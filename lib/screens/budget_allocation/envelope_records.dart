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
  bool isSaving = false; // To track the saving state

  // Function to delete the user's envelope budgeting data from Firestore
  Future<void> _deleteEnvelopeData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Reference to the user's document in Firestore under 'envelopeAllocations'
      DocumentReference userDocRef = FirebaseFirestore.instance.collection('envelopeAllocations').doc(user.uid);

      // Delete the 'envelopes' subcollection under the user's document
      final envelopeCollection = await userDocRef.collection('envelopes').get();
      for (var doc in envelopeCollection.docs) {
        await doc.reference.delete();
      }

      // Delete the main document in 'envelopeAllocations' for this user (optional)
      await userDocRef.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Envelope budgeting data deleted successfully')),
      );

      // Optionally, navigate the user back or to a different page after deletion
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete data: $e')),
      );
    }
  }

  // Show a confirmation dialog before deleting
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
      await _deleteEnvelopeData(); // Proceed with deletion if confirmed
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Envelope> envelopes = filteredCategories.map((category) {
      String allocatedAmount = widget.allocations[category.name]?.toString() ?? '0.0';
      return Envelope(category: category, allocatedBudget: allocatedAmount);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Envelope Budgeting'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings), // Settings icon
            onPressed: _confirmDelete, // Show delete confirmation dialog
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Number of columns
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 1, // Adjusted childAspectRatio to make cards larger
          ),
          itemCount: envelopes.length,
          itemBuilder: (context, index) {
            final envelope = envelopes[index];
            return Card(
              color: Color(envelope.category.color),
              child: Padding(
                padding: const EdgeInsets.all(12.0), // Increased padding inside the Card
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
    );
  }
}
