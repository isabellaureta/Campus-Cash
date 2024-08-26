import 'package:flutter/material.dart';

class SafeToSpendPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Safe-to-Spend Budgeting'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Safe-to-Spend Budgeting',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Set aside essentials and goals, spend the rest freely.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'How It Works:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '1. Enter your monthly income.\n'
                  '2. Subtract your essential expenses.\n'
                  '3. Allocate money towards your savings and goals.\n'
                  '4. The remaining amount is your safe-to-spend balance.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SafeToSpendFormPage()),
                  );
                },
                child: Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SafeToSpendFormPage extends StatefulWidget {
  @override
  _SafeToSpendFormPageState createState() => _SafeToSpendFormPageState();
}

class _SafeToSpendFormPageState extends State<SafeToSpendFormPage> {
  final TextEditingController _incomeController = TextEditingController();
  final TextEditingController _expensesController = TextEditingController();
  final TextEditingController _savingsController = TextEditingController();

  double _safeToSpend = 0.0;

  void _calculateSafeToSpend() {
    final income = double.tryParse(_incomeController.text) ?? 0.0;
    final expenses = double.tryParse(_expensesController.text) ?? 0.0;
    final savings = double.tryParse(_savingsController.text) ?? 0.0;

    setState(() {
      _safeToSpend = income - (expenses + savings);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Safe-to-Spend Calculation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter Your Financial Details',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _incomeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Monthly Income',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _calculateSafeToSpend(),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _expensesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Essential Expenses',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _calculateSafeToSpend(),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _savingsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Savings/Goals',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _calculateSafeToSpend(),
            ),
            SizedBox(height: 32),
            Text(
              'Safe-to-Spend Amount:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.greenAccent,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                '\$${_safeToSpend.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to the next page or perform another action
                },
                child: Text('Track Spending'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
