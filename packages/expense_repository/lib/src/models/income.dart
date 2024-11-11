import 'package:expense_repository/repositories.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Income {
  String incomeId;
  String userId;
  Category2 category2;
  DateTime date;
  int amount;
  String? description;

  Income({
    required this.incomeId,
    required this.userId,
    required this.category2,
    required this.date,
    required this.amount,
    this.description,
  });

  static Future<Income> createIncome({
    required String incomeId,
    required Category2 category2,
    required DateTime date,
    required int amount,
    String? description,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found.');
    }
    return Income(
      incomeId: incomeId,
      userId: user.uid,
      category2: category2,
      date: date,
      amount: amount,
      description: description,
    );
  }

  static final empty = Income(
    incomeId: '',
    userId: '',
    category2: Category2.empty,
    date: DateTime.now(),
    amount: 0,
    description: '',
  );

  IncomeEntity toEntity() {
    return IncomeEntity(
      incomeId: incomeId,
      userId: userId,
      category2: category2,
      date: date,
      amount: amount,
      description: description,
    );
  }

  static Income fromEntity(IncomeEntity entity) {
    return Income(
      incomeId: entity.incomeId,
      userId: entity.userId,
      category2: entity.category2,
      date: entity.date,
      amount: entity.amount,
      description: entity.description,
    );
  }
}
