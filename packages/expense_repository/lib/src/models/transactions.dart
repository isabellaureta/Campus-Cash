abstract class Transaction {
  final double amount;
  final DateTime date;

  Transaction({required this.amount, required this.date});
}

class Category {
  final String name;
  final int color;
  final String icon;

  Category({required this.name, required this.color, required this.icon});
}

class Expense extends Transaction {
  final Category category;

  Expense({required double amount, required DateTime date, required this.category})
      : super(amount: amount, date: date);
}

class Income extends Transaction {
  Income({required double amount, required DateTime date}) : super(amount: amount, date: date);
}