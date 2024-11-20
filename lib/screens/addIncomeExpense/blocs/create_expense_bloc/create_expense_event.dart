part of 'create_expense_bloc.dart';

sealed class CreateExpenseEvent extends Equatable {
  const CreateExpenseEvent();
  @override
  List<Object?> get props => [];
}

class CreateExpense extends CreateExpenseEvent {
  final Expense expense;
  final bool isRecurring;
  final String? frequency;
  final DateTime? startDate;
  final DateTime? endDate;

  const CreateExpense({
    required this.expense,
    this.isRecurring = false,
    this.frequency,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [expense, isRecurring, frequency, startDate, endDate];
}

sealed class CreateIncomeEvent extends Equatable {
  const CreateIncomeEvent();
  @override
  List<Object> get props => [];
}

class CreateIncome extends CreateIncomeEvent{
  final Income income;
  const CreateIncome(this.income);
  @override
  List<Object> get props => [income];
}