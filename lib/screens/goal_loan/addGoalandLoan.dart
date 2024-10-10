import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'addGoals.dart';

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

    // Safely handle null values by providing default values
    String goalName = data['goalName'] ?? 'Unnamed Goal';
    int iconCodePoint = data['iconCodePoint'] ?? Icons.help_outline.codePoint; // Default icon in case of null
    String fontFamily = data['iconFontFamily'] ?? 'MaterialIcons'; // Default font family if null
    String color = data['color'] ?? 'ffffff'; // Default white color
    double goalAmount = data['goalAmount']?.toDouble() ?? 0.0; // Default to 0.0
    double savedAmount = data['savedAmount']?.toDouble() ?? 0.0; // Default to 0.0

    // Calculate progress safely
    double progress = goalAmount > 0 ? savedAmount / goalAmount : 0;

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
        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                goalName,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Color(int.parse('0xff$color')), // Convert color from Firestore
                      radius: 24,
                      child: Icon(
                        IconData(
                          iconCodePoint, // Use default icon if null
                          fontFamily: fontFamily, // Use default font family if null
                        ),
                        size: 30,
                        color: Colors.white, // Set the icon color (adjust as needed)
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Goal: ₱${goalAmount.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Saved: ₱${savedAmount.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16),
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
