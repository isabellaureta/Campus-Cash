part of 'create_category_bloc.dart';

sealed class CreateCategoryState extends Equatable {
  const CreateCategoryState();

  @override
  List<Object> get props => [];
}

final class CreateCategoryInitial extends CreateCategoryState {}

final class CreateCategoryFailure extends CreateCategoryState {}
final class CreateCategoryLoading extends CreateCategoryState {}
final class CreateCategorySuccess extends CreateCategoryState {}




sealed class CreateCategoryState2 extends Equatable {
  const CreateCategoryState2();

  @override
  List<Object> get props => [];
}

final class CreateCategoryInitial2 extends CreateCategoryState2 {}

final class CreateCategoryFailure2 extends CreateCategoryState2 {}
final class CreateCategoryLoading2 extends CreateCategoryState2 {}
final class CreateCategorySuccess2 extends CreateCategoryState2 {}
