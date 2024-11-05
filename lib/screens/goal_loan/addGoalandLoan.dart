import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'addGoals.dart'; // Assuming this file contains your AddGoalPage class

class CustomTabBarsPage extends StatefulWidget {
  const CustomTabBarsPage({super.key});

  @override
  State<CustomTabBarsPage> createState() => _CustomTabBarsPageState();
}

class _CustomTabBarsPageState extends State<CustomTabBarsPage> {
  void _navigateToAddGoalPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddGoalPage()),
    );
  }

  Future<void> _deleteGoal(DocumentSnapshot document) async {
    try {
      await FirebaseFirestore.instance
          .collection('goals')
          .doc(document.id)
          .delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete goal: $e')),
      );
    }
  }

  Widget _buildGoalCard(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;

    // Parse goal progress
    double progress = data['goalAmount'] > 0
        ? data['savedAmount'] / data['goalAmount']
        : 0;

    // Parse startDate and endDate fields from Firestore Timestamps
    DateTime startDate = (data['startDate'] as Timestamp).toDate();
    DateTime? endDate = data['endDate'] != null
        ? (data['endDate'] as Timestamp).toDate()
        : null;

    // Parse the color from Firestore and convert it to a Color object
    Color goalColor = Color(int.parse(data['color'], radix: 16)).withOpacity(1.0);

    return GestureDetector(
      onLongPress: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Delete Goal'),
              content: Text('Are you sure you want to delete this goal?'),
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
                    _deleteGoal(document);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
      child: Card(
        elevation: 4,
        color: goalColor, // Set the card's background color
        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['goalName'] ?? 'Unnamed Goal', // Handle null goal name
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Goal: ₱${data['goalAmount']?.toStringAsFixed(2) ?? '0.00'}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Saved: ₱${data['savedAmount']?.toStringAsFixed(2) ?? '0.00'}',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Start: ${DateFormat.yMMMd().format(startDate)}',
                        style: TextStyle(fontSize: 13),
                      ),
                      Text(
                        'End: ${endDate != null ? DateFormat.yMMMd().format(endDate) : 'Until Forever'}',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              SizedBox(height: 10),
              Text(
                '${(progress * 100).toStringAsFixed(2)}% Completed',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Goals'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _navigateToAddGoalPage,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: 18),
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text('Add Goal'),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('goals').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final goals = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    return _buildGoalCard(goals[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
