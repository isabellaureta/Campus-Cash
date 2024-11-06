import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SetBudgetPage extends StatefulWidget {
  @override
  _SetBudgetPageState createState() => _SetBudgetPageState();
}

class _SetBudgetPageState extends State<SetBudgetPage> {
  final TextEditingController _budgetController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _selectedPeriod = 'daily'; // Default selection
  bool _autoRegenerateIncome = false; // Track if auto-regenerate income is selected
  bool _carryOverExcessIncome = false; // Track if carry-over is selected

  Future<void> _saveBudget() async {
    User? user = _auth.currentUser;
    if (user != null) {
      double budget = double.parse(_budgetController.text);

      await FirebaseFirestore.instance.collection('budgets').doc(user.uid).set({
        'budget': budget,
        'remaining': budget,
        'period': _selectedPeriod,
        'autoRegenerateIncome': _autoRegenerateIncome,
        'carryOverExcessIncome': _carryOverExcessIncome,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Set Budget'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _budgetController,
              decoration: InputDecoration(
                labelText: 'Enter your budget',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            DropdownButton<String>(
              value: _selectedPeriod,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedPeriod = newValue!;
                });
              },
              items: <String>['daily', 'weekly', 'monthly']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            CheckboxListTile(
              title: Text("Automatically regenerate income after each period"),
              value: _autoRegenerateIncome,
              onChanged: (bool? value) {
                setState(() {
                  _autoRegenerateIncome = value!;
                  // Uncheck carry-over if auto-regenerate is turned off
                  if (!_autoRegenerateIncome) _carryOverExcessIncome = false;
                });
              },
            ),
            CheckboxListTile(
              title: Text("Carry over excess income"),
              value: _carryOverExcessIncome,
              onChanged: _autoRegenerateIncome
                  ? (bool? value) {
                setState(() {
                  _carryOverExcessIncome = value!;
                });
              }
                  : null, // Disable if auto-regenerate income is unchecked
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveBudget,
              child: Text('Save Budget'),
            ),
          ],
        ),
      ),
    );
  }
}
