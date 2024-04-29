import 'package:expense_repository/expense_repository.dart';

abstract class ExpenseRepository {

  Future<void> createCategory(Category category);

  Future<List<Category>> getCategory();

  Future<void> createExpense(Expense expense);

  Future<List<Expense>> getExpenses();

  Future<void> deleteCategory(Category category);
}



abstract class IncomeRepository {

  Future<void> createCategory2(Category2 category2);

  Future<List<Category2>> getCategory2();

  Future<void> createIncome(Income income);

  Future<List<Income>> getIncome();

  Future<void> deleteCategory2(Category2 category2);
}