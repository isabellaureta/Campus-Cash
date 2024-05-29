import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_repository/repositories.dart';

part 'create_expense_event.dart';
part 'create_expense_state.dart';

class CreateExpenseBloc extends Bloc<CreateExpenseEvent, CreateExpenseState> {
  ExpenseRepository expenseRepository;

  CreateExpenseBloc(this.expenseRepository) : super(CreateExpenseInitial()) {
    on<CreateExpense>((event, emit) async {
      emit(CreateExpenseLoading());
      try {
        await expenseRepository.createExpense(event.expense);
        emit(CreateExpenseSuccess());
      } catch (e) {
        emit(CreateExpenseFailure());
      }
    });
  }
}

class CreateIncomeBloc extends Bloc<CreateIncomeEvent, CreateIncomeState> {
  IncomeRepository incomeRepository;

  CreateIncomeBloc(this.incomeRepository) : super(CreateIncomeInitial()) {
    on<CreateIncome>((event, emit) async {
      emit(CreateIncomeLoading());
      try {
        await incomeRepository.createIncome(event.income);
        emit(CreateIncomeSuccess());
      } catch (e) {
        emit(CreateIncomeFailure());
      }
    });
  }
}


