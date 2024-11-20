import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_repository/repositories.dart';
part 'create_category_event.dart';
part 'create_category_state.dart';

class CreateCategoryBloc extends Bloc<CreateCategoryEvent, CreateCategoryState> {
  final ExpenseRepository expenseRepository;
  CreateCategoryBloc(this.expenseRepository) : super(CreateCategoryInitial()) {
    on<CreateCategory>((event, emit) async {
      emit(CreateCategoryLoading());
      try {
        await expenseRepository.createCategory(event.category);
        emit(CreateCategorySuccess());
      } catch (e) {
        emit(CreateCategoryFailure());
      }
    });
  }
}

class CreateCategoryBloc2 extends Bloc<CreateCategoryEvent2, CreateCategoryState2> {
  final IncomeRepository incomeRepository;
  CreateCategoryBloc2(this.incomeRepository) : super(CreateCategoryInitial2()) {
    on<CreateCategory2>((event, emit) async {
      emit(CreateCategoryLoading2());
      try {
        await incomeRepository.createCategory2(event.category2);
        emit(CreateCategorySuccess2());
      } catch (e) {
        emit(CreateCategoryFailure2());
      }
    });
  }
}

