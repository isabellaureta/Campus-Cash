import 'package:expense_repository/repositories.dart';

class Expense {
  String expenseId;
  String userId; // Add userId field
  Category category;
  DateTime date;
  int amount;

  Expense({
    required this.expenseId,
    required this.userId, // Include userId in the constructor
    required this.category,
    required this.date,
    required this.amount,
  });

  static final empty = Expense(
    expenseId: '',
    userId: '', // Include userId in the empty instance
    category: Category.empty,
    date: DateTime.now(),
    amount: 0,
  );

  ExpenseEntity toEntity() {
    return ExpenseEntity(
      expenseId: expenseId,
      userId: userId, // Add userId to the entity conversion
      category: category,
      date: date,
      amount: amount,
    );
  }

  static Expense fromEntity(ExpenseEntity entity) {
    return Expense(
      expenseId: entity.expenseId,
      userId: entity.userId, // Extract userId from the entity
      category: entity.category,
      date: entity.date,
      amount: entity.amount,
    );
  }
}
