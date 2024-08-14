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
      final updatedExpense = Expense(
        expenseId: expense.expenseId,
        userId: user.uid, // Ensure the userId is set here
        category: expense.category,
        date: expense.date,
        amount: expense.amount,
      );
      await expenseCollection
          .doc(updatedExpense.expenseId)
          .set(updatedExpense.toEntity().toDocument());
    } catch (e) {
      log(e.toString());
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
      await incomeCollection
          .doc(income.incomeId)
          .set(income.toEntity().toDocument());
    } catch (e) {
      log(e.toString());
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