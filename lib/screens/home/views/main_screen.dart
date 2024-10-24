import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_repository/repositories.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../Profile/UserProfile.dart';
import '../../transaction_history/TransactionHistory.dart';


class MainScreen extends StatefulWidget {
  final List<Expense> expenses;
  final List<Income> incomes;

  const MainScreen({Key? key, required this.expenses, required this.incomes}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class Transaction {
  final String id;
  final String name;
  final double amount;
  final DateTime date;
  final bool isIncome;
  final int color;
  final String icon;

  Transaction({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
    required this.isIncome,
    required this.color,
    required this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'date': date.toIso8601String(),
      'isIncome': isIncome,
      'color': color,
      'icon': icon,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map, String documentId) {
    return Transaction(
      id: documentId,
      name: map['name'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      isIncome: map['isIncome'],
      color: map['color'],
      icon: map['icon'],
    );
  }
}

class _MainScreenState extends State<MainScreen> {
  List<Transaction> transactions = [];
  final TextEditingController _totalBalanceController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  double _totalBudget = 0;
  double _remainingBudget = 0;
  String _userName = '';
  double _totalExpenses = 0;


  @override
  void initState() {
    super.initState();
    _fetchBudgetData();
    _loadTransactions();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _userName = userDoc['name'] ?? 'John Doe';  // Set the fetched name, defaulting to 'John Doe'
      });
    }
  }

  Future<void> _loadTransactions() async {
    transactions = await _fetchTransactions();

    // Calculate total expenses by summing up all non-income transactions
    double totalExpenses = 0;
    for (var transaction in transactions) {
      if (!transaction.isIncome) {
        totalExpenses += transaction.amount;
      }
    }

    setState(() {
      _totalExpenses = totalExpenses;  // Update the total expenses
    });
  }


  Future<List<Transaction>> _fetchTransactions() async {
    User? user = _auth.currentUser;
    if (user == null) return [];

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .get();

    return snapshot.docs
        .map((doc) => Transaction.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<void> _saveTransaction(Transaction transaction) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .doc(transaction.id)
        .set(transaction.toMap());

    // Recalculate total expenses
    if (!transaction.isIncome) {
      setState(() {
        _totalExpenses += transaction.amount;
      });
    }
  }



  Future<void> _fetchBudgetData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot budgetDoc = await FirebaseFirestore.instance.collection('budgets').doc(user.uid).get();
      if (budgetDoc.exists) {
        setState(() {
          _totalBudget = budgetDoc['budget'];
          _remainingBudget = budgetDoc['remaining'];
        });
      }
    }
  }

  /*Future<void> _handleCreateExpense(Expense expense) async {
    final result = await _firebaseExpenseRepo.createExpense(expense);

    if (result == null) {
      // Expense created successfully, update the UI here
      setState(() {
        _totalExpenses += expense.amount;
      });
    } else {
      // Handle any errors here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    }
  }*/


  List<Transaction> _getAllTransactions() {
    List<Transaction> transactions = [];

    for (var expense in widget.expenses) {
      transactions.add(
        Transaction(
            name: expense.category.name,
            amount: expense.amount.toDouble(),
            date: expense.date,
            isIncome: false,
            color: expense.category.color.toInt(),
            icon: expense.category.icon,
            id: expense.userId
        ),
      );
    }

    for (var income in widget.incomes) {
      transactions.add(
        Transaction(
            name: income.category2.name,
            amount: income.amount.toDouble(),
            date: income.date,
            isIncome: true,
            color: income.category2.color.toInt(),
            icon: income.category2.icon,
            id: income.userId
        ),
      );
    }

    transactions.sort((a, b) => b.date.compareTo(a.date));

    return transactions;
  }

  @override
  Widget build(BuildContext context) {
    List<Transaction> transactions = _getAllTransactions();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
        child: Column(
          children: [
            const SizedBox(height: 19,),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.yellow[700],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfilePage(),
                              ),
                            ).then((_) {
                              _fetchUserName();
                            });                          },
                          child: Icon(
                            CupertinoIcons.person_fill,
                            color: Colors.yellow[800],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(width: 8,),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome!",
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.outline
                          ),
                        ),
                        Text(
                          _userName,  // Display the fetched user name
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onBackground
                          ),
                        )
                      ],
                    ),
                  ],
                ),
                IconButton(onPressed: () {}, icon: const Icon(CupertinoIcons.calendar))
              ],
            ),
            const SizedBox(height: 20,),
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.width / 2,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                      Theme.of(context).colorScheme.tertiary,
                    ],
                    transform: const GradientRotation(pi / 4),
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                        blurRadius: 4,
                        color: Colors.grey.shade300,
                        offset: const Offset(5, 5)
                    )
                  ]
              ),

              child: Column(

                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 17),
                  const Text(
                    'Total Budget',
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '₱${_remainingBudget.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 25,
                              height: 25,
                              decoration: const BoxDecoration(
                                  color: Colors.white30,
                                  shape: BoxShape.circle
                              ),
                              child: const Center(
                                  child: Icon(
                                    CupertinoIcons.arrow_up,
                                    size: 12,
                                    color: Colors.greenAccent,
                                  )
                              ),
                            ),
                            const Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  ' Income',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w400
                                  ),
                                ),
                                Text(
                                  '00.00',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              width: 25,
                              height: 25,
                              decoration: const BoxDecoration(
                                color: Colors.white30,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  CupertinoIcons.arrow_down,
                                  size: 12,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                            Column(  // Remove the const here, since _totalExpenses is dynamic
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Expenses',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                Text(
                                  '₱${_totalExpenses.toStringAsFixed(2)}',  // No const here, dynamic content
                                  style: const TextStyle(  // const is fine here for static values
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )

                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transactions',
                  style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onBackground,
                      fontWeight: FontWeight.bold
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Navigate to TransactionHistory screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransactionHistory(transactions: transactions),
                      ),
                    );
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.outline,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                )
              ],
            ),

            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, int i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Color(transactions[i].color),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Image.asset(
                                      '${transactions[i].icon}',
                                      scale: 2,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  transactions[i].name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.onBackground,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "\₱${transactions[i].amount}0",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: transactions[i].isIncome ? Colors.green : Colors.redAccent,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd/MM/yyyy').format(transactions[i].date),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.outline,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(CupertinoIcons.delete),
                              onPressed: () {
                                if (transactions[i].isIncome) {
                                  _showDeleteIncomeConfirmationDialog(context, widget.incomes.firstWhere((income) => income.date == transactions[i].date && income.amount == transactions[i].amount));
                                } else {
                                  _showDeleteExpenseConfirmationDialog(context, widget.expenses.firstWhere((expense) => expense.date == transactions[i].date && expense.amount == transactions[i].amount));
                                }
                              },
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  void dispose() {
    _totalBalanceController.dispose();
    super.dispose();
  }

  void _deleteExpenseTransaction(Expense expense) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final budgetDoc = FirebaseFirestore.instance.collection('budgets').doc(user.uid);

      // Fetch the current remaining budget
      final budgetSnapshot = await budgetDoc.get();

      if (budgetSnapshot.exists) {
        final currentRemaining = budgetSnapshot.data()?['remaining'] ?? 0.0;

        // Add the deleted expense amount back to the remaining budget
        final newRemaining = currentRemaining + expense.amount;

        // Update the remaining field in the budget document
        await budgetDoc.update({
          'remaining': newRemaining,
        });

        // Now delete the expense
        FirebaseFirestore.instance
            .collection('expenses')
            .doc(expense.expenseId)
            .delete()
            .then((_) {
          setState(() {
            widget.expenses.remove(expense);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense transaction deleted and budget updated')),
          );
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete expense transaction')),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No budget found for the user')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No authenticated user found')),
      );
    }
  }


  void _showDeleteExpenseConfirmationDialog(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: const Text('Are you sure you want to delete this transaction?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteExpenseTransaction(expense);
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteIncomeTransaction(Income income) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final budgetDoc = FirebaseFirestore.instance.collection('budgets').doc(user.uid);

      // Fetch the current remaining budget
      final budgetSnapshot = await budgetDoc.get();

      if (budgetSnapshot.exists) {
        final currentRemaining = budgetSnapshot.data()?['remaining'] ?? 0.0;

        // Subtract the deleted income amount from the remaining budget
        final newRemaining = (currentRemaining - income.amount).clamp(0.0, double.infinity);

        // Update the remaining field in the budget document
        await budgetDoc.update({
          'remaining': newRemaining,
        });

        // Now delete the income transaction
        FirebaseFirestore.instance
            .collection('incomes')
            .doc(income.incomeId)
            .delete()
            .then((_) {
          setState(() {
            widget.incomes.remove(income);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Income transaction deleted and budget updated')),
          );
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete income transaction')),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No budget found for the user')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No authenticated user found')),
      );
    }
  }


  void _showDeleteIncomeConfirmationDialog(BuildContext context, Income income) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: const Text('Are you sure you want to delete this transaction?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteIncomeTransaction(income);
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}