import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_repository/repositories.dart';

part 'get_IncomeExpense_event.dart';
part 'get_IncomeExpense_state.dart';

class GetExpensesBloc extends Bloc<GetExpensesEvent, GetExpensesState> {
  final ExpenseRepository expenseRepository;

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
  final IncomeRepository incomeRepository;

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


/*List<Income> validatedIncomes = incomes.where((income) => income != null && income.amount != null).toList();
        emit(GetIncomesSuccess(validatedIncomes));*/