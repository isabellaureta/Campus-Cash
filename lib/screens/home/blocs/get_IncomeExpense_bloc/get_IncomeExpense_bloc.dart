import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_repository/repositories.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        // Log the error to see if it’s a permissions issue
        print("Error in GetExpensesBloc: $e");
        emit(GetExpensesFailure());
      }
    });

  }

  Future<List<Expense>> getExpenses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return []; // If no authenticated user, return an empty list

    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: user.uid) // Only fetch expenses for the logged-in user
        .get();

    return snapshot.docs
        .map((doc) => Expense.fromEntity(
        ExpenseEntity.fromDocument(doc.data() as Map<String, dynamic>)))
        .toList();
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

  Future<List<Income>> getIncome() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('incomes')
        .where('userId', isEqualTo: user.uid) // Only fetch incomes for the logged-in user
        .get();

    return snapshot.docs
        .map((doc) => Income.fromEntity(
        IncomeEntity.fromDocument(doc.data() as Map<String, dynamic>)))
        .toList();
  }
}
