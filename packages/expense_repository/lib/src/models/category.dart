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
  Category(icon: 'assets/Education.png', name: 'Education', color: 0xFFE57373, categoryId: '011'),
  Category(icon: 'assets/Tuition Fees.png', name: 'Tuition Fees', color: 0xFF81C784, categoryId: '012'),
  Category(icon: 'assets/School Supplies.png', name: 'School Supplies', color: 0xFF64B5F6, categoryId: '013'),
  Category(icon: 'assets/Subscriptions.png', name: 'Subscriptions', color: 0xFFFFD54F, categoryId: '014'),
  Category(icon: 'assets/Public Transpo.png', name: 'Public Transpo', color: 0xFFBA68C8, categoryId: '015'),
  Category(icon: 'assets/Booked Transpo.png', name: 'Booked Transpo', color: 0xFF4DB6AC, categoryId: '016'),
  Category(icon: 'assets/House.png', name: 'House', color: 0xFFAED581, categoryId: '017'),
  Category(icon: 'assets/Utilities.png', name: 'Utilities', color: 0xFF7986CB, categoryId: '018'),

  Category(icon: 'assets/Laundry.png', name: 'Laundry', color: 0xFFF48FB1, categoryId: '019'),
  Category(icon: 'assets/Family.png', name: 'Family', color: 0xFFFFE082, categoryId: '021'),
  Category(icon: 'assets/Load.png', name: 'Load', color: 0xFFFFCC80, categoryId: '022'),
  Category(icon: 'assets/Groceries.png', name: 'Groceries', color: 0xFFB0BEC5, categoryId: '023'),
  Category(icon: 'assets/Fitness.png', name: 'Fitness', color: 0xFF9FA8DA, categoryId: '024'),
  Category(icon: 'assets/Dining.png', name: 'Dining', color: 0xFFEF9A9A, categoryId: '025'),
  Category(icon: 'assets/Meals.png', name: 'Meals', color: 0xFFBCAAA4, categoryId: '026'),

  Category(icon: 'assets/Snacks.png', name: 'Snacks/Coffee', color: 0xFFCDDC39, categoryId: '027'),
  Category(icon: 'assets/Printing.png', name: 'Printing', color: 0xFF4DD0E1, categoryId: '028'),
  Category(icon: 'assets/Organizations.png', name: 'Organizations', color: 0xFF29B6F6, categoryId: '029'),
  Category(icon: 'assets/Online Courses.png', name: 'Online Courses', color: 0xFFB39DDB, categoryId: '031'),
  Category(icon: 'assets/School Events.png', name: 'School Events', color: 0xFFE8EAF6, categoryId: '032'),
  Category(icon: 'assets/Sports.png', name: 'Sports', color: 0xFFF3E5F5, categoryId: '033'),
  Category(icon: 'assets/Shopping.png', name: 'Shopping', color: 0xFFFFCDD2, categoryId: '034'),
  Category(icon: 'assets/Online Shopping.png', name: 'Online Shopping', color: 0xFFE8F5E9, categoryId: '035'),
  Category(icon: 'assets/Friends.png', name: 'Friends', color: 0xFFBDBDBD, categoryId: '036'),

  Category(icon: 'assets/Entertainment.png', name: 'Entertainment', color: 0xFFFF7043, categoryId: '037'),
  Category(icon: 'assets/Medical.png', name: 'Medical', color: 0xFFFFEB3B, categoryId: '038'),
  Category(icon: 'assets/Insurance.png', name: 'Insurance', color: 0xFFD4E157, categoryId: '039'),
  Category(icon: 'assets/Savings.png', name: 'Savings', color: 0xFFE91E63, categoryId: '041'),
  Category(icon: 'assets/Investments.png', name: 'Investments', color: 0xFFF44336, categoryId: '042'),
  Category(icon: 'assets/Credit Cards.png', name: 'Credit Cards', color: 0xFF26A69A, categoryId: '043'),
  Category(icon: 'assets/Gifts.png', name: 'Gifts', color: 0xFFBBDEFB, categoryId: '044'),
  Category(icon: 'assets/Travel.png', name: 'Travel', color: 0xFFE1BEE7, categoryId: '045'),
  Category(icon: 'assets/Outings.png', name: 'Outings', color: 0xFFFFCDD2, categoryId: '046'),

  Category(icon: 'assets/Gas.png', name: 'Gas', color: 0xFFB2EBF2, categoryId: '047'),
  Category(icon: 'assets/Vehicle.png', name: 'Vehicle', color: 0xFFFFF9C4, categoryId: '048'),
  Category(icon: 'assets/Loans.png', name: 'Loans', color: 0xFFD7CCC8, categoryId: '049'),
  Category(icon: 'assets/Partner.png', name: 'Partner', color: 0xFF90A4AE, categoryId: '051'),
  Category(icon: 'assets/Business.png', name: 'Business', color: 0xFFC5E1A5, categoryId: '052'),
  Category(icon: 'assets/Personal Care.png', name: 'Personal Care', color: 0xFF29B6F6, categoryId: '053'),
  Category(icon: 'assets/Clothing.png', name: 'Clothing', color: 0xFFF3E5F5, categoryId: '054'),
  Category(icon: 'assets/Others.png', name: 'Others', color: 0xFFEC407A, categoryId: '055'),

];

final List<Category2> predefinedCategories2 = [
  Category2(icon: 'assets/Allowance.png', name: 'Allowance', color: 0xFF7986CB, categoryId2: '056'),
  Category2(icon: 'assets/Scholarship.png', name: 'Scholarship', color: 0xFFE57373, categoryId2: '057'),
  Category2(icon: 'assets/Grants.png', name: 'Grants', color: 0xFF64B5F6, categoryId2: '058'),
  Category2(icon: 'assets/Part-Time Job.png', name: 'Part-Time Job', color: 0xFFFFD54F, categoryId2: '059'),
  Category2(icon: 'assets/Freelance.png', name: 'Freelance', color: 0xFFBA68C8, categoryId2: '060'),
  Category2(icon: 'assets/Stipends.png', name: 'Stipends', color: 0xFF4DB6AC, categoryId2: '061'),
  Category2(icon: 'assets/Salary.png', name: 'Salary', color: 0xFFD4E157, categoryId2: '062'),
  Category2(icon: 'assets/Internships.png', name: 'Internships', color: 0xFFBCAAA4, categoryId2: '063'),
  Category2(icon: 'assets/Awards.png', name: 'Awards', color: 0xFFF06292, categoryId2: '064'),
  Category2(icon: 'assets/Refunds.png', name: 'Refunds', color: 0xFFD7CCC8, categoryId2: '065'),
  Category2(icon: 'assets/Crypto.png', name: 'Crypto', color: 0xFFFFEB3B, categoryId2: '066'),
];

