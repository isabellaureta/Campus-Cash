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
  Set<String> _alertedCategories = {}; // Tracks categories that have already triggered an alert
  late List<Envelope> envelopes;


  @override
  void initState() {
    super.initState();
    _fetchRemainingBudgets();

// Update envelopes list with fetched remaining budgets
    envelopes = filteredCategories
        .where((category) => widget.allocations[category.name] != null && widget.allocations[category.name]! > 0)
        .map((category) {
      String allocatedAmount = widget.allocations[category.name]!.toString();
      String remainingAmount = remainingBudgets[category.name]?.toStringAsFixed(2) ?? allocatedAmount;
      return Envelope(
        category: category,
        allocatedBudget: allocatedAmount,
        remainingBudget: remainingAmount,
      );
    }).toList();
  }

  Future<void> _fetchRemainingBudgets() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentReference userDocRef = FirebaseFirestore.instance.collection('envelopeAllocations').doc(user.uid);
      DocumentSnapshot docSnapshot = await userDocRef.get();

      Map<String, double> fetchedBudgets = {};

      if (docSnapshot.exists && docSnapshot.data() != null) {
        setState(() {
          _income = docSnapshot['income'] ?? 0.0;
          _envelopeExpenses = docSnapshot['envelopeExpenses'] ?? 0.0;
          _remainingEnvelope = docSnapshot['remainingEnvelope'] ?? 0.0;
        });
      }

      final envelopeDocs = await userDocRef.collection('envelopes').get();
      double totalExpenses = 0.0;

      // Calculate total expenses by summing (allocatedAmount - remainingBudget) for each envelope
      for (var doc in envelopeDocs.docs) {
        var data = doc.data();
        double allocatedAmount = data['allocatedAmount']?.toDouble() ?? 0.0;
        double remainingBudget = data['remainingBudget']?.toDouble() ?? 0.0;
        totalExpenses += (allocatedAmount - remainingBudget).clamp(0, allocatedAmount); // Ensures non-negative expense
        fetchedBudgets[data['categoryName']] = remainingBudget;
      }

      // Calculate remaining income by subtracting total expenses from income
      double remainingEnvelope = _income - totalExpenses;

      // Update Firestore with the computed envelopeExpenses and remainingEnvelope totals
      await userDocRef.set({
        'envelopeExpenses': totalExpenses,
        'remainingEnvelope': remainingEnvelope
      }, SetOptions(merge: true));

      // Update local state with fetched data
      setState(() {
        _envelopeExpenses = totalExpenses;
        _remainingEnvelope = remainingEnvelope;
        remainingBudgets = fetchedBudgets;

        // Update envelopes list with fetched remaining budgets
        envelopes = filteredCategories
            .where((category) => widget.allocations[category.name] != null && widget.allocations[category.name]! > 0)
            .map((category) {
          String allocatedAmount = widget.allocations[category.name]!.toString();
          String remainingAmount = remainingBudgets[category.name]?.toStringAsFixed(2) ?? allocatedAmount;
          return Envelope(
            category: category,
            allocatedBudget: allocatedAmount,
            remainingBudget: remainingAmount,
          );
        }).toList();
      });

      // Check for any category that is near the limit
      _checkBudgetLimits();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch remaining budgets: $e')),
      );
    }
  }



  void _checkBudgetLimits() {
    widget.allocations.forEach((categoryName, allocatedBudget) {
      final remaining = remainingBudgets[categoryName] ?? allocatedBudget;

      // Show alert if remaining budget is within 20% of the allocated budget and hasn't been shown yet
      if (remaining <= 0.2 * allocatedBudget && !_alertedCategories.contains(categoryName)) {
        _alertedCategories.add(categoryName); // Mark this category as alerted
        _showLimitAlert(categoryName);
      }
    });
  }

  void _showLimitAlert(String categoryName) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Budget Limit Alert'),
            content: Text("You're almost at your limit for $categoryName!"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    });
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
            onPressed: () {Navigator.pop(context, true);
            },            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _deleteEnvelopeData();
    }
  }


  void _editEnvelopeAmount(Envelope envelope) async {
    final remainingController = TextEditingController(text: envelope.remainingBudget);
    final allocatedController = TextEditingController(text: envelope.allocatedBudget);

    // Fetch allocatedAmount and income for the envelope from Firestore
    double allocatedAmount = 0.0;
    double income = 0.0;
    try {
      // Get allocatedAmount for this specific envelope
      DocumentSnapshot envelopeDoc = await FirebaseFirestore.instance
          .collection('envelopeAllocations')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('envelopes')
          .doc(envelope.category.categoryId)
          .get();
      allocatedAmount = envelopeDoc['allocatedAmount']?.toDouble() ?? 0.0;

      // Get income for this user
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('envelopeAllocations')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      income = userDoc['income']?.toDouble() ?? 0.0;

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch data: $e')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit ${envelope.category.name} Budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: remainingController,
                decoration: InputDecoration(labelText: 'Remaining Amount'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  double remainingAmount = double.tryParse(value) ?? 0.0;

                  // Validate that remainingAmount does not exceed allocatedAmount
                  if (remainingAmount > allocatedAmount) {
                    remainingController.text = envelope.remainingBudget; // Reset to previous value
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Remaining amount cannot exceed allocated amount')),
                    );
                  }
                },
              ),
              TextField(
                controller: allocatedController,
                decoration: InputDecoration(labelText: 'Allocated Amount'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  double newAllocatedAmount = double.tryParse(value) ?? 0.0;

                  // Validate that newAllocatedAmount does not exceed income
                  if (newAllocatedAmount > income) {
                    allocatedController.text = envelope.allocatedBudget; // Reset to previous value
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Allocated amount cannot exceed total income')),
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                double newRemaining = double.tryParse(remainingController.text) ?? double.parse(envelope.remainingBudget);
                double newAllocated = double.tryParse(allocatedController.text) ?? double.parse(envelope.allocatedBudget);

                // Update Firestore with new amounts
                await FirebaseFirestore.instance
                    .collection('envelopeAllocations')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('envelopes')
                    .doc(envelope.category.categoryId)
                    .update({
                  'remainingBudget': newRemaining,
                  'allocatedAmount': newAllocated,
                });

                // Update the local state
                setState(() {
                  envelope.remainingBudget = newRemaining.toString();
                  envelope.allocatedBudget = newAllocated.toString();
                });

                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
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
                  return GestureDetector(
                    onTap: () => _editEnvelopeAmount(envelope),
                    child: Card(
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
                              'Remaining: ₱${double.parse(envelope.remainingBudget).toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 15),
                            ),
                            Text(
                              'Allocated: ₱${double.parse(envelope.allocatedBudget).toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

}