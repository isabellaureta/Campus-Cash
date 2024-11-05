import 'package:campuscash/screens/budget_allocation/BudgetSelectionPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'envelope_budgeting_page.dart';

class EnvelopeBudgetingPage extends StatefulWidget {
  final Map<String, double> allocations;

  EnvelopeBudgetingPage({required this.allocations});

  @override
  _EnvelopeBudgetingPageState createState() => _EnvelopeBudgetingPageState();
}

class _EnvelopeBudgetingPageState extends State<EnvelopeBudgetingPage> {
  bool isSaving = false;
  Map<String, double> remainingBudgets = {};
  double _income = 0.0;
  double _envelopeExpenses = 0.0;
  double _remainingEnvelope = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchRemainingBudgets();
  }

  Future<void> _fetchRemainingBudgets() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentReference userDocRef = FirebaseFirestore.instance.collection('envelopeAllocations').doc(user.uid);
      DocumentSnapshot docSnapshot = await userDocRef.get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        setState(() {
          _income = docSnapshot['income'] ?? 0.0;
          _envelopeExpenses = docSnapshot['envelopeExpenses'] ?? 0.0;
          _remainingEnvelope = docSnapshot['remainingEnvelope'] ?? 0.0;
        });
      }

      // Fetch remaining budgets for each category from the "envelopes" subcollection
      final envelopeDocs = await userDocRef.collection('envelopes').get();
      Map<String, double> fetchedBudgets = {};
      for (var doc in envelopeDocs.docs) {
        var data = doc.data();
        fetchedBudgets[data['categoryName']] = data['remainingBudget']?.toDouble() ?? 0.0;
      }

      setState(() {
        remainingBudgets = fetchedBudgets;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch remaining budgets: $e')),
      );
    }
  }

  Future<void> _deleteEnvelopeData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      DocumentReference userDocRef = FirebaseFirestore.instance.collection('envelopeAllocations').doc(user.uid);
      final envelopeCollection = await userDocRef.collection('envelopes').get();
      for (var doc in envelopeCollection.docs) {
        await doc.reference.delete();
      }
      await userDocRef.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Envelope budgeting data deleted successfully')),
      );
      Navigator.push(context, MaterialPageRoute(builder: (context) => BudgetSelectionPage()));

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete data: $e')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Envelope Budgeting'),
        content: Text('Are you sure you want to delete your envelope budgeting data? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Cancel
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // Confirm
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _deleteEnvelopeData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Envelope> envelopes = filteredCategories.map((category) {
      String allocatedAmount = widget.allocations[category.name]?.toString() ?? '0.0';
      String remainingAmount = remainingBudgets[category.name]?.toStringAsFixed(2) ?? allocatedAmount;
      return Envelope(category: category, allocatedBudget: allocatedAmount, remainingBudget: remainingAmount);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Envelope Budgeting'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _confirmDelete,
          ),
        ],
      ),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display income and frequency at the top of the screen
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Income: ₱${_income.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blueAccent),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Remaining Income: ₱${_remainingEnvelope.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blueAccent),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [

                            Text(
                              'Total Expenses: ₱${_envelopeExpenses.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blueAccent),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
      SizedBox(height: 20),
        Expanded(
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 1,
          ),
          itemCount: envelopes.length,
          itemBuilder: (context, index) {
            final envelope = envelopes[index];
            return Card(
              color: Color(envelope.category.color),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      envelope.category.name,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Allocated: \₱${double.parse(envelope.allocatedBudget).toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 13),
                    ),
                    Text(
                      'Remaining: \₱${double.parse(envelope.remainingBudget).toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ])
    )
    );
  }
}