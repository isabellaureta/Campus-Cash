import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_repository/repositories.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../Profile/UserProfile.dart';
import '../../transaction_history/TransactionHistory.dart';

class MainScreen extends StatefulWidget {
  final List<Expense> expenses;
  final List<Income> incomes;
  final List<Transaction_> monthlyTransactions;

  const MainScreen({Key? key, required this.expenses, required this.incomes, required this.monthlyTransactions,  // Add it to the constructor
  }) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class Transaction_ {
  final String id;
  final String name;
  final double amount;
  final DateTime date;
  final bool isIncome;
  final int color;
  final String icon;
  final String? description;

  Transaction_({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
    required this.isIncome,
    required this.color,
    required this.icon,
    this.description,
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
      'description': description
    };
  }

  factory Transaction_.fromMap(Map<String, dynamic> map, String documentId) {
    return Transaction_(
      id: documentId,
      name: map['name'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      isIncome: map['isIncome'],
      color: map['color'],
      icon: map['icon'],
      description: map['description']
    );
  }
}

class _MainScreenState extends State<MainScreen> {
  List<Transaction_> transactions = [];
  final TextEditingController _totalBalanceController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  double _remainingBudget = 0;
  String _userName = '';
  String? _profileImageUrl;
  double _totalBalance = 0.0;
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;


  @override
  void initState() {
    super.initState();
    _fetchBudgetData();
    _loadTransactions();
    _fetchUserName();
    fetchTotalMoney();
  }

  Future<void> _fetchUserName() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection(
          'users').doc(user.uid).get();
      setState(() {
        _userName = userDoc['name'] ?? 'John Doe';
        _profileImageUrl =
        userDoc['profileImageUrl'];
      });
    }
  }

  Future<void> _loadTransactions() async {
    transactions = await _fetchTransactions();
    double totalExpenses = 0;
    for (var transaction in transactions) {
      if (!transaction.isIncome) {
        totalExpenses += transaction.amount;
      }
    }

    setState(() {
      _totalExpenses = totalExpenses;
    });
  }

  Future<List<Transaction_>> _fetchTransactions() async {
    User? user = _auth.currentUser;
    if (user == null) return [];
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .get();
    return snapshot.docs
        .map((doc) =>
        Transaction_.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<void> _fetchBudgetData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot budgetDoc = await FirebaseFirestore.instance.collection(
          'budgets').doc(user.uid).get();
      if (budgetDoc.exists && budgetDoc.data() != null) {
        setState(() {
          _remainingBudget = budgetDoc['remaining'] ?? _remainingBudget;
        });
      }

      if (_remainingBudget ==
          0) {
        DocumentSnapshot budget503020Doc = await FirebaseFirestore.instance
            .collection('503020').doc(user.uid).get();
        if (budget503020Doc.exists && budget503020Doc.data() != null) {
          setState(() {
            _remainingBudget =
                budget503020Doc['remainingBudget'] ?? _remainingBudget;
          });
        }
      }

      if (_remainingBudget ==
          0) {
        DocumentSnapshot envelopeDoc = await FirebaseFirestore.instance
            .collection('envelopeAllocations').doc(user.uid).get();
        if (envelopeDoc.exists && envelopeDoc.data() != null) {
          setState(() {
            _remainingBudget =
                envelopeDoc['remainingEnvelope'] ?? _remainingBudget;
          });
        }
      }

      if (_remainingBudget ==
          0) {
        DocumentSnapshot payYourselfFirstDoc = await FirebaseFirestore.instance
            .collection('PayYourselfFirst').doc(user.uid).get();
        if (payYourselfFirstDoc.exists && payYourselfFirstDoc.data() != null) {
          setState(() {
            _remainingBudget =
                payYourselfFirstDoc['remainingYourself'] ?? _remainingBudget;
          });
        }
      }

      if (_remainingBudget ==
          0) {
        DocumentSnapshot priorityBasedDoc = await FirebaseFirestore.instance
            .collection('PriorityBased').doc(user.uid).get();
        if (priorityBasedDoc.exists && priorityBasedDoc.data() != null) {
          setState(() {
            _remainingBudget =
                priorityBasedDoc['remainingBudget'] ?? _remainingBudget;
          });
        }
      }
    }
  }

  Future<void> fetchTotalMoney() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final totalMoneyDoc = FirebaseFirestore.instance.collection('totalMoney').doc(user.uid);
    final snapshot = await totalMoneyDoc.get();
    if (snapshot.exists) {
      setState(() {
        _totalBalance = snapshot['totalMoneyAmount'] ?? 0.0;
        _totalIncome = snapshot['totalIncome'] ?? 0.0;
        _totalExpenses = snapshot['totalExpense'] ?? 0.0;
      });
    } else {
      log('No total money document found for user ${user.uid}' as num);
    }
  }


  List<Transaction_> _getAllTransactions() {
    List<Transaction_> transactions = [];
    for (var expense in widget.expenses) {
      transactions.add(
        Transaction_(
            name: expense.category.name,
            amount: expense.amount.toDouble(),
            date: expense.date,
            isIncome: false,
            color: expense.category.color.toInt(),
            icon: expense.category.icon,
            id: expense.userId,
            description: expense.description
        ),
      );
    }
    for (var income in widget.incomes) {
      transactions.add(
        Transaction_(
            name: income.category2.name,
            amount: income.amount.toDouble(),
            date: income.date,
            isIncome: true,
            color: income.category2.color.toInt(),
            icon: income.category2.icon,
            id: income.userId,
            description: income.description
        ),
      );
    }
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  @override
  Widget build(BuildContext context) {
    List<Transaction_> transactions = _getAllTransactions();
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
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfilePage(),
                              ),
                            ).then((_) {
                              _fetchUserName();
                            });
                          },
                          child: CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.yellow[700],
                            backgroundImage: _profileImageUrl != null
                                ? NetworkImage(_profileImageUrl!)
                                : null,
                            child: _profileImageUrl == null
                                ? Icon(
                              CupertinoIcons.person_fill,
                              color: Colors.yellow[800],
                            )
                                : null,
                          ),
                        ),
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
                              color: Theme
                                  .of(context)
                                  .colorScheme
                                  .outline
                          ),
                        ),
                        Text(
                          _userName, // Display the fetched user name
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme
                                  .of(context)
                                  .colorScheme
                                  .onBackground
                          ),
                        )
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () async {
                  },
                  icon: const Icon(CupertinoIcons.calendar),
                ),
              ],
            ),
            const SizedBox(height: 20,),
            Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.width * 0.5, // Adjust height for extra text
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
                    color: Colors.grey.shade500,
                    offset: const Offset(5, 5),
                  )
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 17),
                    const Text(
                      'Total Balance',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '₱${NumberFormat('#,##0.00').format(_totalBalance)}',
                      style: TextStyle(
                        fontSize: 40,
                        color: _totalBalance < 0 ? Colors.red : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400, // Grey circle
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_downward, // Down arrow icon for expense
                                color: Colors.redAccent,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '₱${NumberFormat('#,##0.00').format(_totalExpenses)}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.red.shade100,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400, // Grey circle
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_upward, // Up arrow icon for income
                                color: Colors.green.shade800,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '₱${NumberFormat('#,##0.00').format(_totalIncome)}',
                              style:  TextStyle(
                                fontSize: 16,
                                color: Colors.green.shade100,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: MediaQuery
                  .of(context)
                  .size
                  .width * 0.9,
              height: MediaQuery
                  .of(context)
                  .size
                  .width * 0.4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.shade50,
                    Colors.pink.shade50,
                    Colors.blue.shade50,
                  ],
                  transform: const GradientRotation(pi / 4),
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 6,
                    color: Colors.grey.shade500,
                    offset: const Offset(4, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 17),
                    const Text(
                      'Budget Balance',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '₱${_remainingBudget.toStringAsFixed(2).replaceAllMapped(
                          RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}',
                      style: TextStyle(
                        fontSize: 40,
                        color: _remainingBudget < 0 ? Colors.redAccent : Colors
                            .black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [],
                      ),
                    ),
                  ],
                ),
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
                      color: Theme
                          .of(context)
                          .colorScheme
                          .onBackground,
                      fontWeight: FontWeight.bold
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                        builder: (context) => TransactionHistory(
                      transactions: transactions,
                    ),));
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme
                          .of(context)
                          .colorScheme
                          .outline,
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
                    return GestureDetector(
                      onTap: () {
                        _showTransactionDetailsDialog(context, transactions[i]);
                      },
                      child: Padding(
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
                                        color: Theme
                                            .of(context)
                                            .colorScheme
                                            .onBackground,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "\₱${NumberFormat('#,##0.00').format(transactions[i].amount)}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: transactions[i].isIncome ? Colors.green : Colors.redAccent,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('dd/MM/yyyy').format(
                                          transactions[i].date),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme
                                            .of(context)
                                            .colorScheme
                                            .outline,
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
                      ),
                    );
                  }
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetailsDialog(BuildContext context, Transaction_ transaction) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Transaction Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: ${DateFormat('dd/MM/yyyy').format(transaction.date)}'),
              const SizedBox(height: 8),
              Text('Category: ${transaction.name}'),
              const SizedBox(height: 8),
              Text('Amount: ₱${transaction.amount.toStringAsFixed(2)}'),
              if (transaction.description != null && transaction.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Note: ${transaction.description}'),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
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
      final totalMoneyDoc = FirebaseFirestore.instance.collection('totalMoney').doc(user.uid);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final totalMoneySnapshot = await transaction.get(totalMoneyDoc);

        double currentTotalMoney = totalMoneySnapshot.exists
            ? (totalMoneySnapshot['totalMoneyAmount'] ?? 0.0).toDouble()
            : 0.0;
        double currentTotalExpense = totalMoneySnapshot.exists
            ? (totalMoneySnapshot['totalExpense'] ?? 0.0).toDouble()
            : 0.0;
        double updatedTotalMoney = currentTotalMoney + expense.amount;
        double updatedTotalExpense = currentTotalExpense - expense.amount;
        transaction.set(totalMoneyDoc, {
          'totalMoneyAmount': updatedTotalMoney,
          'totalExpense': updatedTotalExpense,
        }, SetOptions(merge: true));
      });

      final budgetDoc = FirebaseFirestore.instance.collection('budgets').doc(user.uid);
      final budgetSnapshot = await budgetDoc.get();
      if (budgetSnapshot.exists) {
        final currentRemaining = budgetSnapshot.data()?['remaining'] ?? 0.0;
        final newRemaining = currentRemaining + expense.amount;
        await budgetDoc.update({
          'remaining': newRemaining,
        });
      }

      FirebaseFirestore.instance
          .collection('expenses')
          .doc(expense.expenseId)
          .delete()
          .then((_) {
        setState(() {
          widget.expenses.remove(expense);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense transaction deleted')),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete expense transaction')),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No authenticated user found')),
      );
    }
  }

  void _deleteIncomeTransaction(Income income) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final totalMoneyDoc = FirebaseFirestore.instance.collection('totalMoney').doc(user.uid);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final totalMoneySnapshot = await transaction.get(totalMoneyDoc);

        double currentTotalMoney = totalMoneySnapshot.exists
            ? (totalMoneySnapshot['totalMoneyAmount'] ?? 0.0).toDouble()
            : 0.0;
        double currentTotalIncome = totalMoneySnapshot.exists
            ? (totalMoneySnapshot['totalIncome'] ?? 0.0).toDouble()
            : 0.0;
        double updatedTotalMoney = currentTotalMoney - income.amount;
        double updatedTotalIncome = currentTotalIncome - income.amount;

        transaction.set(totalMoneyDoc, {
          'totalMoneyAmount': updatedTotalMoney,
          'totalIncome': updatedTotalIncome,
        }, SetOptions(merge: true));
      });

      final budgetDoc = FirebaseFirestore.instance.collection('budgets').doc(user.uid);
      final budgetSnapshot = await budgetDoc.get();
      if (budgetSnapshot.exists) {
        final currentRemaining = budgetSnapshot.data()?['remaining'] ?? 0.0;
        final newRemaining = (currentRemaining - income.amount).clamp(0.0, double.infinity);
        await budgetDoc.update({
          'remaining': newRemaining,
        });
      }

      FirebaseFirestore.instance
          .collection('incomes')
          .doc(income.incomeId)
          .delete()
          .then((_) {
        setState(() {
          widget.incomes.remove(income);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Income transaction deleted')),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete income transaction')),
        );
      });
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