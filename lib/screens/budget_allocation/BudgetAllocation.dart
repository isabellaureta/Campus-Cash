import 'package:campuscash/screens/budget_allocation/pay_yourself_first_page.dart';
import 'package:campuscash/screens/budget_allocation/priority_based_budgeting_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '503020_budgeting_page.dart';
import '503020_records.dart';
import 'PayYourselfFirstRecords.dart';
import 'PriorityBasedRecords.dart';
import 'envelope_budgeting_page.dart';
import 'envelope_records.dart';

class BudgetAllocation extends StatefulWidget {
  @override
  _BudgetAllocationState createState() => _BudgetAllocationState();
}

class _BudgetAllocationState extends State<BudgetAllocation> {
  User? _currentUser = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? savedBudgetSummary;

  @override
  void initState() {
    super.initState();
    _fetchSavedData();
  }

  Future<void> _fetchSavedData() async {
    try {
      if (_currentUser == null) return;

      // Check for Priority-Based budgeting data first
      final priorityBasedRef = FirebaseFirestore.instance.collection('PriorityBased').doc(_currentUser!.uid);
      final priorityBasedSnapshot = await priorityBasedRef.get();

      if (priorityBasedSnapshot.exists) {
        // If Priority-Based data exists, navigate to PriorityBasedSummary
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PriorityBasedSummary(userId: _currentUser!.uid),
          ),
        );
        return; // Exit the method if Priority-Based data is found
      }

      // Reference to Pay-Yourself-First records in Firestore
      final payYourselfFirstRef = FirebaseFirestore.instance.collection('PayYourselfFirst').doc(_currentUser!.uid);

      // Fetch the saved Pay-Yourself-First data
      final payYourselfFirstSnapshot = await payYourselfFirstRef.get();

      if (payYourselfFirstSnapshot.exists) {
        // If Pay-Yourself-First data exists, navigate to PayYourselfFirstRecords
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PayYourselfFirstRecords(),
          ),
        );
        return;
      }

      // Check for Envelope Budgeting data
      final envelopeRef = FirebaseFirestore.instance
          .collection('envelopeAllocations')
          .doc(_currentUser!.uid)
          .collection('envelopes');

      final envelopeSnapshot = await envelopeRef.get();

      if (envelopeSnapshot.docs.isNotEmpty) {
        final allocations = <String, double>{};

        for (var doc in envelopeSnapshot.docs) {
          var data = doc.data();
          allocations[data['categoryName']] = (data['allocatedAmount'] as num).toDouble();
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EnvelopeBudgetingPage(
              allocations: allocations,
            ),
          ),
        );
        return;
      }

      // Check for 50/30/20 budgeting data
      final budgetRef = FirebaseFirestore.instance.collection('503020').doc(_currentUser!.uid);
      final budgetSnapshot = await budgetRef.get();

      if (budgetSnapshot.exists) {
        final data = budgetSnapshot.data() as Map<String, dynamic>;
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
              expenses: {
                'Needs': data['Needs'],
                'Wants': data['Wants'],
                'Savings': data['Savings'],
              },
              userId: _currentUser!.uid,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch saved data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Budgeting Techniques'),
      ),
      body: savedBudgetSummary != null
          ? _buildBudgetAllocation()
          : _buildBudgetTechniqueSelection(context),
    );
  }

  Widget _buildBudgetAllocation() {
    if (savedBudgetSummary != null) {
      // If there's a saved budget, display the summary similar to BudgetSummaryPage
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Budget: ₱${savedBudgetSummary!['totalBudget'].toStringAsFixed(2)}'),
                Text('Frequency: ${savedBudgetSummary!['frequency']}'),
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
                  automaticallyImplyLeading: false,
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
                    _buildCategoryList(savedBudgetSummary!['Needs'], 'Needs'),
                    _buildCategoryList(savedBudgetSummary!['Wants'], 'Wants'),
                    _buildCategoryList(savedBudgetSummary!['Savings'], 'Savings'),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // Pass context to _buildBudgetTechniqueSelection
      return _buildBudgetTechniqueSelection(context);
    }
  }

  Widget _buildCategoryList(Map<String, dynamic>? categories, String tabName) {
    if (categories == null || categories.isEmpty) {
      return Center(child: Text('No $tabName categories available.'));
    }
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories.entries.elementAt(index).value;
        return ListTile(
          leading: Image.asset(category['icon'], width: 24.0, height: 24.0),
          title: Text(category['name']),
          trailing: Text('₱${category['amount'].toStringAsFixed(2)}'),
        );
      },
    );
  }


  Widget _buildBudgetTechniqueButton(
      String title,
      String description,
      String imagePath,
      VoidCallback onPressed, {
        double height = 160,
      }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 350,
        height: height,
        margin: EdgeInsets.symmetric(vertical: 10),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.pink.shade50, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.4),
              blurRadius: 8,
              offset: Offset(2, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.asset(imagePath, width: 100, height: 100),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.agdasima(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: -0.1, delay: 100.ms, duration: 500.ms);
  }



  Widget _buildBudgetTechniqueSelection(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: _buildBudgetTechniqueButton(
              '50/30/20 Budgeting',
              'Allocate 50% to needs, 30% to wants, and 20% to savings.',
              'assets/503020.png', // Path to the image asset

                  () async {
                final userId = _currentUser!.uid;
                final docSnapshot = await FirebaseFirestore.instance.collection('503020').doc(userId).get();
                if (docSnapshot.exists) {
                  final data = docSnapshot.data() as Map<String, dynamic>;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BudgetSummaryPage(
                        totalBudget: data['totalBudget'] ?? 0.0,
                        totalExpenses: data['totalExpenses'] ?? 0.0,
                        remainingBudget: (data['totalBudget'] ?? 0.0) - (data['totalExpenses'] ?? 0.0),
                        expenses: {},
                        userId: userId,
                      ),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BudgetInputPage(userId: userId)),
                  );
                }
              },
            ),
          ),
          Center(
            child: _buildBudgetTechniqueButton(
              'Envelope Budgeting',
              'Allocate money into different envelopes for various expenses.',
              'assets/envelope.png',
                  () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => IncomeInputPage()));
              },
            ),
          ),

          Center(
            child: _buildBudgetTechniqueButton(
              'Pay-Yourself-First',
              'Prioritize savings and investments before other expenses.',
              'assets/payyourselffirst.png',
                  () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => PayYourselfFirstPage()));
              },
            ),
          ),
          Center(
            child: _buildBudgetTechniqueButton(
              'Priority-Based Budgeting',
              'Allocate funds based on priority expenses.',
              'assets/prioritybased.png',
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CategorySelectionPage(
                    onSelectionDone: (selectedCategories) {
                      setState(() {
                        selectedCategories = selectedCategories;
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RankCategoriesPage(
                          selectedCategories: selectedCategories,
                          onRankingDone: (rankedCategories) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => PriorityBasedRecords(
                                selectedCategories: rankedCategories,
                              )),
                            );
                          },
                        )),
                      );
                    },
                  )),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}