import 'package:expense_repository/repositories.dart';

class Expense {
  String expenseId;
  String userId;
  Category category;
  DateTime date;
  int amount;

  Expense({
    required this.expenseId,
    required this.userId,
    required this.category,
    required this.date,
    required this.amount,
  });

  static final empty = Expense(
    expenseId: '',
    userId: '',
    category: Category.empty,
    date: DateTime.now(),
    amount: 0,
  );

  ExpenseEntity toEntity() {
    return ExpenseEntity(
      expenseId: expenseId,
      userId: userId,
      category: category,
      date: date,
      amount: amount,
    );
  }

  static Expense fromEntity(ExpenseEntity entity) {
    return Expense(
      expenseId: entity.expenseId,
      userId: entity.userId,
      category: entity.category,
      date: entity.date,
      amount: entity.amount,
    );
  }
}
