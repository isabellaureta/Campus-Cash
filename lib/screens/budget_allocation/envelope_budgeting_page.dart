// envelope_budgeting_page.dart
import 'package:expense_repository/repositories.dart';
import 'package:flutter/material.dart';

class Envelope {
  final Category category;
  double allocatedBudget;
  double remainingBudget;

  Envelope({
    required this.category,
    required this.allocatedBudget,
  }) : remainingBudget = allocatedBudget;
}

final List<Envelope> envelopes = predefinedCategories.map((category) {
  // Initialize each envelope with a default budget of 100 for demonstration purposes.
  return Envelope(category: category, allocatedBudget: 100.0);
}).toList();


class EnvelopeBudgetingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Envelope Budgeting')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
            childAspectRatio: 2.0,
          ),
          itemCount: envelopes.length,
          itemBuilder: (context, index) {
            final envelope = envelopes[index];
            return Card(
              color: Color(envelope.category.color),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      envelope.category.name,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Allocated: \$${envelope.allocatedBudget.toStringAsFixed(2)}',
                    ),
                    Text(
                      'Remaining: \$${envelope.remainingBudget.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
