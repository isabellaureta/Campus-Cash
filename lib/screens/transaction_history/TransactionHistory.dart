import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../home/views/main_screen.dart';

class TransactionHistory extends StatefulWidget {
  final List<Transaction_> transactions;

  const TransactionHistory({Key? key, required this.transactions})
      : super(key: key);

  @override
  _TransactionHistoryState createState() => _TransactionHistoryState();
}

class _TransactionHistoryState extends State<TransactionHistory> {
  String selectedFrequency = 'All Time';
  List<Transaction_> filteredTransactions = [];
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    filteredTransactions = widget.transactions;
  }

  void _changeDate(bool increment) {
    setState(() {
      switch (selectedFrequency) {
        case 'Daily':
          selectedDate = selectedDate.add(Duration(days: increment ? 1 : -1));
          break;
        case 'Weekly':
          selectedDate =
              selectedDate.add(Duration(days: increment ? 7 : -7));
          break;
        case 'Monthly':
          selectedDate = DateTime(
            selectedDate.year,
            selectedDate.month + (increment ? 1 : -1),
          );
          break;
        case 'All Time':
          break;
      }
      _filterTransactions();
    });
  }

  void _filterTransactions() {
    DateTime now = selectedDate;

    List<Transaction_> filtered;
    switch (selectedFrequency) {
      case 'Daily':
        filtered = widget.transactions.where((transaction) {
          return isSameDay(transaction.date, now);
        }).toList();
        break;

      case 'Weekly':
        DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
        filtered = widget.transactions.where((transaction) {
          return transaction.date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
              transaction.date.isBefore(endOfWeek.add(const Duration(days: 1)));
        }).toList();
        break;

      case 'Monthly':
        filtered = widget.transactions.where((transaction) {
          return transaction.date.year == now.year &&
              transaction.date.month == now.month;
        }).toList();
        break;

      case 'All Time':
      default:
        filtered = widget.transactions;
    }

    setState(() {
      filteredTransactions = filtered;
    });
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _getDisplayedDate() {
    switch (selectedFrequency) {
      case 'Daily':
        return DateFormat.yMMMd().format(selectedDate);
      case 'Weekly':
        DateTime weekEnd = selectedDate.add(Duration(days: 6));
        return "${DateFormat.yMMMd().format(selectedDate)} - ${DateFormat.yMMMd().format(weekEnd)}";
      case 'Monthly':
        return DateFormat.yMMMM().format(selectedDate);
      default:
        return "All Time";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
      ),
      body: Column(
        children: [
          // Navigation and Filter Controls
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => _changeDate(false),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Text(
                      _getDisplayedDate(),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () => _changeDate(true),
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
                DropdownButton<String>(
                  value: selectedFrequency,
                  isExpanded: true,
                  items: <String>['All Time', 'Daily', 'Weekly', 'Monthly']
                      .map((String frequency) {
                    return DropdownMenuItem<String>(
                      value: frequency,
                      child: Text(frequency),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedFrequency = newValue;
                        _filterTransactions();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          // Transactions List
          Expanded(
            child: filteredTransactions.isEmpty
                ? const Center(
              child: Text(
                'No transactions found',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: filteredTransactions.length,
              itemBuilder: (context, int i) {
                return GestureDetector(
                  onTap: () {
                    _showTransactionDetailsDialog(
                        context, filteredTransactions[i]);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(
                        bottom: 16.0, left: 16.0, right: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
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
                                        color: Color(
                                            filteredTransactions[i]
                                                .color),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Image.asset(
                                      filteredTransactions[i].icon,
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
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onBackground,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "\₱${filteredTransactions[i].amount.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: filteredTransactions[i]
                                        .isIncome
                                        ? Colors.green
                                        : Colors.redAccent,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd/MM/yyyy').format(
                                      filteredTransactions[i].date),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
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

  void _showTransactionDetailsDialog(
      BuildContext context, Transaction_ transaction) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Transaction Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Date: ${DateFormat('dd/MM/yyyy').format(transaction.date)}'),
              const SizedBox(height: 8),
              Text('Category: ${transaction.name}'),
              const SizedBox(height: 8),
              Text('Amount: ₱${transaction.amount.toStringAsFixed(2)}'),
              if (transaction.description != null &&
                  transaction.description!.isNotEmpty)
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
}

