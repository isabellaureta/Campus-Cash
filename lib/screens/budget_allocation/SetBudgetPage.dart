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

  Future<void> _saveBudget() async {
    User? user = _auth.currentUser;
    if (user != null) {
      double budget = double.parse(_budgetController.text);

      await FirebaseFirestore.instance.collection('budgets').doc(user.uid).set({
        'budget': budget,
        'remaining': budget,
        'period': _selectedPeriod,
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
