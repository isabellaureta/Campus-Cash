import 'package:expense_repository/repositories.dart';
import 'package:flutter/material.dart';

class Category {
  final String icon;
  final String name;
  final int color;
  final String categoryId;

  Category({required this.icon, required this.name, required this.color, required this.categoryId});
}


class PriorityBasedBudgetingPage extends StatefulWidget {
  @override
  _PriorityBasedBudgetingPageState createState() => _PriorityBasedBudgetingPageState();
}

class _PriorityBasedBudgetingPageState extends State<PriorityBasedBudgetingPage> {
  final TextEditingController _incomeController = TextEditingController();
  String _incomeType = 'Monthly';
  Map<String, double> _allocatedBudget = {};

  void _allocateBudget(double income) {
    double remainingIncome = income;
    _allocatedBudget.clear();

    List<String> priorityOrder = [
      'Education',
      'Tuition Fees',
      'School Supplies',
      'Public Transpo',
      'House',
      'Utilities',
      'Groceries',
      'Medical',
      'Meals',
      'Subscriptions',
      'Entertainment',
    ];

    for (String category in priorityOrder) {
      if (remainingIncome > 0) {
        // Assign a fixed amount or percentage to each category based on priority
        double allocation = remainingIncome * 0.1; // Example: 10% of remaining income
        _allocatedBudget[category] = allocation;
        remainingIncome -= allocation;
      } else {
        _allocatedBudget[category] = 0;
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Priority-Based Budgeting'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Priority-Based Budgeting',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Allocate funds based on priority expenses.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _incomeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter your income',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: _incomeType,
              onChanged: (String? newValue) {
                setState(() {
                  _incomeType = newValue!;
                });
              },
              items: <String>['Monthly', 'Weekly'].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final income = double.tryParse(_incomeController.text);
                if (income != null) {
                  _allocateBudget(income);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid income amount')),
                  );
                }
              },
              child: const Text('Submit'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _allocatedBudget.length,
                itemBuilder: (context, index) {
                  String category = _allocatedBudget.keys.elementAt(index);
                  double amount = _allocatedBudget[category]!;
                  return ListTile(
                    leading: Image.asset(predefinedCategories.firstWhere((c) => c.name == category).icon),
                    title: Text(category),
                    trailing: Text('\$${amount.toStringAsFixed(2)}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
