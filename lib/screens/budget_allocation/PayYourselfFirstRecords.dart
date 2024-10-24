import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'addBudgetandAllocation.dart';

class PayYourselfFirstRecords extends StatefulWidget {
  @override
  _PayYourselfFirstRecordsState createState() => _PayYourselfFirstRecordsState();
}

class _PayYourselfFirstRecordsState extends State<PayYourselfFirstRecords> {
  late Future<Map<String, dynamic>?> _record;  // Fetch the user's record

  @override
  void initState() {
    super.initState();
    _record = _fetchRecord();  // Fetch the record on initialization
  }

  // Fetch the saved record from Firestore for the current user
  Future<Map<String, dynamic>?> _fetchRecord() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;  // No user logged in

    // Fetch the Pay-Yourself-First record for the current user
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('PayYourselfFirst')
        .doc(user.uid)
        .get();

    if (snapshot.exists) {
      // Include document ID with the returned data
      Map<String, dynamic> recordData = snapshot.data() as Map<String, dynamic>;
      recordData['id'] = snapshot.id; // Store document ID
      return recordData;
    }
    return null;
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

      Navigator.pop(context);  // Navigate back after deletion
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Income Type: ${record['incomeType']}',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDelete(record['id']),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text('Total Income: ₱${record['totalIncome'].toStringAsFixed(2)}'),
                          Text('Total Savings: ₱${record['totalSavings'].toStringAsFixed(2)}'),
                          Text('Excess Money: ₱${record['excessMoney'].toStringAsFixed(2)}'),
                          Text('Frequency: ${record['incomeType']}'),
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
                                leading: SizedBox( // Constrain the size of the leading widget (icon)
                                  width: 40,  // Specify the width
                                  height: 40, // Specify the height
                                  child: Image.asset(details['icon'], fit: BoxFit.contain),
                                ),
                                title: Text(entry.key),
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