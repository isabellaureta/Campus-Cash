import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetSummaryPage extends StatefulWidget {
  final String userId;

  BudgetSummaryPage({required this.userId, required totalBudget, required totalExpenses, required remainingBudget, required Map expenses});

  @override
  _BudgetSummaryPageState createState() => _BudgetSummaryPageState();
}

class _BudgetSummaryPageState extends State<BudgetSummaryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // TabController for Needs, Wants, Savings
  }

  // Fetch budget data from Firestore
  Future<Map<String, dynamic>> _fetchBudgetData() async {
    final firestore = FirebaseFirestore.instance;
    final userDocRef = firestore.collection('503020').doc(widget.userId);

    // Fetch main budget info
    final budgetSnapshot = await userDocRef.get();
    final budgetData = budgetSnapshot.data() ?? {};

    // Fetch Needs categories
    // Fetch Needs, Wants, and Savings categories
    final needsSnapshot = await userDocRef.collection('Needs').get();
    final needsCategories = needsSnapshot.docs.map((doc) => doc.data()).toList();

    // Fetch Wants categories
    final wantsSnapshot = await userDocRef.collection('Wants').get();
    final wantsCategories = wantsSnapshot.docs.map((doc) => doc.data()).toList();

    // Fetch Savings categories
    final savingsSnapshot = await userDocRef.collection('Savings').get();
    final savingsCategories = savingsSnapshot.docs.map((doc) => doc.data()).toList();

    // Fetch total deductions from Firestore
    double totalDeductions = 0;
    final totalNeedsDeductions = await _fetchTotalDeductions(userDocRef, 'Needs');
    final totalWantsDeductions = await _fetchTotalDeductions(userDocRef, 'Wants');
    final totalSavingsDeductions = await _fetchTotalDeductions(userDocRef, 'Savings');

    totalDeductions = totalNeedsDeductions + totalWantsDeductions + totalSavingsDeductions;

    return {
      'budgetData': budgetData,
      'needsCategories': needsCategories,
      'wantsCategories': wantsCategories,
      'savingsCategories': savingsCategories,
      'totalDeductions': totalDeductions,  // Include total deductions
    };
  }

  Future<double> _fetchTotalDeductions(DocumentReference userDocRef, String categoryType) async {
    final totalDeductionsDoc = await userDocRef.collection('TotalDeductions').doc(categoryType).get();
    return totalDeductionsDoc.exists ? totalDeductionsDoc['totalDeductions'] ?? 0.0 : 0.0;
  }


  // Widget to display the category list
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
        return ListTile(
          leading: Image.asset(
            category['icon'], // Assuming icons are stored with their paths
            width: 24.0,
            height: 24.0,
          ),
          title: Text(category['name']),
          trailing: Text('₱${category['amount'].toStringAsFixed(2)}'),
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

      // Optionally, navigate back or refresh the page
      Navigator.pop(context);

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

  Future<double> _fetchTotalExpenses() async {
    double totalExpenses = 0.0;
    try {
      final expenseSnapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: widget.userId)
          .get();

      for (var doc in expenseSnapshot.docs) {
        totalExpenses += (doc['amount'] as num).toDouble();
      }
    } catch (e) {
      print('Error fetching total expenses: $e');
    }
    return totalExpenses;
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
                _confirmDelete(); // Show confirmation dialog to delete the budget
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
            icon: Icon(Icons.settings), // Settings icon for menu options
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
          final remainingBudget = totalBudget - totalExpenses;  // Update remainingBudget using totalExpenses
          final frequency = budgetData['frequency'] ?? 'N/A';
          final totalDeductions = snapshot.data!['totalDeductions'] ?? 0.0;  // Total expenses made

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
                    Text(
                      'Frequency: $frequency',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8.0),
                    // Display total expenses made
                    Text(
                      'Total Expenses: ₱${totalExpenses.toStringAsFixed(2)}',
                      semanticsLabel: 'Total Expenses Made: ₱${totalDeductions.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8.0),
                    // Display remaining budget
                    Text(
                      'Remaining Budget: ₱${remainingBudget.toStringAsFixed(2)}',
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
                    _buildTabContent('Needs', snapshot.data!['needsCategories']),
                    _buildTabContent('Wants', snapshot.data!['wantsCategories']),
                    _buildTabContent('Savings', snapshot.data!['savingsCategories']),
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

