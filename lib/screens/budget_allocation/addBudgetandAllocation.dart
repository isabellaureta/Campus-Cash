import 'package:campuscash/screens/budget_allocation/pay_yourself_first_page.dart';
import 'package:campuscash/screens/budget_allocation/priority_based_budgeting_page.dart';
import 'package:expense_repository/repositories.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '503020_budgeting_page.dart';
import '503020_records.dart';
import 'addBudget.dart';
import 'envelope_budgeting_page.dart';

class AddBudget extends StatefulWidget {
  final String userId;

  AddBudget({required this.userId});

  @override
  State<AddBudget> createState() => _AddBudgetState();
}

class _AddBudgetState extends State<AddBudget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = const [
    Tab(text: 'Budget'),
    Tab(text: 'Budget Allocation'),
  ];

  User? _currentUser;
  List<Envelope> savedEnvelopes = [];
  Map<String, dynamic>? savedBudgetSummary;

  void _fetchCurrentUser() {
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
    _fetchCurrentUser();
    _tabController.addListener(_handleTabChange);
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

  void _handleTabChange() {
    if (_tabController.index == 1) {
      _fetchSavedData();
    }
  }

  Future<void> _fetchSavedData() async {
    try {
      if (_currentUser == null) return;

      // Fetch saved envelopes
      final envelopeRef = FirebaseFirestore.instance.collection('budgetEnvelopes').doc(_currentUser!.uid);
      final envelopesSnapshot = await envelopeRef.collection('envelopes').get();

      // Fetch saved budget summary
      final budgetRef = FirebaseFirestore.instance.collection('503020').doc(_currentUser!.uid);
      final budgetSnapshot = await budgetRef.get();

      setState(() {
        savedEnvelopes = envelopesSnapshot.docs.map((doc) {
          final data = doc.data();
          return Envelope(
            category: predefinedCategories.firstWhere((cat) => cat.name == data['categoryName']),
            allocatedBudget: data['allocatedBudget'] ?? '0.0',
          );
        }).toList();

        if (budgetSnapshot.exists) {
          savedBudgetSummary = budgetSnapshot.data();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch saved data: $e')),
      );
    }
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

  Widget _buildBudgetAllocation() {
    if (savedBudgetSummary != null) {
      // Display saved budget summary like in BudgetSummaryPage
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Budget: ₱${savedBudgetSummary!['totalBudget'].toStringAsFixed(2)}'),
                Text('Total Expenses: ₱${savedBudgetSummary!['totalExpenses'].toStringAsFixed(2)}'),
                Text('Remaining Budget: ₱${savedBudgetSummary!['remainingBudget'].toStringAsFixed(2)}'),
              ],
            ),
          ),
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Scaffold(
                appBar: AppBar(
                  bottom: TabBar(
                    tabs: [
                      Tab(text: 'Needs'),
                      Tab(text: 'Wants'),
                      Tab(text: 'Savings'),
                    ],
                  ),
                ),
                body: TabBarView(
                  children: [
                    CategoryListView(
                      type: 'Needs',
                      expenses: savedBudgetSummary!['expenses'] ?? {},
                      categories: getCategories('Needs'),
                    ),
                    CategoryListView(
                      type: 'Wants',
                      expenses: savedBudgetSummary!['expenses'] ?? {},
                      categories: getCategories('Wants'),
                    ),
                    CategoryListView(
                      type: 'Savings',
                      expenses: savedBudgetSummary!['expenses'] ?? {},
                      categories: getCategories('Savings'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    } else if (savedEnvelopes.isNotEmpty) {
      // Display saved envelopes if available
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Number of columns
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 8.0,
          ),
          itemCount: savedEnvelopes.length,
          itemBuilder: (context, index) {
            final envelope = savedEnvelopes[index];
            return Card(
              color: Color(envelope.category.color),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      envelope.category.name,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Allocated: ₱${double.parse(envelope.allocatedBudget).toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 13),
                    ),
                    Text(
                      'Remaining: ₱${double.parse(envelope.remainingBudget).toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } else {
      // Display original budgeting technique buttons if no saved data is available
      return _buildBudgetTechniqueSelection();
    }
  }

  // Method to get categories based on the type (Needs, Wants, Savings)
  List<Map<String, String>> getCategories(String type) {
    switch (type) {
      case 'Needs':
        return [
          {'icon': 'assets/Education.png', 'name': 'Education', 'id': '011'},
          {'icon': 'assets/Tuition Fees.png', 'name': 'Tuition Fees', 'id': '012'},
          {'icon': 'assets/School Supplies.png', 'name': 'School Supplies', 'id': '013'},
          {'icon': 'assets/Public Transpo.png', 'name': 'Public Transpo', 'id': '015'},
          {'icon': 'assets/House.png', 'name': 'House', 'id': '017'},
          {'icon': 'assets/Utilities.png', 'name': 'Utilities', 'id': '018'},
          {'icon': 'assets/Groceries.png', 'name': 'Groceries', 'id': '023'},
          {'icon': 'assets/Meals.png', 'name': 'Meals', 'id': '026'},
          {'icon': 'assets/Medical.png', 'name': 'Medical', 'id': '038'},
          {'icon': 'assets/Insurance.png', 'name': 'Insurance', 'id': '039'},
        ];
      case 'Wants':
        return [
          {'icon': 'assets/Dining.png', 'name': 'Dining', 'id': '005'},
          {'icon': 'assets/Travel.png', 'name': 'Travel', 'id': '007'},
          {'icon': 'assets/Shopping.png', 'name': 'Shopping', 'id': '008'},
          {'icon': 'assets/Personal Care.png', 'name': 'Personal Care', 'id': '014'},
        ];
      case 'Savings':
        return [
          {'icon': 'assets/Savings.png', 'name': 'Savings', 'id': '041'},
        ];
      default:
        return [];
    }
  }

  // Method to create buttons for budgeting techniques
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

  Widget _buildBudgetTechniqueSelection() {
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
                MaterialPageRoute(builder: (context) => IncomeInputPage()),
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
        ],
      ),
    );
  }
}