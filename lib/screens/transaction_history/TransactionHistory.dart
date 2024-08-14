import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../home/views/main_screen.dart';

// Enum to represent different transaction filters
enum TransactionFilter { thisWeek, thisMonth, allTime }

class TransactionHistory extends StatefulWidget {
  final List<Transaction> transactions;

  const TransactionHistory({Key? key, required this.transactions}) : super(key: key);

  @override
  _TransactionHistoryState createState() => _TransactionHistoryState();
}

class _TransactionHistoryState extends State<TransactionHistory> {
  TransactionFilter _selectedFilter = TransactionFilter.allTime;

  @override
  Widget build(BuildContext context) {
    List<Transaction> filteredTransactions = _filterTransactions(_selectedFilter);

    return Scaffold(
      appBar: AppBar(
        title: Text("Transaction History"),
      ),
      body: Column(
        children: [
          // Dropdown wrapped in Material to avoid the error
          Material(
            child: _buildFilterOptions(),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredTransactions.length,
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
                          IconButton(
                            icon: const Icon(CupertinoIcons.delete),
                            onPressed: () {
                              // Handle delete
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
    );
  }

  // Method to build filter options as a dropdown menu
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

  // Method to filter transactions based on selected filter
  List<Transaction> _filterTransactions(TransactionFilter filter) {
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

  // Helper method to get the filter name
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
}
