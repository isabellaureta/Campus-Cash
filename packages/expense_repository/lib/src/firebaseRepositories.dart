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

  Future<String?> createExpense(Expense expense, {
    bool isRecurring = false,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
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
        description: expense.description,
      );

      final expenseData = updatedExpense.toEntity().toDocument();

      if (isRecurring) {
        expenseData['isRecurring'] = true;
        expenseData['frequency'] = frequency;
        expenseData['startDate'] = startDate != null ? Timestamp.fromDate(startDate) : null;
        expenseData['endDate'] = endDate != null ? Timestamp.fromDate(endDate) : null;
      }

      await expenseCollection.doc(updatedExpense.userId).set(expenseData);
      await _updateTotalMoney(user.uid, expense.amount.toDouble(), false);

      await _updateEnvelopeExpenses(user.uid, updatedExpense.amount.toDouble());
      await _deductExpenseFromCategory(user.uid, updatedExpense.category.categoryId, updatedExpense.amount);
      await _deductFromPayYourselfFirst(user.uid, updatedExpense.category.categoryId, updatedExpense.amount.toDouble());
      await _deductFromRemainingBudget(user.uid, updatedExpense.category.categoryId, updatedExpense.amount.toDouble());
      await _deductFromOverallRemainingBudget(user.uid, updatedExpense.amount.toDouble());
      await _deductFromPriorityBasedCategory(user.uid, updatedExpense.category.categoryId, updatedExpense.amount.toDouble());

      log('Expense created and budget updated successfully.');
      return null;
    } catch (e) {
      log('Failed to create expense: ${e.toString()}');
      return 'Failed to create expense: ${e.toString()}';
    }
  }

  Future<void> _updateTotalMoney(String userId, double amount, bool isIncome) async {
    final totalMoneyDoc = FirebaseFirestore.instance.collection('totalMoney').doc(userId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final totalMoneySnapshot = await transaction.get(totalMoneyDoc);
      double currentTotal = totalMoneySnapshot.exists ? (totalMoneySnapshot['totalMoneyAmount'] ?? 0.0) : 0.0;
      double updatedTotal = isIncome ? currentTotal + amount : currentTotal - amount;

      transaction.set(totalMoneyDoc, {
        'totalMoneyAmount': updatedTotal,
      }, SetOptions(merge: true));
      log('Total money amount updated to $updatedTotal for user $userId.');
    });
  }

  Future<void> _deductFromOverallRemainingBudget(String userId, double expenseAmount) async {
    final budgetDoc = FirebaseFirestore.instance.collection('budgets').doc(userId);
    final budgetSnapshot = await budgetDoc.get();
    if (budgetSnapshot.exists) {
      final currentRemaining = budgetSnapshot.data()?['remaining'] ?? 0.0;
      final newRemaining = currentRemaining - expenseAmount; // Allow negative values

      await budgetDoc.update({
        'remaining': newRemaining,
      });
      log('Remaining budget updated in overall budget document to $newRemaining.');
    } else {
      log('No overall budget found for the user. Skipping overall budget deduction.');
    }
  }

  Future<void> _deductFromPayYourselfFirst(String userId, String categoryId, double expenseAmount) async {
    try {
      final payYourselfFirstDocRef = FirebaseFirestore.instance.collection('PayYourselfFirst').doc(userId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final payYourselfFirstSnapshot = await transaction.get(payYourselfFirstDocRef);
        if (payYourselfFirstSnapshot.exists) {
          Map<String, dynamic> allocations = payYourselfFirstSnapshot.get('allocations') as Map<String, dynamic>;
          double yourselfExpenses = payYourselfFirstSnapshot.get('yourselfExpenses') ?? 0.0;
          double excessMoney = payYourselfFirstSnapshot.get('excessMoney') ?? 0.0;

          if (allocations.containsKey(categoryId)) {
            double allocatedAmount = allocations[categoryId]['amount'] ?? 0.0;
            double updatedAllocatedAmount = allocatedAmount - expenseAmount;
            allocations[categoryId]['amount'] = updatedAllocatedAmount;

            yourselfExpenses += expenseAmount;
            double remainingYourself = excessMoney - yourselfExpenses;

            transaction.update(payYourselfFirstDocRef, {
              'allocations': allocations,
              'yourselfExpenses': yourselfExpenses,
              'remainingYourself': remainingYourself,
            });
            log('PayYourselfFirst budget updated for category $categoryId: New Amount = $updatedAllocatedAmount');
            log('Updated yourselfExpenses = $yourselfExpenses, remainingYourself = $remainingYourself');
          } else {
            log('Category with ID $categoryId not found in PayYourselfFirst allocations.');
          }
        } else {
          log('No PayYourselfFirst document found for user $userId. Skipping PayYourselfFirst deduction.');
        }
      });
    } catch (e) {
      log('Failed to deduct from PayYourselfFirst budget for category $categoryId: ${e.toString()}');
    }
  }

  Future<bool> _deductExpenseFromCategory(String userId, String categoryId, int expenseAmount) async {
    try {
      final budgetDocRef = FirebaseFirestore.instance.collection('503020').doc(userId);
      final subcollections = ['Needs', 'Wants', 'Savings'];
      for (String subcollection in subcollections) {
        final categoryDoc = await budgetDocRef.collection(subcollection).doc(categoryId).get();
        if (categoryDoc.exists) {
          Map<String, dynamic> categoryData = categoryDoc.data() as Map<String, dynamic>;
          double currentAmount = categoryData['amount'] ?? 0.0;
          double updatedAmount = currentAmount - expenseAmount;
          await budgetDocRef.collection(subcollection).doc(categoryId).update({
            'amount': updatedAmount,
          });
          await _updateTotalExpenses(userId, expenseAmount);
          log('Category budget updated successfully for $categoryId in $subcollection.');
          return true;
        }
      }
      log('No matching category found for category ID $categoryId in 503020 budget.');
      return false;
    } catch (e) {
      log('Failed to update budget for category $categoryId: ${e.toString()}');
      return false;
    }
  }

  Future<void> _updateTotalExpenses(String userId, int expenseAmount) async {
    final budgetDocRef = FirebaseFirestore.instance.collection('503020').doc(userId);

    try {
      DocumentSnapshot budgetSnapshot = await budgetDocRef.get();
      if (budgetSnapshot.exists) {
        double currentTotalExpenses = budgetSnapshot['totalExpenses'] ?? 0.0;
        double updatedTotalExpenses = currentTotalExpenses + expenseAmount;
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

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final categorySnapshot = await transaction.get(envelopeDocRef);
        if (categorySnapshot.exists) {
          double remainingBudget = categorySnapshot.get('remainingBudget') ?? 0.0;
          double updatedRemainingBudget = remainingBudget - expenseAmount;
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

  Future<void> _updateEnvelopeExpenses(String userId, double expenseAmount) async {
    final userDocRef = FirebaseFirestore.instance.collection('envelopeAllocations').doc(userId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userDocRef);
      if (userSnapshot.exists) {
        double currentEnvelopeExpenses = userSnapshot.get('envelopeExpenses') ?? 0.0;
        double income = userSnapshot.get('income') ?? 0.0;
        double updatedEnvelopeExpenses = currentEnvelopeExpenses + expenseAmount;
        double remainingEnvelope = income - updatedEnvelopeExpenses;

        transaction.update(userDocRef, {
          'envelopeExpenses': updatedEnvelopeExpenses,
          'remainingEnvelope': remainingEnvelope,
        });
        log('Updated envelopeExpenses to $updatedEnvelopeExpenses and remainingEnvelope to $remainingEnvelope for user $userId.');
      } else {
        log('User document not found in envelopeAllocations for user $userId.');
      }
    });
  }

  Future<void> _deductFromPriorityBasedCategory(String userId, String categoryId, double expenseAmount) async {
    try {
      DocumentReference priorityDocRef = FirebaseFirestore.instance.collection('PriorityBased').doc(userId);
      DocumentSnapshot prioritySnapshot = await priorityDocRef.get();

      if (prioritySnapshot.exists) {
        Map<String, dynamic> categoriesData = prioritySnapshot['categories'] ?? {};

        if (categoriesData.containsKey(categoryId)) {
          double allocatedAmount = categoriesData[categoryId]['allocatedAmount'] ?? 0.0;
          double updatedAllocatedAmount = (allocatedAmount - expenseAmount).clamp(0.0, double.infinity);
          await priorityDocRef.update({
            'categories.$categoryId.allocatedAmount': updatedAllocatedAmount,
          });
          log('Deducted \$${expenseAmount} from category $categoryId. New allocatedAmount = \$${updatedAllocatedAmount}');
        } else {
          log('Category $categoryId not found in PriorityBased categories.');
        }
      } else {
        log('User document not found for userId $userId in PriorityBased.');
      }
    } catch (e) {
      log('Failed to deduct from PriorityBased category allocation for category $categoryId: ${e.toString()}');
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
          .doc(income.userId)
          .set(income.toEntity().toDocument());
      await _updateRemainingBudget(income.userId, income.amount);
      await _updateTotalMoney(income.userId, income.amount.toDouble(), true);
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

  Future<void> _updateTotalMoney(String userId, double amount, bool isIncome) async {
    final totalMoneyDoc = FirebaseFirestore.instance.collection('totalMoney').doc(userId);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final totalMoneySnapshot = await transaction.get(totalMoneyDoc);
      double currentTotal = totalMoneySnapshot.exists ? (totalMoneySnapshot['totalMoneyAmount'] ?? 0.0) : 0.0;
      double updatedTotal = isIncome ? currentTotal + amount : currentTotal - amount;
      updatedTotal = updatedTotal < 0 ? 0.0 : updatedTotal;
      transaction.set(totalMoneyDoc, {
        'totalMoneyAmount': updatedTotal,
      }, SetOptions(merge: true));
      log('Total money amount updated to $updatedTotal for user $userId.');
    });
  }

  Future<void> _updateRemainingBudget(String userId, int incomeAmount) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> budgetSnapshot =
      await FirebaseFirestore.instance.collection('budgets').doc(userId).get();

      if (budgetSnapshot.exists) {
        Map<String, dynamic> budgetData = budgetSnapshot.data() as Map<String, dynamic>;
        double currentRemaining = budgetData['remaining'] ?? 0.0;
        double updatedRemaining = currentRemaining + incomeAmount;
        await FirebaseFirestore.instance.collection('budgets').doc(userId).update({
          'remaining': updatedRemaining,
        });
        log('Remaining budget updated successfully after adding income.');
      } else {
        log('Budget document not found. Skipping update for remaining budget.');
      }
    } catch (e) {
      log('Failed to update remaining budget: ${e.toString()}');
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

