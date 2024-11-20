import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'BudgetSelectionPage.dart';

class PayYourselfFirstRecords extends StatefulWidget {
  @override
  _PayYourselfFirstRecordsState createState() => _PayYourselfFirstRecordsState();
}

class _PayYourselfFirstRecordsState extends State<PayYourselfFirstRecords> {
  late Future<Map<String, dynamic>?> _record;

  @override
  void initState() {
    super.initState();
    _record = _fetchRecord();
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

      Map<String, dynamic> allocations = recordData['allocations'] ?? {};
      double excessMoney = recordData['excessMoney'] ?? 0.0;

      double totalExpenses = 0.0;
      allocations.forEach((categoryName, allocationDetails) {
        double allocatedAmount = (allocationDetails['allocatedAmount'] ?? 0.0).toDouble();
        double remainingAmount = (allocationDetails['amount'] ?? 0.0).toDouble();
        totalExpenses += (allocatedAmount - remainingAmount).abs();
      });

      double remainingIncome = excessMoney - totalExpenses;

      await FirebaseFirestore.instance
          .collection('PayYourselfFirst')
          .doc(user.uid)
          .update({
        'yourselfExpenses': totalExpenses,
        'remainingYourself': remainingIncome,
      });
      recordData['yourselfExpenses'] = totalExpenses;
      recordData['remainingYourself'] = remainingIncome;
      return recordData;
    }
    return null;
  }

  Future<void> _editAllocationAmount(
      String categoryName,
      Map<String, dynamic> details,
      String documentId,
      double excessMoney,
      Map<String, dynamic> allocations,
      ) async {
    final allocatedController = TextEditingController(text: details['allocatedAmount'].toString());
    final amountController = TextEditingController(text: details['amount'].toString());
    double _calculateTotalAllocatedAmount(
        Map<String, dynamic> allocations,
        String excludeCategory,
        double newAllocatedAmount,
        ) {
      double totalAllocated = 0.0;
      allocations.forEach((categoryName, allocationDetails) {
        if (categoryName == excludeCategory) {
          totalAllocated += newAllocatedAmount;
        } else {
          totalAllocated += (allocationDetails['allocatedAmount'] ?? 0.0);
        }
      });
      return totalAllocated;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $categoryName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: allocatedController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Allocated Amount'),
                onChanged: (value) {
                  final newAllocated = double.tryParse(value) ?? 0.0;
                  final totalAllocatedAmount = _calculateTotalAllocatedAmount(
                    allocations,
                    categoryName,
                    newAllocated,
                  );

                  if (totalAllocatedAmount > excessMoney) {
                    allocatedController.text = details['allocatedAmount'].toString();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Total allocated amount cannot exceed excess money of ₱${excessMoney.toStringAsFixed(2)}')),
                    );
                  }
                },
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Remaining Amount'),
                onChanged: (value) {
                  final newAmount = double.tryParse(value) ?? 0.0;
                  final allocatedAmount = double.tryParse(allocatedController.text) ?? details['allocatedAmount'];
                  if (newAmount > allocatedAmount) {
                    amountController.text = details['amount'].toString();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Remaining amount cannot exceed allocated amount of ₱${allocatedAmount.toStringAsFixed(2)}')),
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
            TextButton(
              onPressed: () async {
                final newAllocatedAmount = double.tryParse(allocatedController.text) ?? details['allocatedAmount'];
                final newAmount = double.tryParse(amountController.text) ?? details['amount'];

                if (newAllocatedAmount > excessMoney) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Allocated amount cannot exceed excess money of ₱${excessMoney.toStringAsFixed(2)}')),
                  );
                  return;
                }

                if (newAmount > newAllocatedAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Remaining amount cannot exceed allocated amount of ₱${newAllocatedAmount.toStringAsFixed(2)}')),
                  );
                  return;
                }

                final firestore = FirebaseFirestore.instance;
                final allocationRef = firestore.collection('PayYourselfFirst').doc(documentId);
                await allocationRef.update({
                  'allocations.$categoryName.allocatedAmount': newAllocatedAmount,
                  'allocations.$categoryName.amount': newAmount,
                });
                setState(() {
                  details['allocatedAmount'] = newAllocatedAmount;
                  details['amount'] = newAmount;
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
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
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
        title: Text('Pay Yourself First Record'),
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
            var allocations = record['allocations'] as Map<String, dynamic>;
            var totalIncome = record['totalIncome'] ?? 0.0;
            var excessMoney = record['excessMoney'] ?? 0.0;;

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
                              Text('Remaining Income: ₱${(record['remainingYourself'] ?? 0.0).toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 16)),
                              IconButton(
                                icon: Icon(Icons.settings, color: Colors.red),
                                onPressed: () => _confirmDelete(record['id']),
                              ),
                            ],
                          ),
                          Text('Total Income: ₱${(totalIncome).toStringAsFixed(2)}'),
                          Text('Total Savings: ₱${(record['totalSavings'] ?? 0.0).toStringAsFixed(2)}'),
                          Text('Excess Money: ₱${(record['excessMoney'] ?? 0.0).toStringAsFixed(2)}'),
                          Text('Total Expenses: ₱${(record['yourselfExpenses'] ?? 0.0).toStringAsFixed(2)}'),
                          Divider(),
                          Text('Allocations:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: allocations.length,
                            itemBuilder: (context, index) {
                              var entry = allocations.entries.elementAt(index);
                              var details = entry.value as Map<String, dynamic>;
                              double amount = details['amount'] ?? 0.0;
                              double allocatedAmount = details['allocatedAmount'] ?? 0.0;

                              // Determine the status and color based on the amount
                              String status = '';
                              Color amountColor = Colors.black;
                              Color markColor = Colors.black;
                              bool nearLimit = false;

                              if (amount == 0) {
                                status = 'Completed';
                                amountColor = Colors.green; // Completed is marked in green
                                markColor = Colors.green; // Mark is green
                              } else if (amount < 0) {
                                status = 'Below Zero';
                                amountColor = Colors.red; // Below zero is marked in red
                                markColor = Colors.red; // Mark is red
                              } else if (amount <= (allocatedAmount * 0.2)) {
                                // Check if amount is near 0 (within 20% of the allocated amount)
                                status = 'Near the limit!';
                                amountColor = Colors.orange.shade800; // Mark is orange
                                markColor = Colors.orange.shade800; // Mark is orange
                                nearLimit = true;
                              }

                              return GestureDetector(
                                onTap: () => _editAllocationAmount(entry.key, details, record['id'], excessMoney, allocations),
                                child: Card(
                                  elevation: 5,
                                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Status mark
                                        Container(
                                          width: 100,
                                          height: 4,
                                          color: markColor,
                                        ),
                                        SizedBox(height: 8),

                                        // Category icon and name
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: 40,
                                              height: 40,
                                              child: Image.asset(details['icon'], fit: BoxFit.contain),
                                            ),
                                            SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                details['categoryName'] ?? entry.key,
                                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),

                                        // Amount and allocated text
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '₱${amount.toString()}',
                                              style: TextStyle(fontSize: 15, color: amountColor),
                                            ),
                                            Text(
                                              'Allocated: ₱${allocatedAmount.toString()}',
                                              style: TextStyle(fontSize: 13),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),

                                        // Status text (Near the limit if applicable)
                                        if (nearLimit)
                                        Text(
                                          status,
                                          style: TextStyle(fontSize: 12, color: amountColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
