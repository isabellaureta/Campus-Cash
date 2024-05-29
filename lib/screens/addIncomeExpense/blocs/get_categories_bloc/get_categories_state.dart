part of 'get_categories_bloc.dart';

sealed class GetCategoriesState extends Equatable {
  const GetCategoriesState();

  @override
  List<Object> get props => [];
}

final class GetCategoriesInitial extends GetCategoriesState {}

final class GetCategoriesFailure extends GetCategoriesState {}
final class GetCategoriesLoading extends GetCategoriesState {}
final class GetCategoriesSuccess extends GetCategoriesState {
  final List<Category> categories;

  const GetCategoriesSuccess(this.categories);

  @override
  List<Object> get props => [categories];
}


sealed class GetCategoriesState2 extends Equatable {
  const GetCategoriesState2();

  @override
  List<Object> get props => [];
}

final class GetCategoriesInitial2 extends GetCategoriesState2 {}

final class GetCategoriesFailure2 extends GetCategoriesState2 {}
final class GetCategoriesLoading2 extends GetCategoriesState2 {}
final class GetCategoriesSuccess2 extends GetCategoriesState2 {
  final List<Category2> categories2;

  const GetCategoriesSuccess2(this.categories2);

  @override
  List<Object> get props => [categories2];
}
