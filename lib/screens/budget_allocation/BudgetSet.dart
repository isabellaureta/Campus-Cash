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
  String _selectedPeriod = 'daily';
  bool _autoRegenerateIncome = false;
  bool _carryOverExcessIncome = false;

  Future<void> _saveBudget() async {
    User? user = _auth.currentUser;
    if (user != null) {
      double budget = double.parse(_budgetController.text);

      DateTime nextRegeneration = DateTime.now();
      if (_autoRegenerateIncome) {
        switch (_selectedPeriod) {
          case 'daily':
            nextRegeneration = nextRegeneration.add(const Duration(days: 1));
            break;
          case 'weekly':
            nextRegeneration = nextRegeneration.add(const Duration(days: 7));
            break;
          case 'monthly':
            nextRegeneration = DateTime(
              nextRegeneration.year,
              nextRegeneration.month + 1,
              nextRegeneration.day,
            );
            break;
        }
      }

      await FirebaseFirestore.instance.collection('budgets').doc(user.uid).set({
        'budget': budget,
        'remaining': budget,
        'period': _selectedPeriod,
        'autoRegenerateIncome': _autoRegenerateIncome,
        'carryOverExcessIncome': _carryOverExcessIncome,
        'nextRegeneration': nextRegeneration,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
    }
  }


  Future<void> _scheduleBudgetRegeneration(String userId, double budget, String period) async {
    DateTime nextTimestamp;

    // Determine the next timestamp based on frequency
    switch (period) {
      case 'daily':
        nextTimestamp = DateTime.now().add(const Duration(days: 1));
        break;
      case 'weekly':
        nextTimestamp = DateTime.now().add(const Duration(days: 7));
        break;
      case 'monthly':
        nextTimestamp = DateTime.now().add(const Duration(days: 30)); // Simplified logic for demo
        break;
      default:
        return; // Invalid period, do nothing
    }

    // Save the next regeneration timestamp
    await FirebaseFirestore.instance.collection('budgetSchedules').doc(userId).set({
      'nextRegeneration': nextTimestamp,
      'budget': budget,
      'period': period,
      'autoRegenerateIncome': true,
    });
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
              items: <String>['daily', 'weekly', 'monthly'] // Ensure lowercase matches _selectedPeriod
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value[0].toUpperCase() + value.substring(1)), // Capitalize for display
                );
              }).toList(),
            ),

            SizedBox(height: 20),
            CheckboxListTile(
              title: Text("Automatically regenerate income after each selected period"),
              value: _autoRegenerateIncome,
              onChanged: (bool? value) {
                setState(() {
                  _autoRegenerateIncome = value!;
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
                  : null,
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
