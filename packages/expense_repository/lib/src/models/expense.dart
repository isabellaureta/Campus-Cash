import 'package:expense_repository/repositories.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  static Future<Expense> createExpense({
    required String expenseId,
    required Category category,
    required DateTime date,
    required int amount,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found.');
    }
    return Expense(
      expenseId: expenseId,
      userId: user.uid,
      category: category,
      date: date,
      amount: amount,
    );
  }

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
