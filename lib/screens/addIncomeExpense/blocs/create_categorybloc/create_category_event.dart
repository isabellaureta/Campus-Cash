part of 'create_category_bloc.dart';

sealed class CreateCategoryEvent extends Equatable {
  const CreateCategoryEvent();
  @override
  List<Object> get props => [];
}

class CreateCategory extends CreateCategoryEvent {
  final Category category;
  const CreateCategory(this.category);
  @override
  List<Object> get props => [category];
}

sealed class CreateCategoryEvent2 extends Equatable {
  const CreateCategoryEvent2();
  @override
  List<Object> get props => [];
}

class CreateCategory2 extends CreateCategoryEvent2 {
  final Category2 category2;
  const CreateCategory2(this.category2);
  @override
  List<Object> get props => [category2];
}
