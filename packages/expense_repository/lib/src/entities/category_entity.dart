class CategoryEntity {
  String categoryId;
  String name;
  int totalExpenses;
  String icon;
  int color;


  CategoryEntity({
    required this.categoryId,
    required this.name,
    required this.totalExpenses,
    required this.icon,
    required this.color,
  });

  Map<String, Object?> toDocument() {
    return {
      'categoryId': categoryId,
      'name': name,
      'totalExpenses': totalExpenses,
      'icon': icon,
      'color': color,
    };
  }

  static CategoryEntity fromDocument(Map<String, dynamic> doc) {
    return CategoryEntity(
      categoryId: doc['categoryId'],
      name: doc['name'],
      totalExpenses: doc['totalExpenses'],
      icon: doc['icon'],
      color: doc['color'],
    );
  }
}


class CategoryEntity2 {
  String categoryId2;
  String name;
  int totalIncome;
  String icon;
  int color;


  CategoryEntity2({
    required this.categoryId2,
    required this.name,
    required this.totalIncome,
    required this.icon,
    required this.color,
  });

  Map<String, Object?> toDocument() {
    return {
      'categoryId': categoryId2,
      'name': name,
      'totalIncome': totalIncome,
      'icon': icon,
      'color': color,
    };
  }

  static CategoryEntity2 fromDocument(Map<String, dynamic> doc) {
    return CategoryEntity2(
      categoryId2: doc['categoryId'],
      name: doc['name'],
      totalIncome: doc['totalIncomes'],
      icon: doc['icon'],
      color: doc['color'],
    );
  }
}