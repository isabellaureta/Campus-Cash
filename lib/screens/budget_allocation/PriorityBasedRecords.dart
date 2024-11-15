import 'package:campuscash/screens/budget_allocation/Budget.dart';
import 'package:campuscash/screens/budget_allocation/BudgetSelectionPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:expense_repository/repositories.dart';

class PriorityBasedRecords extends StatefulWidget {
  final List<Category> selectedCategories;

  PriorityBasedRecords({required this.selectedCategories});

  @override
  _PriorityBasedRecordsState createState() => _PriorityBasedRecordsState();
}

class _PriorityBasedRecordsState extends State<PriorityBasedRecords> {
  final TextEditingController _incomeController = TextEditingController();
  String _incomeType = 'Monthly';
  double totalIncome = 0.0;
  double totalAllocated = 0.0;
  Map<Category, TextEditingController> categoryAmountControllers = {};

  @override
  void initState() {
    super.initState();
    for (var category in widget.selectedCategories) {
      categoryAmountControllers[category] = TextEditingController()
        ..addListener(_calculateTotalAllocation);
    }
  }

  void _calculateTotalAllocation() {
    double allocatedSum = 0.0;
    for (var controller in categoryAmountControllers.values) {
      final value = double.tryParse(controller.text) ?? 0.0;
      allocatedSum += value;
    }

    setState(() {
      totalAllocated = allocatedSum;
    });
  }

  Future<void> _saveAllocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in.')),
      );
      return;
    }

    final allocationData = widget.selectedCategories.map((category) {
      return {
        'categoryName': category.name,
        'categoryId': category.categoryId,
        'allocatedAmount': double.tryParse(categoryAmountControllers[category]?.text ?? '0') ?? 0.0,
        'categoryIcon': category.icon,
      };
    }).toList();

    final collectionRef = FirebaseFirestore.instance.collection('PriorityBased').doc(user.uid);

    await collectionRef.set({
      'allocations': allocationData,
      'totalIncome': totalIncome,
      'frequency': _incomeType,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Allocation saved successfully!')),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PriorityBasedSummary(userId: user.uid)),
    );
  }

  @override
  void dispose() {
    for (var controller in categoryAmountControllers.values) {
      controller.dispose();
    }
    _incomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAllocationValid = totalAllocated <= totalIncome;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Allocate Funds'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Your Income',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _incomeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter your income',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  totalIncome = double.tryParse(value) ?? 0.0;
                  _calculateTotalAllocation();
                });
              },
            ),
            const SizedBox(height: 16),

            // Total Allocation Display
            Text(
              'Total Allocation: \$${totalAllocated.toStringAsFixed(2)} / \$${totalIncome.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isAllocationValid ? Colors.black : Colors.red,
              ),
            ),
            const SizedBox(height: 8),

// Progress Bar
            LinearProgressIndicator(
              value: totalIncome > 0 ? totalAllocated / totalIncome : 0.0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isAllocationValid ? Colors.blueAccent : Colors.redAccent,
              ),
            ),
            const SizedBox(height: 8),

// Exceeding Income Message
            if (!isAllocationValid)
              const Text(
                'Warning: Total allocation exceeds your income!',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 16),

            // Category Allocation Input Fields
            Expanded(
              child: ListView.builder(
                itemCount: widget.selectedCategories.length,
                itemBuilder: (context, index) {
                  final category = widget.selectedCategories[index];
                  final controller = categoryAmountControllers[category]!;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: Image.asset(
                        category.icon,
                        width: 40,
                        height: 40,
                      ),
                      title: Text(
                        category.name,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Save Allocation Button (disabled if allocation exceeds income)
            ElevatedButton(
              onPressed: isAllocationValid ? _saveAllocation : null,
              child: const Text('Save Allocation'),
            ),
          ],
        ),
      ),
    );
  }
}

class PriorityBasedSummary extends StatelessWidget {
  final String userId;

  PriorityBasedSummary({required this.userId});

  Future<Map<String, dynamic>?> _fetchAllocationData() async {
    final doc = await FirebaseFirestore.instance.collection('PriorityBased').doc(userId).get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> _deleteAllocation(BuildContext context) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Allocation"),
          content: const Text("Are you sure you want to delete this allocation? This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // User pressed "No"
              child: const Text("No"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true), // User pressed "Yes"
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );

    if (confirmation == true) {
      await FirebaseFirestore.instance.collection('PriorityBased').doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Allocation deleted successfully.')),
      );

      // Navigate to AddBudget after deletion
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => BudgetSelectionPage()),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Priority-Based Allocation Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchAllocationData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No allocation data available.'));
          }

          final data = snapshot.data!;
          final totalIncome = data['totalIncome'];
          final allocations = List<Map<String, dynamic>>.from(data['allocations'] ?? []);

          // Sort allocations by priority, handling null values
          allocations.sort((a, b) {
            final priorityA = a['priority'] ?? double.infinity; // Assign a default high priority if null
            final priorityB = b['priority'] ?? double.infinity;
            return priorityB.compareTo(priorityA); // Higher priority comes first
          });

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: Colors.blue.shade50,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: ListTile(
                    title: Text(
                      'Income: \$${totalIncome.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),

                    leading: const Icon(Icons.account_balance_wallet, color: Colors.blue),
                  ),
                ),
                const Text(
                  'Category Allocations by Priority:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: allocations.length,
                    itemBuilder: (context, index) {
                      final allocation = allocations[index];
                      final priorityLevel = index + 1;
                      final priorityColor = Color.lerp(Colors.red, Colors.green, index / allocations.length);

                      return Card(
                        color: priorityColor!.withOpacity(0.8),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 4,
                        child: ListTile(
                          leading: allocation['categoryIcon'] != null
                              ? Image.asset(
                            allocation['categoryIcon'],
                            width: 40,
                            height: 40,
                          )
                              : const Icon(Icons.category, size: 40),
                          title: Text(
                            allocation['categoryName'],
                            style: TextStyle(
                              fontSize: 16 + (allocations.length - priorityLevel).toDouble(),
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            'Allocated: \$${allocation['allocatedAmount'].toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          trailing: Icon(
                            priorityLevel == 1
                                ? Icons.star
                                : Icons.arrow_downward,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Allocation', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(context).pop(); // Close the bottom sheet
                  _deleteAllocation(context); // Confirm deletion
                },
              ),
            ],
          ),
        );
      },
    );
  }
}