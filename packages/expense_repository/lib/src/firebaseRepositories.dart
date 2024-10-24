import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_repository/repositories.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseExpenseRepo implements ExpenseRepository {
  final categoryCollection = FirebaseFirestore.instance.collection('categories');
  final expenseCollection = FirebaseFirestore.instance.collection('expenses');

  @override
  Future<void> createCategory(Category category) async {
    try {
      await categoryCollection
          .doc(category.categoryId)
          .set(category.toEntity().toDocument());
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<List<Category>> getCategory() async {
    try {
      return await categoryCollection
          .get()
          .then((value) => value.docs.map((e) =>
          Category.fromEntity(CategoryEntity.fromDocument(e.data()))
      ).toList());
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  Future<String?> createExpense(Expense expense) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found.');
      }

      final updatedExpense = Expense(
        expenseId: expense.expenseId,
        userId: user.uid,
        category: expense.category,
        date: expense.date,
        amount: expense.amount,
      );

      await FirebaseFirestore.instance
          .collection('expenses')
          .doc(updatedExpense.expenseId)
          .set(updatedExpense.toEntity().toDocument());

      // Deduct the expense from the category in the 503020 budget system
      final categoryDeducted = await _deductExpenseFromCategory(user.uid, updatedExpense.category.categoryId, updatedExpense.amount);

      // Deduct from the PayYourselfFirst budget system
      await _deductFromPayYourselfFirst(user.uid, updatedExpense.category.categoryId, updatedExpense.amount.toDouble());

      await _deductFromRemainingBudget(user.uid, updatedExpense.category.categoryId, updatedExpense.amount.toDouble());

      if (!categoryDeducted) {
        return 'No matched category in your budget';
      } else {
        log('Expense created and budget updated successfully.');
        return null;
      }
    } catch (e) {
      log('Failed to create expense: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> _deductFromPayYourselfFirst(String userId, String categoryId, double expenseAmount) async {
    try {
      final payYourselfFirstDocRef = FirebaseFirestore.instance.collection('PayYourselfFirst').doc(userId);

      // Run the deduction in a Firestore transaction
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final payYourselfFirstSnapshot = await transaction.get(payYourselfFirstDocRef);

        if (payYourselfFirstSnapshot.exists) {
          final allocations = payYourselfFirstSnapshot.get('allocations') as Map<String, dynamic>;

          if (allocations.containsKey(categoryId)) {
            // Get the current amount for the matching category
            double currentAmount = allocations[categoryId]['amount'] ?? 0.0;

            // Deduct the expense amount
            double updatedAmount = currentAmount - expenseAmount;
            if (updatedAmount < 0) updatedAmount = 0.0; // Prevent negative budget

            // Update the Firestore document with the new amount
            allocations[categoryId]['amount'] = updatedAmount;

            transaction.update(payYourselfFirstDocRef, {
              'allocations': allocations,
            });

            log('PayYourselfFirst budget updated for category $categoryId: New Amount = $updatedAmount');
          } else {
            log('Category with ID $categoryId not found in PayYourselfFirst.');
          }
        } else {
          log('No PayYourselfFirst document found for user $userId.');
        }
      });
    } catch (e) {
      log('Failed to deduct from PayYourselfFirst budget for category $categoryId: ${e.toString()}');
      rethrow;
    }
  }


  Future<bool> _deductExpenseFromCategory(String userId, String categoryId, int expenseAmount) async {
    try {
      final budgetDocRef = FirebaseFirestore.instance.collection('503020').doc(userId);

      // Iterate through each subcollection (Needs, Wants, Savings) to find the matching categoryId
      final subcollections = ['Needs', 'Wants', 'Savings'];

      for (String subcollection in subcollections) {
        final categoryDoc = await budgetDocRef.collection(subcollection).doc(categoryId).get();

        if (categoryDoc.exists) {
          // If the categoryId is found, deduct the expense amount from the category's budget
          Map<String, dynamic> categoryData = categoryDoc.data() as Map<String, dynamic>;
          double currentAmount = categoryData['amount'] ?? 0.0;

          double updatedAmount = currentAmount - expenseAmount;
          if (updatedAmount < 0) updatedAmount = 0; // Ensure it doesn't go negative

          // Update the category document with the new amount
          await budgetDocRef.collection(subcollection).doc(categoryId).update({
            'amount': updatedAmount,
          });

          // Update the totalExpenses field in the main 503020 document
          await _updateTotalExpenses(userId, expenseAmount);

          log('Category budget updated successfully for $categoryId in $subcollection.');
          return true; // Return true if deduction was successful
        }
      }
      // Return false if no matching categoryId is found
      return false;

    } catch (e) {
      log('Failed to update budget for category $categoryId: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> _updateTotalExpenses(String userId, int expenseAmount) async {
    final budgetDocRef = FirebaseFirestore.instance.collection('503020').doc(userId);

    try {
      DocumentSnapshot budgetSnapshot = await budgetDocRef.get();

      if (budgetSnapshot.exists) {
        double currentTotalExpenses = budgetSnapshot['totalExpenses'] ?? 0.0;
        double updatedTotalExpenses = currentTotalExpenses + expenseAmount;

        // Update totalExpenses in Firestore
        await budgetDocRef.update({
          'totalExpenses': updatedTotalExpenses,
        });

        log('Total expenses updated successfully.');
      }
    } catch (e) {
      log('Failed to update total expenses: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> _deductFromRemainingBudget(String userId, String categoryId, double expenseAmount) async {
    try {
      final envelopeDocRef = FirebaseFirestore.instance
          .collection('envelopeAllocations')
          .doc(userId)
          .collection('envelopes')
          .doc(categoryId);

      // Run the deduction in a Firestore transaction
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final categorySnapshot = await transaction.get(envelopeDocRef);

        if (categorySnapshot.exists) {
          // Retrieve the current remaining budget
          double remainingBudget = categorySnapshot.get('remainingBudget') ?? 0.0;

          // Calculate the new remaining budget
          double updatedRemainingBudget = remainingBudget - expenseAmount;
          if (updatedRemainingBudget < 0) updatedRemainingBudget = 0.0; // Prevent negative remaining budget

          // Update the remainingBudget in Firestore
          transaction.update(envelopeDocRef, {
            'remainingBudget': updatedRemainingBudget,
          });

          log('Remaining budget updated for category $categoryId: New Remaining Budget = $updatedRemainingBudget');
        } else {
          log('Category with ID $categoryId not found in user\'s envelope allocations.');
        }
      });
    } catch (e) {
      log('Failed to deduct from remaining budget for category $categoryId: ${e.toString()}');
      rethrow;
    }
  }


  @override
  Future<List<Expense>> getExpenses() async {
    try {
      return await expenseCollection
          .get()
          .then((value) => value.docs.map((e) =>
          Expense.fromEntity(ExpenseEntity.fromDocument(e.data()))
      ).toList());
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> deleteCategory(Category category) async {
    try {
      await categoryCollection.doc(category.categoryId).delete();
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
}








class FirebaseExpenseRepo2 implements IncomeRepository {
  final categoryCollection2 = FirebaseFirestore.instance.collection('categories2');
  final incomeCollection = FirebaseFirestore.instance.collection('incomes');

  @override
  Future<void> createCategory2(Category2 category2) async {
    try {
      await categoryCollection2
          .doc(category2.categoryId2)
          .set(category2.toEntity().toDocument());
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<List<Category2>> getCategory2() async {
    try {
      var querySnapshot = await categoryCollection2.get();
      var categories2 = querySnapshot.docs.map((e) {
        var data = e.data();
        log('Category2 data: $data');
        return Category2.fromEntity(CategoryEntity2.fromDocument(data));
      }).toList();
      return categories2;
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> createIncome(Income income) async {
    try {
      await incomeCollection
          .doc(income.incomeId)
          .set(income.toEntity().toDocument());

      await _updateRemainingBudget(income.userId, income.amount);

      log('Income created and budget updated successfully.');
    } catch (e) {
      log('Failed to create income: ${e.toString()}');
      rethrow;
    }
  }

  @override
  Future<List<Income>> getIncome() async {
    try {
      return await incomeCollection
          .get()
          .then((value) => value.docs.map((e) =>
          Income.fromEntity(IncomeEntity.fromDocument(e.data()))
      ).toList());
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  Future<void> _updateRemainingBudget(String userId, int incomeAmount) async {
    try {
      DocumentSnapshot budgetDoc = await FirebaseFirestore.instance
          .collection('budgets')
          .doc(userId)
          .get();

      if (budgetDoc.exists) {
        Map<String, dynamic> budgetData = budgetDoc.data() as Map<String, dynamic>;
        double currentRemaining = budgetData['remaining'] ?? 0.0;

        double updatedRemaining = currentRemaining + incomeAmount;

        await FirebaseFirestore.instance
            .collection('budgets')
            .doc(budgetDoc.id)
            .update({'remaining': updatedRemaining});

        log('Remaining budget updated successfully after adding income.');
      } else {
        throw Exception('Budget document not found.');
      }
    } catch (e) {
      log('Failed to update remaining budget: ${e.toString()}');
      rethrow;
    }
  }

  @override
  Future<void> deleteCategory2(Category2 category2) async {
    try {
      log('Deleting category with ID: ${category2.categoryId2}');
      await categoryCollection2.doc(category2.categoryId2).delete();
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
}

