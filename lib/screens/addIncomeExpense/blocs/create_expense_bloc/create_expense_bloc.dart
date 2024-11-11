import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_repository/repositories.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'create_expense_event.dart';
part 'create_expense_state.dart';

class CreateExpenseBloc extends Bloc<CreateExpenseEvent, CreateExpenseState> {
  final ExpenseRepository expenseRepository;

  CreateExpenseBloc(this.expenseRepository) : super(CreateExpenseInitial()) {
    on<CreateExpense>((event, emit) async {
      emit(CreateExpenseLoading());
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('No authenticated user found.');
        }

        final expense = Expense(
          expenseId: event.expense.expenseId,
          userId: user.uid,
          category: event.expense.category,
          date: event.expense.date,
          amount: event.expense.amount,
          description: event.expense.description
        );

        // Pass recurring options to the repository if the expense is marked as recurring
        await expenseRepository.createExpense(
          expense,
          isRecurring: event.isRecurring,
          frequency: event.frequency,
          startDate: event.startDate,
          endDate: event.endDate,
        );

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
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('No authenticated user found.');
        }

        final income = Income(
          incomeId: event.income.incomeId,
          userId: user.uid,
          category2: event.income.category2,
          date: event.income.date,
          amount: event.income.amount,
          description: event.income.description
        );

        await incomeRepository.createIncome(income);
        emit(CreateIncomeSuccess());
      } catch (e) {
        emit(CreateIncomeFailure());
      }
    });
  }
}


