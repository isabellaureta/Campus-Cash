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
  final Set<String> _alertedCategories = {};

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

      // Get allocations and excess money
      Map<String, dynamic> allocations = recordData['allocations'] ?? {};
      double excessMoney = recordData['excessMoney'] ?? 0.0;

      // Calculate total expenses as the sum of the differences between allocatedAmount and amount
      double totalExpenses = 0.0;
      allocations.forEach((categoryName, allocationDetails) {
        double allocatedAmount = (allocationDetails['allocatedAmount'] ?? 0.0).toDouble();
        double remainingAmount = (allocationDetails['amount'] ?? 0.0).toDouble();
        totalExpenses += (allocatedAmount - remainingAmount).abs();
      });

      // Calculate remaining income
      double remainingIncome = excessMoney - totalExpenses;

      // Update these values in Firestore
      await FirebaseFirestore.instance
          .collection('PayYourselfFirst')
          .doc(user.uid)
          .update({
        'yourselfExpenses': totalExpenses,
        'remainingYourself': remainingIncome,
      });

      // Add calculated fields to recordData for local use
      recordData['yourselfExpenses'] = totalExpenses;
      recordData['remainingYourself'] = remainingIncome;

      _checkCategoryLimits(recordData['allocations']);
      return recordData;
    }
    return null;
  }


  void _checkCategoryLimits(Map<String, dynamic> allocations) {
    allocations.forEach((categoryName, allocationDetails) {
      double allocatedAmount = (allocationDetails['allocatedAmount'] ?? 0.0).toDouble();
      double remainingAmount = (allocationDetails['amount'] ?? allocatedAmount).toDouble();

      if (remainingAmount <= 0.2 * allocatedAmount && !_alertedCategories.contains(categoryName)) {
        _alertedCategories.add(categoryName);
        WidgetsBinding.instance.addPostFrameCallback((_) => _showLimitAlert(categoryName));
      }
    });
  }

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

  Future<void> _editAllocationAmount(
      String categoryName,
      Map<String, dynamic> details,
      String documentId,
      double excessMoney, // Updated from totalIncome to excessMoney
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

                  if (totalAllocatedAmount > excessMoney) { // Validate against excessMoney
                    allocatedController.text = details['allocatedAmount'].toString(); // Revert to original
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

                if (newAllocatedAmount > excessMoney) { // Final validation against excessMoney
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
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(Icons.settings, color: Colors.red),
                                onPressed: () => _confirmDelete(record['id']),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text('Total Income: ₱${(totalIncome).toStringAsFixed(2)}'),
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
                                    Text(details['categoryName'] ?? entry.key),
                                    SizedBox(width: 8),
                                  ],
                                ),
                                subtitle: Text(
                                  'Allocated: ₱${details['allocatedAmount'].toString()}',
                                  style: TextStyle(fontSize: 11),
                                ),
                                trailing: Text(
                                  '₱${details['amount'].toString()}',
                                  style: TextStyle(fontSize: 15),
                                ),
                                onTap: () => _editAllocationAmount(entry.key, details, record['id'], excessMoney, allocations),
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
