import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'addBudgetandAllocation.dart';

class PayYourselfFirstRecords extends StatefulWidget {
  @override
  _PayYourselfFirstRecordsState createState() => _PayYourselfFirstRecordsState();
}

class _PayYourselfFirstRecordsState extends State<PayYourselfFirstRecords> {
  late Future<List<Map<String, dynamic>>> _records;

  @override
  void initState() {
    super.initState();
    _records = _fetchRecords();
  }

  Future<List<Map<String, dynamic>>> _fetchRecords() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('PayYourselfFirst').get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Explicitly add the document ID
      return data;
    }).toList();
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

      // Navigate back to AddBudget class after successful deletion
      Navigator.push(context, MaterialPageRoute(builder: (context) => AddBudget(userId: '',)));
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
        title: Text('Your Savings Records'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _records,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error fetching records'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No records found'));
          } else {
            List<Map<String, dynamic>> records = snapshot.data!;
            return ListView.builder(
              itemCount: records.length,
              itemBuilder: (context, index) {
                var record = records[index];
                var allocations = record['allocations'] as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Income Type: ${record['incomeType']}', style: TextStyle(fontSize: 18)),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(record['id']),
                            ),
                          ],
                        ),
                        Text('Total Income: \$${record['totalIncome'].toStringAsFixed(2)}'),
                        Text('Total Savings: \$${record['totalSavings'].toStringAsFixed(2)}'),
                        Text('Excess Money: \$${record['excessMoney'].toStringAsFixed(2)}'),
                        Divider(),
                        Text('Allocations:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Column(
                          children: allocations.entries.map((entry) {
                            var details = entry.value as Map<String, dynamic>;
                            return ListTile(
                              leading: Image.asset(details['icon'], width: 24, height: 24),
                              title: Text(entry.key),
                              trailing: Text('\$${details['amount']}'),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
