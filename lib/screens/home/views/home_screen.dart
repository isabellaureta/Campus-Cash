import 'dart:math';

import 'package:expense_repository/expense_repository.dart';
import 'package:expenses_tracker/main.dart';
import 'package:expenses_tracker/screens/add_expense/blocs/create_categorybloc/create_category_bloc.dart';
import 'package:expenses_tracker/screens/add_expense/blocs/get_categories_bloc/get_categories_bloc.dart';
import 'package:expenses_tracker/screens/add_expense/views/add_expense.dart';
import 'package:expenses_tracker/screens/add_expense/views/add_income.dart';
import 'package:expenses_tracker/screens/budget_allocation/BudgetAllocation.dart';
import 'package:expenses_tracker/screens/home/blocs/get_expenses_bloc/get_expenses_bloc.dart';
import 'package:expenses_tracker/screens/home/views/main_screen.dart';
import 'package:expenses_tracker/screens/plan/planning_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../add_expense/blocs/create_expense_bloc/create_expense_bloc.dart';
import '../../plan/add_new_plan_screen.dart';
import '../../stats/stats.dart';

import 'package:flutter_speed_dial/flutter_speed_dial.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  late Color selectedItem = Colors.blue;
  Color unselectedItem = Colors.grey;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GetExpensesBloc, GetExpensesState>(
        builder: (context, expensesState) {
          return BlocBuilder<GetIncomesBloc, GetIncomesState>(
              builder: (context, incomesState) {
                if (expensesState is GetExpensesSuccess) {

                  return Scaffold(
                      bottomNavigationBar: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(30)),
                        child: BottomNavigationBar(
                            onTap: (value) {
                              setState(() {
                                index = value;
                              });
                            },
                            showSelectedLabels: false,
                            showUnselectedLabels: false,
                            elevation: 3,
                            items: [
                              BottomNavigationBarItem(
                                  icon: Icon(
                                      CupertinoIcons.home,
                                      color: index == 0
                                          ? selectedItem
                                          : unselectedItem),
                                  label: 'Budget'),
                              BottomNavigationBarItem(
                                  icon: Icon(
                                      CupertinoIcons.money_dollar_circle_fill,
                                      color: index == 1
                                          ? selectedItem
                                          : unselectedItem),
                                  label: 'Home'),
                              BottomNavigationBarItem(
                                  icon: Icon(
                                      CupertinoIcons.graph_square_fill,
                                      color: index == 2
                                          ? selectedItem
                                          : unselectedItem),
                                  label: 'Stats'),
                            ]),
                      ),


                      floatingActionButtonLocation: FloatingActionButtonLocation
                          .endFloat,
                      floatingActionButton: SpeedDial(
                        icon: CupertinoIcons.plus,
                        children: [
/*
                          SpeedDialChild(
                              child: const Icon(
                                CupertinoIcons.money_dollar_circle_fill,
                                color: Colors.red,
                              ),
                              label: 'Income',
                              onTap: () async {
                                Income? newIncome = await Navigator.push(
                                  context,
                                  MaterialPageRoute<Income>(
                                    builder: (BuildContext context) =>
                                        MultiBlocProvider(
                                          providers: [
                                            BlocProvider(
                                              create: (context) =>
                                                  CreateCategoryBloc2(
                                                      FirebaseExpenseRepo2()),
                                            ),
                                            BlocProvider(
                                              create: (context) =>
                                              GetCategoriesBloc2(
                                                  FirebaseExpenseRepo2())
                                                ..add(GetCategories2()),
                                            ),
                                            BlocProvider(
                                              create: (context) =>
                                                  CreateIncomeBloc(
                                                      FirebaseExpenseRepo2()),
                                            ),
                                          ],
                                          child: const AddIncome(),
                                        ),
                                  ),
                                );

                                if (newIncome != null) {
                                  setState(() {
                                    incomesState.incomes.insert(0, newIncome);
                                  });
                                }
                              }
                          ),
*/

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
                                    builder: (BuildContext context) =>
                                        MultiBlocProvider(
                                          providers: [
                                            BlocProvider(
                                              create: (context) =>
                                                  CreateCategoryBloc(
                                                      FirebaseExpenseRepo()),
                                            ),
                                            BlocProvider(
                                              create: (context) =>
                                              GetCategoriesBloc(
                                                  FirebaseExpenseRepo())
                                                ..add(GetCategories()),
                                            ),
                                            BlocProvider(
                                              create: (context) =>
                                                  CreateExpenseBloc(
                                                      FirebaseExpenseRepo()),
                                            ),
                                          ],
                                          child: const AddExpense(),
                                        ),
                                  ),
                                );

                                if (newExpense != null) {
                                  setState(() {
                                    expensesState.expenses.insert(
                                        0, newExpense);
                                  });
                                }
                              }
                          )
                        ],
                        shape: const CircleBorder(),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Theme
                                      .of(context)
                                      .colorScheme
                                      .tertiary,
                                  Theme
                                      .of(context)
                                      .colorScheme
                                      .secondary,
                                  Theme
                                      .of(context)
                                      .colorScheme
                                      .primary,
                                ],
                                transform: const GradientRotation(pi / 4),
                              )),
                          child: const Icon(CupertinoIcons.add),
                        ),
                      ),

                    body: index == 0
                        ? MainScreen(expenses: expensesState.expenses)
                        : ChartScreen(expenses: expensesState.expenses),
                  );
                }

                else {
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
}