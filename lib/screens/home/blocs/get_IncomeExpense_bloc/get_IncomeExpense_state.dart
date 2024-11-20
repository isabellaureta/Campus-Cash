part of 'get_IncomeExpense_bloc.dart';

sealed class GetExpensesState extends Equatable {
  const GetExpensesState();
  @override
  List<Object> get props => [];
}
final class GetExpensesInitial extends GetExpensesState {}
final class GetExpensesFailure extends GetExpensesState {}
final class GetExpensesLoading extends GetExpensesState {}
final class GetExpensesSuccess extends GetExpensesState {
  final List<Expense> expenses;
  const GetExpensesSuccess(this.expenses);
  @override
  List<Object> get props => [expenses];
}

sealed class GetIncomesState extends Equatable {
  const GetIncomesState();
  @override
  List<Object> get props => [];
}
final class GetIncomesInitial extends GetIncomesState {}
final class GetIncomesFailure extends GetIncomesState {}
final class GetIncomesLoading extends GetIncomesState {}
final class GetIncomesSuccess extends GetIncomesState {
  final List<Income> incomes;
  const GetIncomesSuccess(this.incomes);
  @override
  List<Object> get props => [incomes];
}
