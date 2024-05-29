import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_repository/src/entities/entities.dart';

import '../models/models.dart';

class ExpenseEntity {
  String expenseId;
  Category category;
  DateTime date;
  int amount;

  ExpenseEntity({
    required this.expenseId,
    required this.category,
    required this.date,
    required this.amount,
  });

  Map<String, Object?> toDocument() {
    return {
      'expenseId': expenseId,
      'category': category.toEntity().toDocument(),
      'date': date,
      'amount': amount,
    };
  }

  static ExpenseEntity fromDocument(Map<String, dynamic> doc) {
    return ExpenseEntity(
      expenseId: doc['expenseId'],
      category: Category.fromEntity(CategoryEntity.fromDocument(doc['category'])),
      date: (doc['date'] as Timestamp).toDate(),
      amount: doc['amount'],
    );
  }
}



class IncomeEntity {
  String incomeId;
  Category2 category2;
  DateTime date;
  int amount;

  IncomeEntity({
    required this.incomeId,
    required this.category2,
    required this.date,
    required this.amount,
  });

  Map<String, Object?> toDocument() {
    return {
      'incomeId': incomeId,
      'category2': category2.toEntity().toDocument(),
      'date': date,
      'amount': amount,
    };
  }

  static IncomeEntity fromDocument(Map<String, dynamic> doc) {
    return IncomeEntity(
      incomeId: doc['incomeId'],
      category2: Category2.fromEntity(CategoryEntity2.fromDocument(doc['category2'])),
      date: (doc['date'] as Timestamp).toDate(),
      amount: doc['amount'],
    );
  }
}

