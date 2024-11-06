import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'BudgetSelectionPage.dart';


class PayYourselfFirstRecords extends StatefulWidget {
  @override
  _PayYourselfFirstRecordsState createState() => _PayYourselfFirstRecordsState();
}

class _PayYourselfFirstRecordsState extends State<PayYourselfFirstRecords> {
  late Future<Map<String, dynamic>?> _record;  // Fetch the user's record
  final Set<String> _alertedCategories = {}; // Track categories that have shown alerts


  @override
  void initState() {
    super.initState();
    _record = _fetchRecord();  // Fetch the record on initialization
  }

  Future<Map<String, dynamic>?> _fetchRecord() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('PayYourselfFirst')
        .doc(user.uid)
        .get();

    if (snapshot.exists) {
      Map<String, dynamic> recordData = snapshot.data() as Map<String, dynamic>;
      recordData['id'] = snapshot.id;

      _checkCategoryLimits(recordData['allocations']);
      return recordData;
    }
    return null;
  }

  void _checkCategoryLimits(Map<String, dynamic> allocations) {
    allocations.forEach((categoryName, allocationDetails) {
      double allocatedAmount = (allocationDetails['amount'] ?? 0.0).toDouble();
      double remainingAmount = (allocationDetails['remainingBudget'] ?? allocatedAmount).toDouble();

      // If within 20% of allocated budget and hasn't been alerted before, show alert
      if (remainingAmount <= 0.2 * allocatedAmount && !_alertedCategories.contains(categoryName)) {
        _alertedCategories.add(categoryName); // Track alerted category
        WidgetsBinding.instance.addPostFrameCallback((_) => _showLimitAlert(categoryName));
      }
    });
  }


  // Displays an alert dialog for categories near their limit
  void _showLimitAlert(String categoryName) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Budget Limit Alert'),
          content: Text("You're almost at your limit for $categoryName!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    });
  }


  Future<void> _deleteRecordData(String documentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('PayYourselfFirst')
          .doc(documentId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Record deleted successfully')),
      );

      Navigator.push(context, MaterialPageRoute(builder: (context) => BudgetSelectionPage()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete record: $e')),
      );
    }
  }

  Future<void> _confirmDelete(String documentId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Record'),
        content: Text('Are you sure you want to delete this record? This action cannot be undone.'),
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
      await _deleteRecordData(documentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Pay Yourself First Records'),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _record,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error fetching records: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('No records found.'));
          } else {
            var record = snapshot.data!;
            var allocations = record['allocations'] as Map<String, dynamic>;  // Retrieve the allocations map

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                children: [
                  Card(
                    elevation: 4,
                    margin: EdgeInsets.all(8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(Icons.settings, color: Colors.red),
                                onPressed: () => _confirmDelete(record['id']),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text('Total Income: ₱${(record['totalIncome'] ?? 0.0).toStringAsFixed(2)}'),
                          Text('Total Savings: ₱${(record['totalSavings'] ?? 0.0).toStringAsFixed(2)}'),
                          Text('Excess Money: ₱${(record['excessMoney'] ?? 0.0).toStringAsFixed(2)}'),
                          Text('Total Expenses: ₱${(record['yourselfExpenses'] ?? 0.0).toStringAsFixed(2)}'),
                          Text('Remaining Income: ₱${(record['remainingYourself'] ?? 0.0).toStringAsFixed(2)}'),


                          Divider(),
                          Text('Allocations:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: allocations.length,
                            itemBuilder: (context, index) {
                              var entry = allocations.entries.elementAt(index);
                              var details = entry.value as Map<String, dynamic>;

                              return ListTile(
                                leading: SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Image.asset(details['icon'], fit: BoxFit.contain),
                                ),
                                title: Row(
                                  children: [
                                    Text(details['categoryName'] ?? entry.key), // Show categoryName if available
                                    SizedBox(width: 8), // Add spacing between icon and text
                                  ],
                                ),
                                trailing: Text('₱${details['amount'].toString()}'),
                              );
                            },
                          ),

                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}