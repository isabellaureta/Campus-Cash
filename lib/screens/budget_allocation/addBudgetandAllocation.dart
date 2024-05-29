import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'addBudget.dart';

class AddBudget extends StatefulWidget {
  @override
  State<AddBudget> createState() => _AddBudgetState();
}

class _AddBudgetState extends State<AddBudget> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = const [
    Tab(text: 'Budget'),
    Tab(text: 'Budget Allocation'),
  ];

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
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
      await FirebaseFirestore.instance
          .collection('budgets')
          .doc(document.id)
          .delete();
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
          Center(
              child: Text('Add Budget allocation')
          ),
        ],
      ),
    );
  }
}
