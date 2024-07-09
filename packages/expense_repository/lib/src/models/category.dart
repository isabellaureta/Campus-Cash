import '../entities/entities.dart';

class Category {
  String categoryId;
  String name;
  String icon;
  int color;

  Category({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.color,
  });

  static final empty = Category(
      categoryId: '',
      name: '',
      icon: '',
      color: 0
  );

  CategoryEntity toEntity() {
    return CategoryEntity(
      categoryId: categoryId,
      name: name,
      icon: icon,
      color: color,
    );
  }

  static Category fromEntity(CategoryEntity entity) {
    return Category(
      categoryId: entity.categoryId,
      name: entity.name,
      icon: entity.icon,
      color: entity.color,
    );
  }
}




class Category2 {
  String categoryId2;
  String name;
  String icon;
  int color;

  Category2({
    required this.categoryId2,
    required this.name,
    required this.icon,
    required this.color,
  });

  static final empty = Category2(
      categoryId2: '',
      name: '',
      icon: '',
      color: 0
  );

  CategoryEntity2 toEntity() {
    return CategoryEntity2(
      categoryId2: categoryId2,
      name: name,
      icon: icon,
      color: color,
    );
  }

  static Category2 fromEntity(CategoryEntity2 entity) {
    return Category2(
      categoryId2: entity.categoryId2,
      name: entity.name,
      icon: entity.icon,
      color: entity.color,
    );
  }
}

final List<Category> predefinedCategories = [
  Category(icon: 'House', name: 'House', color: 0xFFAED581, categoryId: '017'),
  Category(icon: 'Utilities', name: 'Utilities', color: 0xFF7986CB, categoryId: '018'),
  Category(icon: 'Groceries', name: 'Groceries', color: 0xFF7986CB, categoryId: '023'),
  Category(icon: 'Meals', name: 'Meals', color: 0xFF7986CB, categoryId: '026'),
  Category(icon: 'Snacks', name: 'Snacks/Coffee', color: 0xFF7986CB, categoryId: '027'),
  Category(icon: 'Medical', name: 'Medical', color: 0xFF7986CB, categoryId: '038'),
  Category(icon: 'Insurance', name: 'Insurance', color: 0xFF7986CB, categoryId: '039'),
  Category(icon: 'Tuition Fees', name: 'Tuition Fees', color: 0xFF81C784, categoryId: '012'),
  Category(icon: 'School Supplies', name: 'School Supplies', color: 0xFF64B5F6, categoryId: '013'),
  Category(icon: 'Public Transpo', name: 'Public Transpo', color: 0xFFBA68C8, categoryId: '015'),
  Category(icon: 'Booked Transpo', name: 'Booked Transpo', color: 0xFF4DB6AC, categoryId: '016'),
  Category(icon: 'Savings', name: 'Savings', color: 0xFF7986CB, categoryId: '041'),
];

