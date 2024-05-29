import '../entities/entities.dart';

class Category {
  String categoryId;
  String name;
  int totalExpenses;
  String icon;
  int color;

  Category({
    required this.categoryId,
    required this.name,
    required this.totalExpenses,
    required this.icon,
    required this.color,
  });

  static final empty = Category(
      categoryId: '',
      name: '',
      totalExpenses: 0,
      icon: '',
      color: 0
  );

  CategoryEntity toEntity() {
    return CategoryEntity(
      categoryId: categoryId,
      name: name,
      totalExpenses: totalExpenses,
      icon: icon,
      color: color,
    );
  }

  static Category fromEntity(CategoryEntity entity) {
    return Category(
      categoryId: entity.categoryId,
      name: entity.name,
      totalExpenses: entity.totalExpenses,
      icon: entity.icon,
      color: entity.color,
    );
  }
}




class Category2 {
  String categoryId2;
  String name;
  int totalIncome;
  String icon;
  int color;

  Category2({
    required this.categoryId2,
    required this.name,
    required this.totalIncome,
    required this.icon,
    required this.color,
  });

  static final empty = Category2(
      categoryId2: '',
      name: '',
      totalIncome: 0,
      icon: '',
      color: 0
  );

  CategoryEntity2 toEntity() {
    return CategoryEntity2(
      categoryId2: categoryId2,
      name: name,
      totalIncome: totalIncome,
      icon: icon,
      color: color,
    );
  }

  static Category2 fromEntity(CategoryEntity2 entity) {
    return Category2(
      categoryId2: entity.categoryId2,
      name: entity.name,
      totalIncome: entity.totalIncome,
      icon: entity.icon,
      color: entity.color,
    );
  }
}

