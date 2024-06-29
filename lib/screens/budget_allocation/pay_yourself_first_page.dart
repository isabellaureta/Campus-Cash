import 'package:flutter/material.dart';

class PayYourselfFirstPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pay-Yourself-First Budgeting'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pay-Yourself-First Budgeting',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Prioritize savings and investments before other expenses.',
              style: TextStyle(fontSize: 16),
            ),
            // Add input fields for budget details here
          ],
        ),
      ),
    );
  }
}
