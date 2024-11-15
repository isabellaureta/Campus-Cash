import 'package:expense_repository/repositories.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../home/views/main_screen.dart';

enum TransactionFilter { thisWeek, thisMonth, allTime }

class TransactionHistory extends StatefulWidget {
  final List<Transaction_> transactions;
  final List<Transaction_> monthlyTransactions;
  final List<Expense> expenses;
  final List<Income> incomes;

  const TransactionHistory({Key? key, required this.transactions, required this.monthlyTransactions, required this.expenses, required this.incomes})
      : super(key: key);

  @override
  _TransactionHistoryState createState() => _TransactionHistoryState();
}

class _TransactionHistoryState extends State<TransactionHistory> {
  TransactionFilter _selectedFilter = TransactionFilter.allTime;

  @override
  Widget build(BuildContext context) {
    List<Transaction_> filteredTransactions = _filterTransactions(_selectedFilter);

    return Scaffold(
      appBar: AppBar(
        title: Text("Transaction History"),
      ),
      body: Column(
        children: [
          Material(
            child: _buildFilterOptions(),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredTransactions.length,
              itemBuilder: (context, int i) {
                return GestureDetector(
                  onTap: () {
                    _showTransactionDetailsDialog(context, filteredTransactions[i]);
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
                                        color: Color(filteredTransactions[i].color),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Image.asset(
                                      '${filteredTransactions[i].icon}',
                                      scale: 2,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  filteredTransactions[i].name,
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
                                  "\₱${filteredTransactions[i].amount}0",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: filteredTransactions[i].isIncome ? Colors.green : Colors.redAccent,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd/MM/yyyy').format(filteredTransactions[i].date),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.outline,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            /*IconButton(
                              icon: const Icon(CupertinoIcons.delete),
                              onPressed: () {
                                if (transactions[i].isIncome) {
                                  _showDeleteIncomeConfirmationDialog(context, widget.incomes.firstWhere((income) => income.date == transactions[i].date && income.amount == transactions[i].amount));
                                } else {
                                  _showDeleteExpenseConfirmationDialog(context, widget.expenses.firstWhere((expense) => expense.date == transactions[i].date && expense.amount == transactions[i].amount));
                                }
                              },
                            )
                        */


                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions() {
    return DropdownButton<TransactionFilter>(
      value: _selectedFilter,
      items: TransactionFilter.values.map((filter) {
        return DropdownMenuItem<TransactionFilter>(
          value: filter,
          child: Text(_filterName(filter)),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedFilter = value;
          });
        }
      },
    );
  }

  List<Transaction_> _filterTransactions(TransactionFilter filter) {
    DateTime now = DateTime.now();
    switch (filter) {
      case TransactionFilter.thisWeek:
        DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return widget.transactions.where((transaction) {
          return transaction.date.isAfter(startOfWeek);
        }).toList();
      case TransactionFilter.thisMonth:
        DateTime startOfMonth = DateTime(now.year, now.month, 1);
        return widget.transactions.where((transaction) {
          return transaction.date.isAfter(startOfMonth);
        }).toList();
      case TransactionFilter.allTime:
      default:
        return widget.transactions;
    }
  }

  String _filterName(TransactionFilter filter) {
    switch (filter) {
      case TransactionFilter.thisWeek:
        return 'This Week';
      case TransactionFilter.thisMonth:
        return 'This Month';
      case TransactionFilter.allTime:
      default:
        return 'All Time';
    }
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

  void _deleteExpenseTransaction(Expense expense) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Update totalMoneyAmount in totalMoney collection
      final totalMoneyDoc = FirebaseFirestore.instance.collection('totalMoney').doc(user.uid);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final totalMoneySnapshot = await transaction.get(totalMoneyDoc);
        double currentTotalMoney = totalMoneySnapshot.exists
            ? (totalMoneySnapshot['totalMoneyAmount'] ?? 0.0).toDouble()
            : 0.0;
        double updatedTotalMoney = currentTotalMoney + expense.amount;
        transaction.set(totalMoneyDoc, {
          'totalMoneyAmount': updatedTotalMoney,
        }, SetOptions(merge: true));
      });

      // Attempt to update the budgets collection if it exists
      final budgetDoc = FirebaseFirestore.instance.collection('budgets').doc(user.uid);
      final budgetSnapshot = await budgetDoc.get();
      if (budgetSnapshot.exists) {
        final currentRemaining = budgetSnapshot.data()?['remaining'] ?? 0.0;
        final newRemaining = currentRemaining + expense.amount;
        await budgetDoc.update({
          'remaining': newRemaining,
        });
      }

      // Delete the expense transaction
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
        const SnackBar(content: Text('No authenticated user found')),
      );
    }
  }

  void _deleteIncomeTransaction(Income income) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Update totalMoneyAmount in totalMoney collection
      final totalMoneyDoc = FirebaseFirestore.instance.collection('totalMoney').doc(user.uid);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final totalMoneySnapshot = await transaction.get(totalMoneyDoc);
        double currentTotalMoney = totalMoneySnapshot.exists
            ? (totalMoneySnapshot['totalMoneyAmount'] ?? 0.0).toDouble()
            : 0.0;
        double updatedTotalMoney = currentTotalMoney - income.amount;
        transaction.set(totalMoneyDoc, {
          'totalMoneyAmount': updatedTotalMoney,
        }, SetOptions(merge: true));
      });

      // Attempt to update the budgets collection if it exists
      final budgetDoc = FirebaseFirestore.instance.collection('budgets').doc(user.uid);
      final budgetSnapshot = await budgetDoc.get();
      if (budgetSnapshot.exists) {
        final currentRemaining = budgetSnapshot.data()?['remaining'] ?? 0.0;
        final newRemaining = (currentRemaining - income.amount).clamp(0.0, double.infinity);
        await budgetDoc.update({
          'remaining': newRemaining,
        });
      }

      // Delete the income transaction
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
        const SnackBar(content: Text('No authenticated user found')),
      );
    }
  }
}