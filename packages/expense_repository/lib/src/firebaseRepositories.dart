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

  // Modify createExpense to include category update
  Future<void> createExpense(Expense expense) async {
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

      // Save the expense to Firestore
      await FirebaseFirestore.instance
          .collection('expenses')
          .doc(updatedExpense.expenseId)
          .set(updatedExpense.toEntity().toDocument());

      // Update the remaining budget
      await _updateRemainingBudget(user.uid, updatedExpense.amount);

      // Make sure the category budget is updated
      String categoryType = _determineCategoryType(expense.category.categoryId);
      await _updateCategoryBudget(user.uid, expense.category.categoryId, categoryType, updatedExpense.amount);

      log('Expense created and budget updated successfully.');
    } catch (e) {
      log('Failed to create expense: ${e.toString()}');
      rethrow;
    }
  }

  // Add helper method to determine the category type based on categoryId
  String _determineCategoryType(String categoryId) {
    // Logic to determine the category type based on categoryId
    // Adjust this based on how you categorize Needs, Wants, and Savings
    Set<String> needsCategoryIds = {'011', '012', '013'}; // Replace with your real IDs
    Set<String> wantsCategoryIds = {'005', '006'}; // Replace with your real IDs
    Set<String> savingsCategoryIds = {'041'}; // Replace with your real IDs

    if (needsCategoryIds.contains(categoryId)) {
      return 'Needs';
    } else if (wantsCategoryIds.contains(categoryId)) {
      return 'Wants';
    } else if (savingsCategoryIds.contains(categoryId)) {
      return 'Savings';
    } else {
      throw Exception('Invalid category ID');
    }
  }

  // Update the category budget in the specific subcollection (e.g., Needs, Wants, or Savings)
  Future<void> _updateCategoryBudget(String userId, String categoryId, String categoryType, int expenseAmount) async {
    try {
      // Get the document for the 503020 budget
      DocumentReference budgetDocRef = FirebaseFirestore.instance.collection('503020').doc(userId);

      // Fetch the specific category document within the subcollection (e.g., Needs, Wants, or Savings)
      DocumentSnapshot categoryDoc = await budgetDocRef.collection(categoryType).doc(categoryId).get();

      if (categoryDoc.exists) {
        Map<String, dynamic> categoryData = categoryDoc.data() as Map<String, dynamic>;
        double currentAmount = categoryData['amount'] ?? 0.0;

        // Subtract the expense from the category's amount
        double updatedAmount = currentAmount - expenseAmount;
        if (updatedAmount < 0) updatedAmount = 0; // Ensure it doesn't go negative

        // Update the category document with the new amount
        await budgetDocRef.collection(categoryType).doc(categoryId).update({
          'amount': updatedAmount,
        });

        log('Category budget updated successfully for $categoryId.');
      } else {
        throw Exception('Category document not found.');
      }
    } catch (e) {
      log('Failed to update budget for category $categoryId: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> _updateRemainingBudget(String userId, int expenseAmount) async {
    try {
      DocumentSnapshot budgetDoc = await FirebaseFirestore.instance
          .collection('budgets')
          .doc(userId)
          .get();

      if (budgetDoc.exists) {
        Map<String, dynamic> budgetData = budgetDoc.data() as Map<String, dynamic>;
        double currentRemaining = budgetData['remaining'] ?? 0.0;

        double updatedRemaining = currentRemaining - expenseAmount;
        updatedRemaining = updatedRemaining < 0 ? 0 : updatedRemaining;

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
