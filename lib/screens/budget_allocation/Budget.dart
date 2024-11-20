import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'BudgetSet.dart';

class Budget extends StatelessWidget {
  void _navigateToAddBudgetPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SetBudgetPage()),
    );
  }

  Future<void> _deleteBudget(BuildContext context, DocumentSnapshot document) async {
    try {
      await FirebaseFirestore.instance.collection('budgets').doc(document.id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Budget deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete budget: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Budget'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('budgets').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final budgets = snapshot.data!.docs;
          final hasBudgets = budgets.isNotEmpty;

          return Column(
            children: [
              if (!hasBudgets) // Show "Add Budget" button only if no budgets exist
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () => _navigateToAddBudgetPage(context),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      textStyle: TextStyle(fontSize: 18),
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text('Add Budget'),
                  ),
                ),
              Expanded(
                child: budgets.isNotEmpty
                    ? ListView.builder(
                  itemCount: budgets.length,
                  itemBuilder: (context, index) {
                    return _buildBudgetCard(context, budgets[index]);
                  },
                )
                    : Center(child: Text('No budgets available.')),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBudgetCard(BuildContext context, DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    double budget = data['budget'] ?? 0.0;
    double remaining = data['remaining'] ?? 0.0;

    // Calculate remaining budget percentage
    double remainingPercentage = (remaining / budget) * 100;

    // Show warning if remaining is less than or equal to 20%
    if (remainingPercentage <= 20 && remaining > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Warning'),
              content: Text('You are near your budget limit! Only ₱${remaining.toStringAsFixed(2)} left.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      });
    }

    // Show alert if remaining is negative
    if (remaining < 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Budget Exceeded'),
              content: Text('You have exceeded your budget by ₱${remaining.abs().toStringAsFixed(2)}.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      });
    }

    return GestureDetector(
      onLongPress: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Delete Budget'),
              content: Text('Are you sure you want to delete this budget?'),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Delete'),
                  onPressed: () {
                    _deleteBudget(context, document);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
        child: Card(child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 6,
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade100, Colors.pink.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remaining: ₱${remaining.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: remaining < 0 ? Colors.red : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Budget: ₱${budget.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Period: ${data['period']}',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        )
    );
  }
}
