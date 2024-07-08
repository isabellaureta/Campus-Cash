import 'package:expense_repository/repositories.dart';
import 'package:flutter/material.dart';

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

  List<Category> _getCategories() {
    return [
      Category(icon: 'House', name: 'House', color: 0xFFAED581, categoryId: '017'),
      Category(icon: 'Utilities', name: 'Utilities', color: 0xFF7986CB, categoryId: '018'),
      Category(icon: 'Groceries', name: 'Groceries', color: 0xFF7986CB, categoryId: '023'),
      Category(icon: 'Meals', name: 'Meals', color: 0xFF7986CB, categoryId: '026'),
      Category(icon: 'Snacks', name: 'Snacks/Coffee', color: 0xFF7986CB, categoryId: '027'),
      Category(icon: 'Medical', name: 'Medical', color: 0xFF7986CB, categoryId: '038'),
      Category(icon: 'Insurance', name: 'Insurance', color: 0xFF7986CB, categoryId: '039'),
      Category(icon: 'Tuition Fees', name: 'Tuition Fees', color: 0xFF81C784, categoryId: '012'),
      Category(icon: 'School Supplies', name: 'School Supplies', color: 0xFF64B5F6, categoryId: '013'),
      Category(icon: 'Public Transpo', name: 'Public Transpo', color: 0xFFBA68C8, categoryId: '015'),
      Category(icon: 'Booked Transpo', name: 'Booked Transpo', color: 0xFF4DB6AC, categoryId: '016'),
      Category(icon: 'Savings', name: 'Savings', color: 0xFF7986CB, categoryId: '041'),
    ];
  }

}


class Envelope {
  final Category category;
  double allocatedBudget;
  double remainingBudget;

  Envelope({
    required this.category,
    required this.allocatedBudget,
  }) : remainingBudget = allocatedBudget;
}

