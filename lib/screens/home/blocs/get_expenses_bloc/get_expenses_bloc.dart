import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_repository/expense_repository.dart';

part 'get_expenses_event.dart';
part 'get_expenses_state.dart';

class GetExpensesBloc extends Bloc<GetExpensesEvent, GetExpensesState> {
  ExpenseRepository expenseRepository;

  GetExpensesBloc(this.expenseRepository) : super(GetExpensesInitial()) {
    on<GetExpenses>((event, emit) async {
      emit(GetExpensesLoading());
      try {
        List<Expense> expenses = await expenseRepository.getExpenses();
        emit(GetExpensesSuccess(expenses));
      } catch (e) {
        emit(GetExpensesFailure());
      }
    });
  }
}


class GetIncomesBloc extends Bloc<GetIncomesEvent, GetIncomesState> {
  IncomeRepository incomeRepository;

  GetIncomesBloc(this.incomeRepository) : super(GetIncomesInitial()) {
    on<GetIncomes>((event, emit) async {
      emit(GetIncomesLoading());
      try {
        List<Income> incomes = await incomeRepository.getIncome();
        emit(GetIncomesSuccess(incomes));
      } catch (e) {
        emit(GetIncomesFailure());
      }
    });
  }
}
