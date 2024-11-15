import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campuscash/screens/budget_allocation/BudgetSelectionPage.dart';

class BudgetSummaryPage extends StatefulWidget {
  final String userId;

  BudgetSummaryPage({
    required this.userId,
    required totalBudget,
    required totalExpenses,
    required remainingBudget,
    required Map expenses,
  });

  @override
  _BudgetSummaryPageState createState() => _BudgetSummaryPageState();
}

class _BudgetSummaryPageState extends State<BudgetSummaryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Set<String> _alertedCategories = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _alertedCategories = {};
  }

  Future<Map<String, dynamic>> _fetchBudgetData() async {
    final firestore = FirebaseFirestore.instance;
    final userDocRef = firestore.collection('503020').doc(widget.userId);

    // Fetch the user's main budget document
    final budgetSnapshot = await userDocRef.get();
    final budgetData = budgetSnapshot.data() ?? {};

    // Retrieve the stored budget values or set defaults
    final totalBudget = budgetData['totalBudget'] ?? 0.0;

    // Calculate Needs and Wants budget as percentages of totalBudget
    final needsBudget = totalBudget * 0.50;
    final wantsBudget = totalBudget * 0.30;
    final savingsBudget = totalBudget * 0.20;

    // Calculate initial totalBudgetToSpend as sum of Needs and Wants
    double totalBudgetToSpend = totalBudget * 0.50 + totalBudget * 0.30;;

    // Calculate the totalExpenses based on the differences between originalAmount and amount
    double computedTotalExpenses = 0.0;

    // Retrieve Needs and Wants categories from Firestore
    final needsSnapshot = await userDocRef.collection('Needs').get();
    final wantsSnapshot = await userDocRef.collection('Wants').get();
    final savingsSnapshot = await userDocRef.collection('Savings').get();

    // List of needs and wants categories
    final needsCategories = needsSnapshot.docs.map((doc) => doc.data()).toList();
    final wantsCategories = wantsSnapshot.docs.map((doc) => doc.data()).toList();
    final savingsCategories = savingsSnapshot.docs.map((doc) => doc.data()).toList();

    // Compute total expenses by summing the differences in Needs and Wants categories
    for (var category in needsCategories) {
      final originalAmount = category['originalAmount'] ?? 0.0;
      final amount = category['amount'] ?? 0.0;
      computedTotalExpenses += (originalAmount - amount).abs();
    }

    for (var category in wantsCategories) {
      final originalAmount = category['originalAmount'] ?? 0.0;
      final amount = category['amount'] ?? 0.0;
      computedTotalExpenses += (originalAmount - amount).abs();
    }

    // Update the `totalExpenses` in Firestore with the computed value
    await userDocRef.update({'totalExpenses': computedTotalExpenses});

    // Calculate remaining budget based on updated totalExpenses
    final calculatedRemainingBudget = totalBudgetToSpend - computedTotalExpenses;

    // Update remaining budget in Firestore if needed
    if (budgetData['remainingBudget'] != calculatedRemainingBudget) {
      await userDocRef.update({'remainingBudget': calculatedRemainingBudget});
    }

    // Fetch total deductions for each category type
    final totalNeedsDeductions = await _fetchTotalDeductions(userDocRef, 'Needs');
    final totalWantsDeductions = await _fetchTotalDeductions(userDocRef, 'Wants');
    final totalSavingsDeductions = await _fetchTotalDeductions(userDocRef, 'Savings');

    // Save updated budget info back to Firestore with merged settings to avoid overwriting
    await userDocRef.set({
      'userId': widget.userId,
      'totalBudget': totalBudget,
      'totalExpenses': computedTotalExpenses,
      'remainingBudget': calculatedRemainingBudget,
      'totalBudgetToSpend': totalBudgetToSpend,
    }, SetOptions(merge: true));

    // Check and alert if any category limit is reached
    _checkCategoryLimits(needsCategories, 'Needs');
    _checkCategoryLimits(wantsCategories, 'Wants');
    _checkCategoryLimits(savingsCategories, 'Savings');

    // Return a structured map with all relevant data for UI
    return {
      'budgetData': budgetData,
      'needsCategories': needsCategories,
      'wantsCategories': wantsCategories,
      'savingsCategories': savingsCategories,
      'totalDeductions': totalNeedsDeductions + totalWantsDeductions + totalSavingsDeductions,
      'needsBudget': needsBudget,
      'wantsBudget': wantsBudget,
      'savingsBudget': savingsBudget,
    };
  }




  Future<double> _fetchTotalDeductions(DocumentReference userDocRef, String categoryType) async {
    final totalDeductionsDoc = await userDocRef.collection('TotalDeductions').doc(categoryType).get();
    return totalDeductionsDoc.exists ? totalDeductionsDoc['totalDeductions'] ?? 0.0 : 0.0;
  }

  void _checkCategoryLimits(List<dynamic> categories, String categoryType) {
    for (var category in categories) {
      final categoryBudget = category['amount'] ?? 0.0;
      final remainingAmount = categoryBudget - (category['deductions'] ?? 0.0);

      if (remainingAmount <= 0.2 * categoryBudget && !_alertedCategories.contains(category['name'])) {
        _alertedCategories.add(category['name']);
        _showLimitAlert(category['name'], categoryType);
      }
    }
  }

  void _showLimitAlert(String categoryName, String categoryType) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Budget Limit Alert'),
          content: Text("You're almost at your limit for $categoryType: $categoryName!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryList(List<dynamic> categories, double budgetAmount, String categoryType) {
    if (categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('No categories available'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final amount = category['amount'] ?? 0.0;
        final originalAmount = category['originalAmount'] ?? 0.0;

        return ListTile(
          leading: Image.asset(
            category['icon'], // Assuming icons are stored with their paths
            width: 24.0,
            height: 24.0,
          ),
          title: Text(category['name']),
          subtitle: originalAmount > 0
              ? Text(
            'Allocated: ₱${originalAmount.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 10.0),
          )
              : null,
          trailing: Text(
            '₱${amount.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 16.0),
          ),
          onTap: categoryType != 'Savings'
              ? () => _editCategoryAmount(category, budgetAmount, categoryType, categories)
              : null, // Make Savings non-editable
        );
      },
    );
  }



  // Dialog for editing category amounts
  Future<void> _editCategoryAmount(Map<String, dynamic> category, double budgetAmount, String categoryType, List<dynamic> categories) async {
    final TextEditingController allocatedController = TextEditingController(text: category['originalAmount'].toString());
    final TextEditingController amountController = TextEditingController(text: category['amount'].toString());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit ${category['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: allocatedController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Allocated Amount'),
                onChanged: (value) {
                  final newAllocated = double.tryParse(value) ?? 0.0;

                  // Calculate total originalAmount including the new value for this category
                  final totalOriginalAmount = _calculateTotalOriginalAmount(categories, category['categoryId'], newAllocated);

                  if (totalOriginalAmount > budgetAmount) {
                    allocatedController.text = category['originalAmount'].toString(); // Revert to original value
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Total allocated amount in $categoryType cannot exceed ₱$budgetAmount')),
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
                  final originalAmount = double.tryParse(allocatedController.text) ?? category['originalAmount'];

                  // Ensure amount does not exceed allocated (originalAmount) value
                  if (newAmount > originalAmount) {
                    amountController.text = category['amount'].toString(); // Revert to previous value
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Amount cannot exceed allocated amount of ₱${originalAmount.toStringAsFixed(2)}')),
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
                final newAllocatedAmount = double.tryParse(allocatedController.text) ?? category['originalAmount'];
                final newAmount = double.tryParse(amountController.text) ?? category['amount'];

                // Ensure the amount still does not exceed the allocated amount before saving
                if (newAmount > newAllocatedAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Amount cannot exceed allocated amount of ₱${newAllocatedAmount.toStringAsFixed(2)}')),
                  );
                  return;
                }

                final firestore = FirebaseFirestore.instance;
                final categoryDocRef = firestore
                    .collection('503020')
                    .doc(widget.userId)
                    .collection(categoryType)
                    .doc(category['categoryId']);

                final docSnapshot = await categoryDocRef.get();
                if (docSnapshot.exists) {
                  await categoryDocRef.update({
                    'originalAmount': newAllocatedAmount,
                    'amount': newAmount,
                  });

                  setState(() {
                    category['originalAmount'] = newAllocatedAmount;
                    category['amount'] = newAmount;
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Category document not found.')),
                  );
                }

                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }



// Helper function to calculate the total originalAmount in the current tab
  double _calculateTotalOriginalAmount(List<dynamic> categories, String excludeCategoryId, double newAmount) {
    return categories.fold<double>(0.0, (sum, category) {
      if (category['categoryId'] == excludeCategoryId) {
        return sum + newAmount;
      }
      return sum + (category['originalAmount'] ?? 0.0);
    });
  }


  Widget _buildTabContent(String tabName, List<dynamic> categories, double budgetAmount) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$tabName Categories: ₱${budgetAmount.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.0),
          Expanded(child: _buildCategoryList(categories, budgetAmount, tabName)),
        ],
      ),
    );
  }

  Future<void> _deleteBudget() async {
    final firestore = FirebaseFirestore.instance;
    final userDocRef = firestore.collection('503020').doc(widget.userId);

    try {
      await userDocRef.collection('Needs').get().then((snapshot) {
        for (DocumentSnapshot ds in snapshot.docs) {
          ds.reference.delete();
        }
      });
      await userDocRef.collection('Wants').get().then((snapshot) {
        for (DocumentSnapshot ds in snapshot.docs) {
          ds.reference.delete();
        }
      });
      await userDocRef.collection('Savings').get().then((snapshot) {
        for (DocumentSnapshot ds in snapshot.docs) {
          ds.reference.delete();
        }
      });

      await userDocRef.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Budget deleted successfully')),
      );

      Navigator.push(context, MaterialPageRoute(builder: (context) => BudgetSelectionPage()));
    } catch (e) {
      print("Error deleting budget: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete budget')),
      );
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Budget'),
          content: Text('Are you sure you want to delete your 50/30/20 budget? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteBudget();
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Budget Summary'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDelete();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete Budget', style: TextStyle(color: Colors.red)),
                ),
              ];
            },
            icon: Icon(Icons.settings),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Needs'),
            Tab(text: 'Wants'),
            Tab(text: 'Savings'),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchBudgetData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading budget data.'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('No budget data found.'));
          }

          final budgetData = snapshot.data!['budgetData'];
          final needsCategories = snapshot.data!['needsCategories'];
          final wantsCategories = snapshot.data!['wantsCategories'];
          final savingsCategories = snapshot.data!['savingsCategories'];
          final needsBudget = snapshot.data!['needsBudget'];
          final wantsBudget = snapshot.data!['wantsBudget'];
          final savingsBudget = snapshot.data!['savingsBudget'];

          final totalBudget = budgetData['totalBudget'] ?? 0.0;
          final totalExpenses = budgetData['totalExpenses'] ?? 0.0;
          final remainingBudget = budgetData['remainingBudget'] ?? 0.0;

          double totalBudgetToSpend = totalBudget * 0.50 + totalBudget * 0.30;;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Budget: ₱${totalBudget.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Total Budget to Spend: ₱${totalBudgetToSpend.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Total Expenses: ₱${totalExpenses.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Remaining Budget: ₱${(totalBudgetToSpend - totalExpenses).toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    SizedBox(height: 16.0),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTabContent('Needs', needsCategories, needsBudget),
                    _buildTabContent('Wants', wantsCategories, wantsBudget),
                    _buildTabContent('Savings', savingsCategories, savingsBudget),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
