import 'package:flutter/material.dart';

class Budget503020Page extends StatefulWidget {
  @override
  _Budget503020PageState createState() => _Budget503020PageState();
}

class _Budget503020PageState extends State<Budget503020Page> {
  final _formKey = GlobalKey<FormState>();
  final _budgetController = TextEditingController();
  double? _needs;
  double? _wants;
  double? _savings;

  void _calculateBudget(double budget) {
    setState(() {
      _needs = budget * 0.5;
      _wants = budget * 0.3;
      _savings = budget * 0.2;
    });
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('50/30/20 Budgeting'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '50/30/20 Budgeting',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  'Allocate 50% to needs, 30% to wants, and 20% to savings.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _budgetController,
                  decoration: InputDecoration(
                    labelText: 'Enter your budget',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your budget';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _calculateBudget(double.parse(_budgetController.text));
                    }
                  },
                  child: Text('Calculate'),
                ),
                SizedBox(height: 16),
                if (_needs != null && _wants != null && _savings != null) ...[
                  Text(
                    'Your Budget Allocation:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Needs (50%): ₱${_needs!.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Wants (30%): ₱${_wants!.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Savings (20%): ₱${_savings!.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Categories for Students:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Needs:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text('Rent, Utilities, Groceries, Transportation, Tuition'),
                  SizedBox(height: 8),
                  Text(
                    'Wants:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text('Dining Out, Entertainment, Hobbies, Shopping'),
                  SizedBox(height: 8),
                  Text(
                    'Savings:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text('Emergency Fund, Investments, Future Goals'),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
