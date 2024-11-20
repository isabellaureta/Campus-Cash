part of 'get_IncomeExpense_bloc.dart';

sealed class GetExpensesEvent extends Equatable {
  const GetExpensesEvent();
  @override
  List<Object> get props => [];
}

class GetExpenses extends GetExpensesEvent{}
sealed class GetIncomesEvent extends Equatable {
  const GetIncomesEvent();
  @override
  List<Object> get props => [];
}

class GetIncomes extends GetIncomesEvent{}