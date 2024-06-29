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
            // Add input fields for budget details here
          ],
        ),
      ),
    );
  }
}
