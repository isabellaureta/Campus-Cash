import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_repository/repositories.dart';

part 'get_categories_event.dart';
part 'get_categories_state.dart';

class GetCategoriesBloc extends Bloc<GetCategoriesEvent, GetCategoriesState> {
  ExpenseRepository expenseRepository;

  GetCategoriesBloc(this.expenseRepository) : super(GetCategoriesInitial()) {
    on<GetCategories>((event, emit) async {
      // Remove the category from the state
      emit(GetCategoriesLoading());
      try {
        List<Category> categories = await expenseRepository.getCategory();
        emit(GetCategoriesSuccess(categories));
      } catch (e) {
        emit(GetCategoriesFailure());
      }
    });

    on<DeleteCategory>((event, emit) async {
      // Remove the category from the state
      if (state is GetCategoriesSuccess) {
        try {
          // Delete the category from the database
          await expenseRepository.deleteCategory(event.category);
          // Update the state by removing the deleted category
          final newState = (state as GetCategoriesSuccess)
              .categories
              .where((cat) => cat != event.category)
              .toList();
          emit(GetCategoriesSuccess(newState)); // Emitting the new state
        } catch (e) {
          // Handle error if deletion fails
          emit(GetCategoriesFailure());
        }
      }
    });
  }

  Stream<GetCategoriesState> mapEventToState(GetCategoriesEvent event) async* {
    if (event is DeleteCategory) {
      // Remove the category from the state
      if (state is GetCategoriesSuccess) {
        final newState = (state as GetCategoriesSuccess)
            .categories
            .where((cat) => cat != event.category)
            .toList();
        yield GetCategoriesSuccess(newState); // Passing the new state to the constructor
      }
    }
  }
}



class GetCategoriesBloc2 extends Bloc<GetCategoriesEvent2, GetCategoriesState2> {
  final IncomeRepository incomeRepository;

  GetCategoriesBloc2(this.incomeRepository) : super(GetCategoriesInitial2()) {
    on<GetCategories2>((event, emit) async {
      emit(GetCategoriesLoading2());
      try {
        List<Category2> categories2 = await incomeRepository.getCategory2();
        emit(GetCategoriesSuccess2(categories2));
      } catch (e) {
        emit(GetCategoriesFailure2());
      }
    });

    on<DeleteCategory2>((event, emit) async {
      if (state is GetCategoriesSuccess2) {
        try {
          final categoryId2 = event.category2.categoryId2;
          if (categoryId2.isEmpty) {
            log('Category ID is empty. Cannot delete category.');
            emit(GetCategoriesFailure2());
            return;
          }

          log('Deleting category: $categoryId2');
          await incomeRepository.deleteCategory2(event.category2);
          final newState2 = (state as GetCategoriesSuccess2)
              .categories2
              .where((cat2) => cat2.categoryId2 != categoryId2)
              .toList();
          emit(GetCategoriesSuccess2(newState2));
        } catch (e) {
          log(e.toString());
          emit(GetCategoriesFailure2());
        }
      }
    });
  }
}
