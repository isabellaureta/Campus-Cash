import 'package:flutter/material.dart';

class PriorityBasedBudgetingPage extends StatefulWidget {
  @override
  _PriorityBasedBudgetingPageState createState() => _PriorityBasedBudgetingPageState();
}

class _PriorityBasedBudgetingPageState extends State<PriorityBasedBudgetingPage> {
  final TextEditingController _incomeController = TextEditingController();
  String _incomeType = 'Monthly';

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
                  // Handle income submission logic
                  print('Income: $income, Type: $_incomeType');
                } else {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid income amount')),
                  );
                }
              },
              child: const Text('Submit'),
            ),
            // Add more input fields for budget details here
          ],
        ),
      ),
    );
  }
}
