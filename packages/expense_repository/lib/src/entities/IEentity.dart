import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_repository/src/entities/entities.dart';
import '../models/models.dart';

class ExpenseEntity {
  String expenseId;
  Category category;
  DateTime date;
  int amount;
  String userId;

  ExpenseEntity({
    required this.expenseId,
    required this.category,
    required this.date,
    required this.amount,
    required this.userId,
  });

  Map<String, Object?> toDocument() {
    return {
      'expenseId': expenseId,
      'category': category.toEntity().toDocument(),
      'date': Timestamp.fromDate(date),
      'amount': amount,
      'userId': userId,
    };
  }

  static ExpenseEntity fromDocument(Map<String, dynamic> doc) {
    return ExpenseEntity(
      expenseId: doc['expenseId'] as String,
      category: Category.fromEntity(CategoryEntity.fromDocument(doc['category'])),
      date: (doc['date'] as Timestamp).toDate(),
      amount: doc['amount'] as int,
      userId: doc['userId'] as String,
    );
  }
}

class IncomeEntity {
  String incomeId;
  Category2 category2;
  DateTime date;
  int amount;
  String userId;

  IncomeEntity({
    required this.incomeId,
    required this.category2,
    required this.date,
    required this.amount,
    required this.userId,
  });

  Map<String, Object?> toDocument() {
    return {
      'incomeId': incomeId,
      'category2': category2.toEntity().toDocument(),
      'date': date,
      'amount': amount,
      'userId': userId,
    };
  }

  static IncomeEntity fromDocument(Map<String, dynamic> doc) {
    return IncomeEntity(
      incomeId: doc['incomeId'],
      category2: Category2.fromEntity(CategoryEntity2.fromDocument(doc['category2'])),
      date: (doc['date'] as Timestamp).toDate(),
      amount: doc['amount'],
      userId: doc['userId'],
    );
  }
}
