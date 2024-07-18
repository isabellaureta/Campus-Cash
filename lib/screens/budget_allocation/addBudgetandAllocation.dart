import 'package:campuscash/screens/budget_allocation/pay_yourself_first_page.dart';
import 'package:campuscash/screens/budget_allocation/priority_based_budgeting_page.dart';
import 'package:campuscash/screens/budget_allocation/safe_to_spend_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '503020_budgeting_page.dart';
import '503020_records.dart';
import 'addBudget.dart';
import 'envelope_budgeting_page.dart';

class AddBudget extends StatefulWidget {
  @override
  State<AddBudget> createState() => _AddBudgetState();

  final String userId;

  AddBudget({required this.userId});
}

class _AddBudgetState extends State<AddBudget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = const [
    Tab(text: 'Budget'),
    Tab(text: 'Budget Allocation'),
  ];

  User? _currentUser;

  void _fetchCurrentUser() {
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
    _fetchCurrentUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToAddBudgetPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SetBudgetPage()),
    );
  }

  Future<void> _deleteBudget(DocumentSnapshot document) async {
    try {
      await FirebaseFirestore.instance.collection('budget').doc(document.id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Budget deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete budget: $e')),
      );
    }
  }

  Widget _buildBudgetCard(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;

    return GestureDetector(
      onLongPress: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Delete Budget'),
              content: Text('Are you sure you want to delete this budget?'),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Delete'),
                  onPressed: () {
                    _deleteBudget(document);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
      child: Card(
        elevation: 4,
        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Budget: ₱${data['budget'].toStringAsFixed(2)}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                'Remaining: ₱${data['remaining'].toStringAsFixed(2)}',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Period: ${data['period']}',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetAllocation() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select a Budgeting Technique:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          _buildBudgetTechniqueButton(
            '50/30/20 Budgeting',
            'Allocate 50% to needs, 30% to wants, and 20% to savings.',
                () async {
              final userId = _currentUser!.uid;
              final docSnapshot = await FirebaseFirestore.instance.collection('503020').doc(userId).get();

              if (docSnapshot.exists) {
                final data = docSnapshot.data() as Map<String, dynamic>;
                final totalBudget = data['totalBudget'] ?? 0.0;
                final totalExpenses = data['totalExpenses'] ?? 0.0;
                final remainingBudget = totalBudget - totalExpenses;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BudgetSummaryPage(
                      totalBudget: totalBudget,
                      totalExpenses: totalExpenses,
                      remainingBudget: remainingBudget,
                      expenses: {}, // Fetch expenses from Firestore
                      userId: userId,
                    ),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BudgetInputPage(userId: userId),
                  ),
                );
              }
            },
          ),
          _buildBudgetTechniqueButton(
            'Envelope Budgeting',
            'Allocate money into different envelopes for various expenses.',
                () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EnvelopeBudgetingPage()),
              );
            },
          ),
          _buildBudgetTechniqueButton(
            'Pay-Yourself-First',
            'Prioritize savings and investments before other expenses.',
                () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PayYourselfFirstPage()),
              );
            },
          ),
          _buildBudgetTechniqueButton(
            'Priority-Based Budgeting',
            'Allocate funds based on priority expenses.',
                () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PriorityBasedBudgetingPage()),
              );
            },
          ),
          _buildBudgetTechniqueButton(
            'Safe-to-Spend Budgeting',
            'Set aside essentials and goals, spend the rest freely.',
                () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SafeToSpendPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetTechniqueButton(String title, String description, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16),
          textStyle: TextStyle(fontSize: 18),
          minimumSize: Size(double.infinity, 60),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(description, style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Budget'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _navigateToAddBudgetPage,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    textStyle: TextStyle(fontSize: 18),
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Text('Add Budget'),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('budgets').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final budgets = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: budgets.length,
                      itemBuilder: (context, index) {
                        return _buildBudgetCard(budgets[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          _buildBudgetAllocation(),
        ],
      ),
    );
  }
}