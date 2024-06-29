import 'package:flutter/material.dart';

class EnvelopeBudgetingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Envelope Budgeting'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Envelope Budgeting',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Allocate money into different envelopes for various expenses.',
              style: TextStyle(fontSize: 16),
            ),
            // Add input fields for budget details here
          ],
        ),
      ),
    );
  }
}
