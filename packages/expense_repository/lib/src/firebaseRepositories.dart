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

  @override
  Future<void> createExpense(Expense expense) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found.');
      }

      // Save the expense to Firestore
      final updatedExpense = Expense(
        expenseId: expense.expenseId,
        userId: user.uid, // Ensure the userId is set here
        category: expense.category,
        date: expense.date,
        amount: expense.amount,
      );

      await FirebaseFirestore.instance
          .collection('expenses')
          .doc(updatedExpense.expenseId)
          .set(updatedExpense.toEntity().toDocument());

      // After saving the expense, update the corresponding budget's remaining amount
      await _updateRemainingBudget(user.uid, updatedExpense.amount);

      log('Expense created and budget updated successfully.');
    } catch (e) {
      log('Failed to create expense: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> _updateRemainingBudget(String userId, int expenseAmount) async {
    try {
      // Fetch the user's budget document
      DocumentSnapshot budgetDoc = await FirebaseFirestore.instance
          .collection('budgets')
          .doc(userId) // Assuming the budget document is identified by userId
          .get();

      if (budgetDoc.exists) {
        Map<String, dynamic> budgetData = budgetDoc.data() as Map<String, dynamic>;
        double currentRemaining = budgetData['remaining'] ?? 0.0;

        // Deduct the expense amount from the remaining budget
        double updatedRemaining = currentRemaining - expenseAmount;

        // Ensure the remaining amount doesn't go below zero
        updatedRemaining = updatedRemaining < 0 ? 0 : updatedRemaining;

        // Update the remaining amount in the budget document
        await FirebaseFirestore.instance
            .collection('budgets')
            .doc(budgetDoc.id)
            .update({'remaining': updatedRemaining});

        log('Remaining budget updated successfully.');
      } else {
        throw Exception('Budget document not found.');
      }
    } catch (e) {
      log('Failed to update remaining budget: ${e.toString()}');
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
        log('Category2 data: $data'); // Log data to ensure it's not null or missing fields
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
      // Save the income to Firestore
      await incomeCollection
          .doc(income.incomeId)
          .set(income.toEntity().toDocument());

      // After saving the income, update the corresponding budget's remaining amount
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
      // Fetch the user's budget document
      DocumentSnapshot budgetDoc = await FirebaseFirestore.instance
          .collection('budgets')
          .doc(userId) // Assuming the budget document is identified by userId
          .get();

      if (budgetDoc.exists) {
        Map<String, dynamic> budgetData = budgetDoc.data() as Map<String, dynamic>;
        double currentRemaining = budgetData['remaining'] ?? 0.0;

        // Add the income amount to the remaining budget
        double updatedRemaining = currentRemaining + incomeAmount;

        // Update the remaining amount in the budget document
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

  /*
   @override
  Future<void> createIncome(Income income) async {
    try {
      // Save the income to Firestore
      await incomeCollection
          .doc(income.incomeId)
          .set(income.toEntity().toDocument());

      // After saving the income, update the corresponding budget's remaining amount
      await _updateRemainingBudget(income.userId, income.amount);

      log('Income created and budget updated successfully.');
    } catch (e) {
      log('Failed to create income: ${e.toString()}');
      rethrow;
    }
  }

  // Method to update the remaining budget in Firestore after saving an income
  Future<void> _updateRemainingBudget(String userId, int incomeAmount) async {
    try {
      // Fetch the user's budget document
      DocumentSnapshot budgetDoc = await FirebaseFirestore.instance
          .collection('budgets')
          .doc(userId) // Assuming the budget document is identified by userId
          .get();

      if (budgetDoc.exists) {
        Map<String, dynamic> budgetData = budgetDoc.data() as Map<String, dynamic>;
        double currentRemaining = budgetData['remaining'] ?? 0.0;

        // Add the income amount to the remaining budget
        double updatedRemaining = currentRemaining + incomeAmount;

        // Update the remaining amount in the budget document
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
   */
}