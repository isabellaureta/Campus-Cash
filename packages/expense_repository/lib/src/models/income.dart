import 'package:expense_repository/repositories.dart';

class Income {
  String incomeId;
  Category2 category2;
  DateTime date;
  int amount;

  Income({
    required this.incomeId,
    required this.category2,
    required this.date,
    required this.amount,
  });

  static final empty = Income(
    incomeId: '',
    category2: Category2.empty,
    date: DateTime.now(),
    amount: 0,
  );

  IncomeEntity toEntity() {
    return IncomeEntity(
      incomeId: incomeId,
      category2: category2,
      date: date,
      amount: amount,
    );
  }

  static Income fromEntity(IncomeEntity entity) {
    return Income(
      incomeId: entity.incomeId,
      category2: entity.category2,
      date: entity.date,
      amount: entity.amount,
    );
  }
}