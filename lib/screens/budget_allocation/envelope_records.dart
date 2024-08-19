import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'addBudgetandAllocation.dart';
import 'envelope_budgeting_page.dart';

class EnvelopeBudgetingPage extends StatefulWidget {
  final Map<String, double> allocations;

  EnvelopeBudgetingPage({required this.allocations});

  @override
  _EnvelopeBudgetingPageState createState() => _EnvelopeBudgetingPageState();
}

class _EnvelopeBudgetingPageState extends State<EnvelopeBudgetingPage> {
  bool isSaving = false; // To track the saving state

  @override
  Widget build(BuildContext context) {
    final List<Envelope> envelopes = filteredCategories.map((category) {
      String allocatedAmount = widget.allocations[category.name]?.toString() ?? '0.0';
      return Envelope(category: category, allocatedBudget: allocatedAmount);
    }).toList();

    // Function to save data to Firestore
    Future<void> saveToFirestore() async {
      setState(() {
        isSaving = true; // Disable the button to prevent multiple presses
      });

      try {
        // Get the current user
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('No user logged in');
        }

        String userId = user.uid;

        // Reference to the user's document in the budgetEnvelopes collection
        DocumentReference userDocRef = FirebaseFirestore.instance.collection('budgetEnvelopes').doc(userId);

        // Save each envelope
        for (var envelope in envelopes) {
          await userDocRef.collection('envelopes').add({
            'categoryName': envelope.category.name,
            'allocatedBudget': envelope.allocatedBudget,
            'remainingBudget': envelope.remainingBudget,
          });
        }

        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data saved successfully!')),
        );

        // Navigate to AddBudget page
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => AddBudget(userId: '',)), // Replace with your AddBudget class
              (route) => false,
        );
      } catch (e) {
        // Show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save data: $e')),
        );
        setState(() {
          isSaving = false; // Re-enable the button if saving fails
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Envelope Budgeting'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: isSaving ? null : saveToFirestore, // Disable button while saving
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
                      'Allocated: \$${double.parse(envelope.allocatedBudget).toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 13),
                    ),
                    Text(
                      'Remaining: \$${double.parse(envelope.remainingBudget).toStringAsFixed(2)}',
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
