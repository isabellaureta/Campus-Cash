import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoalDetailPage extends StatefulWidget {
  final DocumentSnapshot goal;

  GoalDetailPage({required this.goal});

  @override
  _GoalDetailPageState createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends State<GoalDetailPage> {
  String selectedFrequency = 'Daily'; // Default frequency
  List<String> _frequencies = ['Daily', 'Weekly', 'Monthly'];
  late Map<String, dynamic> goalData;
  late double progress;
  double requiredSavings = 0.0;
  DateTime? selectedEndDate; // Track selected end date for editing
  final TextEditingController _goalNameController = TextEditingController();
  final TextEditingController _goalAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    goalData = widget.goal.data() as Map<String, dynamic>;
    progress = goalData['goalAmount'] > 0
        ? goalData['savedAmount'] / goalData['goalAmount']
        : 0;

    _goalNameController.text = goalData['goalName'] ?? '';
    _goalAmountController.text = goalData['goalAmount']?.toString() ?? '0.0';
    selectedEndDate = (goalData['endDate'] as Timestamp?)?.toDate();

    _calculateRequiredSavings();
  }

  void _calculateRequiredSavings() {
    // Check if the end date is not set or if the goal amount is invalid
    if (selectedEndDate == null || (double.tryParse(_goalAmountController.text) ?? 0.0) <= 0) return;

    final duration = selectedEndDate!.difference(DateTime.now());
    double remainingAmount = (double.tryParse(_goalAmountController.text) ?? 0.0) - goalData['savedAmount'];
    int periods;

    switch (goalData['frequency']) {
      case 'Daily':
        periods = duration.inDays;
        break;
      case 'Weekly':
        periods = (duration.inDays / 7).ceil();
        break;
      case 'Monthly':
        periods = (duration.inDays / 30).ceil();
        break;
      default:
        periods = 0;
    }

    setState(() {
      requiredSavings = periods > 0 ? remainingAmount / periods : 0;
    });
  }


  void _showEditGoalDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Goal'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _goalNameController,
                    decoration: InputDecoration(labelText: 'Goal Name'),
                  ),
                  TextField(
                    controller: _goalAmountController,
                    decoration: InputDecoration(labelText: 'Goal Amount'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() => _calculateRequiredSavings());
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedFrequency,
                    items: _frequencies.map((frequency) {
                      return DropdownMenuItem(
                        value: frequency,
                        child: Text(frequency),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedFrequency = value!;
                        _calculateRequiredSavings(); // Recalculate savings when frequency changes
                      });
                    },
                    decoration: InputDecoration(labelText: 'Frequency'),
                  ),
                  GestureDetector(
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          selectedEndDate = pickedDate;
                          _calculateRequiredSavings(); // Recalculate savings when end date changes
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(width: 1, color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'End Date: ${selectedEndDate != null ? DateFormat.yMd().format(selectedEndDate!) : 'Select a date'}',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  if (requiredSavings > 0) // Only show if there's a required savings amount
                    Text(
                      'Required Savings: ₱${requiredSavings.toStringAsFixed(2)} ${selectedFrequency.toLowerCase()}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
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
                    await _updateGoal(
                      _goalNameController.text,
                      double.tryParse(_goalAmountController.text) ?? 0.0,
                      selectedFrequency,
                      selectedEndDate,
                    );
                  },
                  child: Text('Update'),
                )

              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateGoal(String goalName, double goalAmount, String frequency, DateTime? endDate) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentReference goalDoc = FirebaseFirestore.instance
        .collection('goals')
        .doc(user.uid)
        .collection('userGoals')
        .doc(widget.goal.id);

    await goalDoc.update({
      'goalName': goalName,
      'goalAmount': goalAmount,
      'frequency': frequency,
      'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
    });

    setState(() {
      goalData['goalName'] = goalName;
      goalData['goalAmount'] = goalAmount;
      goalData['frequency'] = frequency;
      goalData['endDate'] = endDate != null ? Timestamp.fromDate(endDate) : null;

      progress = goalAmount > 0 ? goalData['savedAmount'] / goalAmount : 0;
      _calculateRequiredSavings();
    });
  }


  Future<void> _addGoalSavings(double amount, DateTime date) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Update saved amount in Firestore
    await FirebaseFirestore.instance
        .collection('goals')
        .doc(user.uid)
        .collection('userGoals')
        .doc(widget.goal.id)
        .update({
      'savedAmount': FieldValue.increment(amount),
    });

    // Add new entry to history
    await FirebaseFirestore.instance
        .collection('goals')
        .doc(user.uid)
        .collection('userGoals')
        .doc(widget.goal.id)
        .collection('history')
        .add({
      'amount': amount,
      'date': date,
    });

    // Update local state to reflect new saved amount
    setState(() {
      goalData['savedAmount'] += amount;
      progress = goalData['goalAmount'] > 0
          ? goalData['savedAmount'] / goalData['goalAmount']
          : 0;

      // Recalculate required savings after adding new savings
      _calculateRequiredSavings();
    });
  }

  void _showAddSavingsDialog() {
    double amount = 0.0;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Goal Savings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Amount'),
                onChanged: (value) {
                  amount = double.tryParse(value) ?? 0.0;
                },
              ),
              SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = pickedDate;
                    });
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(width: 1, color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Date: ${DateFormat.yMd().format(selectedDate)}',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _addGoalSavings(amount, selectedDate);
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('goals')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('userGoals')
          .doc(widget.goal.id)
          .collection('history')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        final historyDocs = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: historyDocs.length,
          itemBuilder: (context, index) {
            var data = historyDocs[index].data() as Map<String, dynamic>;
            double amount = data['amount']?.toDouble() ?? 0.0;

            return GestureDetector(
              onLongPress: () {
                // Prompt user for deletion
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Delete History'),
                      content: Text('Are you sure you want to delete this history entry?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            await _deleteHistoryEntry(historyDocs[index].id, amount);
                            Navigator.of(context).pop();
                          },
                          child: Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    );
                  },
                );
              },
              child: ListTile(
                title: Text('₱${amount.toStringAsFixed(2)}'),
                subtitle: Text(DateFormat.yMd().format((data['date'] as Timestamp).toDate())),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteHistoryEntry(String historyId, double amount) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Reference to the specific goal document
    DocumentReference goalDoc = FirebaseFirestore.instance
        .collection('goals')
        .doc(user.uid)
        .collection('userGoals')
        .doc(widget.goal.id);

    // Update Firestore: Delete history entry and decrement saved amount
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot goalSnapshot = await transaction.get(goalDoc);

      if (goalSnapshot.exists) {
        double currentSavedAmount = goalSnapshot['savedAmount'] ?? 0.0;
        double updatedSavedAmount = currentSavedAmount - amount;

        // Update the goal's savedAmount after deleting the history entry
        transaction.update(goalDoc, {
          'savedAmount': updatedSavedAmount,
        });

        // Remove the history entry
        transaction.delete(goalDoc.collection('history').doc(historyId));
      }
    });

    // Update the local state
    setState(() {
      goalData['savedAmount'] -= amount;
      progress = goalData['goalAmount'] > 0
          ? goalData['savedAmount'] / goalData['goalAmount']
          : 0;
      _calculateRequiredSavings(); // Recalculate required savings
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(goalData['goalName'] ?? 'Goal Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: _showEditGoalDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Goal Details',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyLarge,
                          children: [
                            TextSpan(
                              text: 'Goal: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: '₱${goalData['goalAmount']?.toStringAsFixed(2) ?? '0.00'}',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyLarge,
                          children: [
                            TextSpan(
                              text: 'Saved: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: '₱${goalData['savedAmount']?.toStringAsFixed(2) ?? '0.00'}',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Frequency: ${goalData['frequency'] ?? 'N/A'}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'End Date: ${goalData['endDate'] != null ? DateFormat.yMd().format((goalData['endDate'] as Timestamp).toDate()) : 'No end date'}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Required Savings: ₱${requiredSavings.toStringAsFixed(2)} ${goalData['frequency']}',
                        style: TextStyle(fontSize: 16, color: Colors.green),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 12,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(progress * 100).toStringAsFixed(2)}% Completed',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Goal Savings History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink.shade300,
                ),
              ),
              const Divider(height: 20, thickness: 1.5),
              _buildHistoryList(),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.center,
                child: ElevatedButton.icon(
                  onPressed: _showAddSavingsDialog,
                  icon: Icon(Icons.add),
                  label: Text('Add Savings'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
