class CategoryEntity {
  String categoryId;
  String name;
  String icon;
  int color;


  CategoryEntity({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.color,
  });

  Map<String, Object?> toDocument() {
    return {
      'categoryId': categoryId,
      'name': name,
      'icon': icon,
      'color': color,
    };
  }

  static CategoryEntity fromDocument(Map<String, dynamic> doc) {
    return CategoryEntity(
      categoryId: doc['categoryId'],
      name: doc['name'],
      icon: doc['icon'],
      color: doc['color'],
    );
  }
}


class CategoryEntity2 {
  String categoryId2;
  String name;
  String icon;
  int color;

  CategoryEntity2({
    required this.categoryId2,
    required this.name,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toDocument() {
    return {
      'categoryId2': categoryId2,
      'name': name,
      'icon': icon,
      'color': color,
    };
  }

  static CategoryEntity2 fromDocument(Map<String, dynamic> doc) {
    return CategoryEntity2(
      categoryId2: doc['categoryId2'] as String? ?? '',
      name: doc['name'] as String? ?? '',
      icon: doc['icon'] as String? ?? '',
      color: doc['color'] as int? ?? 0,
    );
  }
}

