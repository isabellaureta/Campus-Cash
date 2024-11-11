import 'package:campuscash/screens/budget_allocation/BudgetSelectionPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  Set<String> _alertedCategories = {}; // Track categories that have already triggered an alert


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // TabController for Needs, Wants, Savings
    Set<String> _alertedCategories = {}; // Track categories that have already triggered an alert
  }

  // Fetch budget data from Firestore
  Future<Map<String, dynamic>> _fetchBudgetData() async {
    final firestore = FirebaseFirestore.instance;
    final userDocRef = firestore.collection('503020').doc(widget.userId);

    // Fetch main budget info
    final budgetSnapshot = await userDocRef.get();
    final budgetData = budgetSnapshot.data() ?? {};

    // Calculate remaining budget as totalBudget - totalExpenses
    final totalBudget = budgetData['totalBudget'] ?? 0.0;
    final totalExpenses = budgetData['totalExpenses'] ?? 0.0;
    final calculatedRemainingBudget = totalBudget - totalExpenses;

    // Update Firestore with the correct remaining budget if it’s different
    if (budgetData['remainingBudget'] != calculatedRemainingBudget) {
      await userDocRef.update({'remainingBudget': calculatedRemainingBudget});
    }

    // Fetch Needs, Wants, and Savings categories
    final needsSnapshot = await userDocRef.collection('Needs').get();
    final wantsSnapshot = await userDocRef.collection('Wants').get();
    final savingsSnapshot = await userDocRef.collection('Savings').get();

    final needsCategories = needsSnapshot.docs.map((doc) => doc.data()).toList();
    final wantsCategories = wantsSnapshot.docs.map((doc) => doc.data()).toList();
    final savingsCategories = savingsSnapshot.docs.map((doc) => doc.data()).toList();

    // Calculate total deductions for each category type
    final totalNeedsDeductions = await _fetchTotalDeductions(userDocRef, 'Needs');
    final totalWantsDeductions = await _fetchTotalDeductions(userDocRef, 'Wants');
    final totalSavingsDeductions = await _fetchTotalDeductions(userDocRef, 'Savings');

    final totalBudgetToSpend = needsCategories.fold<double>(0.0, (sum, category) => sum + (category['amount'] ?? 0.0)) +
        wantsCategories.fold<double>(0.0, (sum, category) => sum + (category['amount'] ?? 0.0));

    await userDocRef.set({
      'userId': widget.userId,
      'totalBudget': totalBudget,
      'totalExpenses': totalExpenses,
      'remainingBudget': calculatedRemainingBudget,
      'totalBudgetToSpend': totalBudgetToSpend, // Save totalBudgetToSpend to Firestore
    }, SetOptions(merge: true));  // Use merge to avoid overwriting other fields

    _checkCategoryLimits(needsCategories, 'Needs');
    _checkCategoryLimits(wantsCategories, 'Wants');
    _checkCategoryLimits(savingsCategories, 'Savings');

    return {
      'budgetData': budgetData,
      'needsCategories': needsCategories,
      'wantsCategories': wantsCategories,
      'savingsCategories': savingsCategories,
      'totalDeductions': totalNeedsDeductions + totalWantsDeductions + totalSavingsDeductions,
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

      // If remaining is within 20% of budget and hasn't already been alerted, show alert
      if (remainingAmount <= 0.2 * categoryBudget && !_alertedCategories.contains(category['name'])) {
        _alertedCategories.add(category['name']); // Mark as alerted
        _showLimitAlert(category['name'], categoryType); // Trigger the alert dialog
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


  Widget _buildCategoryList(List<dynamic> categories) {
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
        final originalAmount = category['originalAmount'] ?? 0.0;  // Fetch originalAmount if it exists

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
            style: TextStyle(fontSize: 10.0), // Set font size here
          )
              : null,
          trailing: Text(
            '₱${amount.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 16.0), // Optional: set font size for amount as well
          ),
        );

      },
    );
  }


  // Build the TabBar view for Needs, Wants, and Savings
  Widget _buildTabContent(String tabName, List<dynamic> categories) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$tabName Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.0),
          Expanded(child: _buildCategoryList(categories)),
        ],
      ),
    );
  }

  // Function to delete the budget from Firestore
  Future<void> _deleteBudget() async {
    final firestore = FirebaseFirestore.instance;
    final userDocRef = firestore.collection('503020').doc(widget.userId);

    try {
      // Delete subcollections (Needs, Wants, Savings)
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

      // Delete the main budget document
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

  // Show confirmation dialog before deleting the budget
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Budget'),
          content: Text('Are you sure you want to delete your 50/30/20 budget? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close dialog
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _deleteBudget(); // Proceed with deletion
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

          final totalBudget = budgetData['totalBudget'] ?? 0.0;
          final totalExpenses = budgetData['totalExpenses'] ?? 0.0;
          final remainingBudget = budgetData['remainingBudget'] ?? 0.0;

          // Calculate the total amount of the "Needs" and "Wants" categories
          final totalBudgetToSpend = needsCategories.fold<double>(0.0, (double sum, Map<String, dynamic> category) => sum + (category['amount'] ?? 0.0))
              + wantsCategories.fold<double>(0.0, (double sum, Map<String, dynamic> category) => sum + (category['amount'] ?? 0.0));


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
                    // New "Total Budget to Spend" calculation
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
                    // Calculate Remaining Budget as Total Budget to Spend - Total Expenses
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
                    _buildTabContent('Needs', needsCategories),
                    _buildTabContent('Wants', wantsCategories),
                    _buildTabContent('Savings', savingsCategories),
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
