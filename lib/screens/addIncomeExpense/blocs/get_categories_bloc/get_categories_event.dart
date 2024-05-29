part of 'get_categories_bloc.dart';

sealed class GetCategoriesEvent extends Equatable {
  const GetCategoriesEvent();

  @override
  List<Object> get props => [];
}

class GetCategories extends GetCategoriesEvent {}

class DeleteCategory extends GetCategoriesEvent {
  final Category category;

  const DeleteCategory(this.category);

  @override
  List<Object> get props => [category];
}





sealed class GetCategoriesEvent2 extends Equatable {
  const GetCategoriesEvent2();

  @override
  List<Object> get props => [];
}

class GetCategories2 extends GetCategoriesEvent2 {}

class DeleteCategory2 extends GetCategoriesEvent2 {
  final Category2 category2;

  const DeleteCategory2(this.category2);

  @override
  List<Object> get props => [category2];
}