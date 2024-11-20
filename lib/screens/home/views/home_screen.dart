import 'dart:math';
import 'package:campuscash/screens/budget_allocation/Budget.dart';
import 'package:campuscash/screens/budget_allocation/BudgetSelectionPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_repository/repositories.dart';
import 'package:campuscash/screens/addIncomeExpense/blocs/create_categorybloc/create_category_bloc.dart';
import 'package:campuscash/screens/addIncomeExpense/blocs/get_categories_bloc/get_categories_bloc.dart';
import 'package:campuscash/screens/addIncomeExpense/views/add_expense.dart';
import 'package:campuscash/screens/addIncomeExpense/views/add_income.dart';
import 'package:campuscash/screens/home/blocs/get_IncomeExpense_bloc/get_IncomeExpense_bloc.dart';
import 'package:campuscash/screens/home/views/main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../addIncomeExpense/blocs/create_expense_bloc/create_expense_bloc.dart';
import '../../budget_allocation/503020_records.dart';
import '../../budget_allocation/PayYourselfFirstRecords.dart';
import '../../budget_allocation/PriorityBasedRecords.dart';
import '../../budget_allocation/envelope_records.dart';
import '../../goal_loan/addGoalandLoan.dart';
import '../../stats/stats.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  Color selectedItem = Colors.blue;
  Color unselectedItem = Colors.grey;
  User? _currentUser = FirebaseAuth.instance.currentUser;

  Future<Widget> _fetchSavedData() async {
    try {
      if (_currentUser == null) return BudgetSelectionPage();
      final userId = _currentUser!.uid;
      final priorityBasedSnapshot = await FirebaseFirestore.instance
          .collection('PriorityBased')
          .doc(userId)
          .get();
      if (priorityBasedSnapshot.exists) {
        return PriorityBasedSummary(userId: userId);
      }

      final payYourselfFirstSnapshot = await FirebaseFirestore.instance
          .collection('PayYourselfFirst')
          .doc(userId)
          .get();
      if (payYourselfFirstSnapshot.exists) {
        return PayYourselfFirstRecords();
      }
      final envelopeSnapshot = await FirebaseFirestore.instance
          .collection('envelopeAllocations')
          .doc(userId)
          .collection('envelopes')
          .get();
      if (envelopeSnapshot.docs.isNotEmpty) {
        final allocations = <String, double>{};
        for (var doc in envelopeSnapshot.docs) {
          var data = doc.data();
          allocations[data['categoryName']] = (data['allocatedAmount'] as num).toDouble();
        }
        return EnvelopeBudgetingPage(allocations: allocations);
      }
      final budgetSnapshot = await FirebaseFirestore.instance
          .collection('503020')
          .doc(userId)
          .get();
      if (budgetSnapshot.exists) {
        final data = budgetSnapshot.data() as Map<String, dynamic>;
        final totalBudget = data['totalBudget'] ?? 0.0;
        final totalExpenses = data['totalExpenses'] ?? 0.0;
        final remainingBudget = totalBudget - totalExpenses;
        return BudgetSummaryPage(
          totalBudget: totalBudget,
          totalExpenses: totalExpenses,
          remainingBudget: remainingBudget,
          expenses: {
            'Needs': data['Needs'],
            'Wants': data['Wants'],
            'Savings': data['Savings'],
          },
          userId: userId,
        );
      }
      return BudgetSelectionPage();
    } catch (e) {
      return Scaffold(
        body: Center(
          child: Text('Failed to fetch saved data: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GetExpensesBloc, GetExpensesState>(
        builder: (context, expensesState) {
          return BlocBuilder<GetIncomesBloc, GetIncomesState>(
              builder: (context, incomesState) {
                if (expensesState is GetExpensesSuccess && incomesState is GetIncomesSuccess) {
                  return Scaffold(
                    bottomNavigationBar: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                      child: BottomNavigationBar(
                        onTap: (value) {
                          setState(() {
                            index = value;
                          });
                        },
                        showSelectedLabels: false,
                        showUnselectedLabels: false,
                        elevation: 3,
                        selectedFontSize: 14,
                        unselectedFontSize: 14,
                        iconSize: 24,
                        selectedItemColor: selectedItem,
                        unselectedItemColor: unselectedItem,
                        items: [
                          BottomNavigationBarItem(
                            icon: Icon(
                              CupertinoIcons.home,
                              color: index == 0 ? selectedItem : unselectedItem,
                            ),
                            label: 'Home',
                          ),
                          BottomNavigationBarItem(
                            icon: Icon(
                              CupertinoIcons.graph_square_fill,
                              color: index == 1 ? selectedItem : unselectedItem,
                            ),
                            label: 'Stats',
                          ),
                          BottomNavigationBarItem(
                            icon: Icon(
                              CupertinoIcons.money_dollar_circle_fill,
                              color: index == 2 ? selectedItem : unselectedItem,
                            ),
                            label: 'Budget',
                          ),
                          BottomNavigationBarItem(
                            icon: Icon(
                              CupertinoIcons.flag_fill,
                              color: index == 3 ? selectedItem : unselectedItem,
                            ),
                            label: 'Goals',
                          ),
                        ],
                      ),
                    ),
                    floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
                    floatingActionButton: SpeedDial(
                      icon: CupertinoIcons.plus,
                      children: [
                        SpeedDialChild(
                            child: const Icon(
                              CupertinoIcons.money_dollar_circle_fill,
                              color: Colors.green,
                            ),
                            label: 'Income',
                            onTap: () async {
                              Income? newIncome = await Navigator.push(
                                context,
                                MaterialPageRoute<Income>(
                                  builder: (BuildContext context) => MultiBlocProvider(
                                    providers: [
                                      BlocProvider(
                                        create: (context) => CreateCategoryBloc2(FirebaseExpenseRepo2()),
                                      ),
                                      BlocProvider(
                                        create: (context) => GetCategoriesBloc2(FirebaseExpenseRepo2())..add(GetCategories2()),
                                      ),
                                      BlocProvider(
                                        create: (context) => CreateIncomeBloc(FirebaseExpenseRepo2()),
                                      ),
                                    ],
                                    child: const AddIncome(),
                                  ),
                                ),
                              );
                              if (newIncome != null) {
                                setState(() {
                                  if (incomesState is GetIncomesSuccess) {
                                    incomesState.incomes.insert(0, newIncome);
                                  }
                                });
                              }
                            }
                        ),

                        SpeedDialChild(
                            child: const Icon(
                              CupertinoIcons.money_dollar_circle_fill,
                              color: Colors.red,
                            ),
                            label: 'Expense',
                            onTap: () async {
                              Expense? newExpense = await Navigator.push(
                                context,
                                MaterialPageRoute<Expense>(
                                  builder: (BuildContext context) => MultiBlocProvider(
                                    providers: [
                                      BlocProvider(
                                        create: (context) => CreateCategoryBloc(FirebaseExpenseRepo()),
                                      ),
                                      BlocProvider(
                                        create: (context) => GetCategoriesBloc(FirebaseExpenseRepo())..add(GetCategories()),
                                      ),
                                      BlocProvider(
                                        create: (context) => CreateExpenseBloc(FirebaseExpenseRepo()),
                                      ),
                                    ],
                                    child: const AddExpense(),
                                  ),
                                ),
                              );
                              if (newExpense != null) {
                                setState(() {
                                  if (expensesState is GetExpensesSuccess) {
                                    expensesState.expenses.insert(0, newExpense);
                                  }
                                });
                              }
                            }
                        ),
                      ],
                      shape: const CircleBorder(),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.tertiary,
                              Theme.of(context).colorScheme.secondary,
                              Theme.of(context).colorScheme.primary,
                            ],
                            transform: const GradientRotation(pi / 4),
                          ),
                        ),
                        child: const Icon(CupertinoIcons.add),
                      ),
                    ),
                    body: _buildBody(index, expensesState.expenses, incomesState.incomes),
                  );
                } else {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
              }
          );
        }
    );
  }
  Widget _buildBody(int index, List<Expense> expenses, List<Income> incomes) {
    switch (index) {
      case 0:
        return MainScreen(expenses: expenses, incomes: incomes, monthlyTransactions: []);
      case 1:
        return ChartScreen(expenses: expenses, income: incomes);
      case 2:
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('budgets').get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              return Budget();
            } else {
              return FutureBuilder<Widget>(
                future: _fetchSavedData(),
                builder: (context, savedDataSnapshot) {
                  if (savedDataSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (savedDataSnapshot.hasData) {
                    return savedDataSnapshot.data!;
                  } else {
                    return BudgetSelectionPage();
                  }
                },
              );
            }
          },
        );
      case 3:
        return const CustomTabBarsPage();
      default:
        return Container();
    }
  }
}
