import 'package:campuscash/screens/budget_allocation/BudgetSelectionPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:expense_repository/repositories.dart';
import 'package:intl/intl.dart';

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
        'amount': double.tryParse(categoryAmountControllers[category]?.text ?? '0') ?? 0.0,
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
    final numberFormat = NumberFormat('#,##0.00'); // Define the number formatter

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
            Text(
              'Total Allocation: \₱${totalAllocated.toStringAsFixed(2)} / \₱${totalIncome.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isAllocationValid ? Colors.black : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: totalIncome > 0 ? totalAllocated / totalIncome : 0.0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isAllocationValid ? Colors.blueAccent : Colors.redAccent,
              ),
            ),
            const SizedBox(height: 8),
            if (!isAllocationValid)
              const Text(
                'Warning: Total allocation exceeds your income!',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 16),
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

class PriorityBasedSummary extends StatefulWidget {
  final String userId;

  PriorityBasedSummary({required this.userId});

  @override
  State<PriorityBasedSummary> createState() => _PriorityBasedSummaryState();
}

class _PriorityBasedSummaryState extends State<PriorityBasedSummary> {
  double totalIncome = 0.0;
  double totalExpenses = 0.0;
  double remainingBudget = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateTotalExpenses();
  }

  Future<void> _calculateTotalExpenses() async {
    final doc = await FirebaseFirestore.instance.collection('PriorityBased').doc(widget.userId).get();
    if (doc.exists) {
      final data = doc.data()!;
      final allocations = List<Map<String, dynamic>>.from(data['allocations'] ?? []);
      double calculatedExpenses = allocations.fold(0.0, (sum, category) {
        final allocatedAmount = category['allocatedAmount'] ?? 0.0;
        final amount = category['amount'] ?? 0.0;
        return sum + (allocatedAmount - amount).abs();
      });

      final income = data['totalIncome'] ?? 0.0;
      double calculatedRemaining = income - calculatedExpenses;

      setState(() {
        totalIncome = data['totalIncome'] ?? 0.0;
        totalExpenses = calculatedExpenses;
        remainingBudget = calculatedRemaining;
      });

      await FirebaseFirestore.instance.collection('PriorityBased').doc(widget.userId).update({
        'totalExpenses': calculatedExpenses,
        'remainingBudget': calculatedRemaining,
      });
    }
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
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("No"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
        child: const Text("Yes"),
            ),
          ],
        );
      },
    );

    if (confirmation == true) {
      await FirebaseFirestore.instance.collection('PriorityBased').doc(widget.userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Allocation deleted successfully.')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => BudgetSelectionPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,##0.00');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: FirebaseFirestore.instance.collection('PriorityBased').doc(widget.userId).get().then((doc) => doc.data()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No allocation data available.'));
          }
          final data = snapshot.data!;
          final allocations = List<Map<String, dynamic>>.from(data['allocations'] ?? []);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: Colors.blue.shade50,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Income: \₱${numberFormat.format(totalIncome)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total Expenses: \₱${numberFormat.format(totalExpenses)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Remaining Budget: \₱${numberFormat.format(remainingBudget)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
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
                      final priorityColor = Color.lerp(Colors.red.shade400, Colors.green.shade400, index / allocations.length);

                      return Card(
                        color: priorityColor!.withOpacity(0.8),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 4,
                        child: ListTile(
                          onTap: () => _editCategory(context, allocation, allocations, totalIncome),
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                priorityLevel <= 3 ? Icons.star : null,
                                color: Colors.white,
                              ),
                              if (priorityLevel > 3)
                                Text(
                                  priorityLevel.toString(),
                                  style: const TextStyle(color: Colors.white, fontSize: 16),
                                ),
                              const SizedBox(width: 8),
                              allocation['categoryIcon'] != null
                                  ? Image.asset(
                                allocation['categoryIcon'],
                                width: 30,
                                height: 30,
                              )
                                  : const Icon(Icons.category, size: 40),
                            ],
                          ),
                          title: Text(
                            allocation['categoryName'],
                            style: TextStyle(
                              fontSize: 12 + (allocations.length - priorityLevel).toDouble(),
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            'Allocated: ₱${allocation['allocatedAmount'].toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          trailing: Text(
                            '₱${allocation['amount']?.toStringAsFixed(2) ?? "0.00"}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
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

  void _editCategory(
      BuildContext context,
      Map<String, dynamic> selectedCategory,
      List<Map<String, dynamic>> allCategories,
      double totalIncome,
      ) {
    final allocatedAmountController = TextEditingController(
      text: selectedCategory['allocatedAmount'].toStringAsFixed(2),
    );
    final amountController = TextEditingController(
      text: selectedCategory['amount'].toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit ${selectedCategory['categoryName']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: allocatedAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Allocated Amount',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Parse new values
                final newAllocatedAmount =
                    double.tryParse(allocatedAmountController.text) ?? 0.0;
                final newAmount = double.tryParse(amountController.text) ?? 0.0;

                // Validation: Amount cannot exceed AllocatedAmount
                if (newAmount > newAllocatedAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Amount cannot exceed Allocated Amount.'),
                    ),
                  );
                  return;
                }

                // Validation: Total AllocatedAmount cannot exceed TotalIncome
                final updatedTotalAllocated = allCategories.fold<double>(0.0, (sum, category) {
                  if (category == selectedCategory) {
                    return sum + newAllocatedAmount;
                  }
                  return sum + (category['allocatedAmount'] ?? 0.0);
                });

                if (updatedTotalAllocated > totalIncome) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Total allocation exceeds total income.'),
                    ),
                  );
                  return;
                }
                await FirebaseFirestore.instance
                    .collection('PriorityBased')
                    .doc(widget.userId)
                    .update({
                  'allocations': allCategories.map((category) {
                    if (category['categoryId'] == selectedCategory['categoryId']) {
                      return {
                        ...category,
                        'allocatedAmount': newAllocatedAmount,
                        'amount': newAmount,
                      };
                    }
                    return category;
                  }).toList(),
                });

                Navigator.pop(context);
                setState(() {});
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
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
                  Navigator.of(context).pop();
                  _deleteAllocation(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}