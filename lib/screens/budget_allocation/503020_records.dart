
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'addBudgetandAllocation.dart';


class BudgetSummaryPage extends StatefulWidget {
  final double totalBudget;
  final double totalExpenses;
  final double remainingBudget;
  final Map<String, String> expenses;
  final String userId;

  BudgetSummaryPage({
    required this.totalBudget,
    required this.totalExpenses,
    required this.remainingBudget,
    required this.expenses,
    required this.userId,
  });

  @override
  _BudgetSummaryPageState createState() => _BudgetSummaryPageState();
}

class _BudgetSummaryPageState extends State<BudgetSummaryPage> {
  double totalBudget = 0;
  double totalExpenses = 0;
  double remainingBudget = 0;
  Map<String, String> expenses = {};

  @override
  void initState() {
    super.initState();
    _fetchBudgetData();
  }

  Future<void> _fetchBudgetData() async {
    final userId = widget.userId;
    final docSnapshot = await FirebaseFirestore.instance.collection('503020').doc(userId).get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data() as Map<String, dynamic>;
      setState(() {
        totalBudget = data['totalBudget'] ?? 0.0;
        totalExpenses = data['totalExpenses'] ?? 0.0;
        remainingBudget = totalBudget - totalExpenses;
        // Fetch expenses from Firestore and update state
        _fetchExpensesData();
      });
    }
  }

  Future<void> _fetchExpensesData() async {
    final userId = widget.userId;
    final needsSnapshot = await FirebaseFirestore.instance.collection('503020').doc(userId).collection('Needs').get();
    final wantsSnapshot = await FirebaseFirestore.instance.collection('503020').doc(userId).collection('Wants').get();
    final savingsSnapshot = await FirebaseFirestore.instance.collection('503020').doc(userId).collection('Savings').get();

    setState(() {
      expenses = {};
      for (var doc in needsSnapshot.docs) {
        expenses[doc.id] = doc.data()['amount'].toString();
      }
      for (var doc in wantsSnapshot.docs) {
        expenses[doc.id] = doc.data()['amount'].toString();
      }
      for (var doc in savingsSnapshot.docs) {
        expenses[doc.id] = doc.data()['amount'].toString();
      }
    });
  }

  List<Map<String, String>> getCategories(String type) {
    if (type == 'Needs') {
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
    } else if (type == 'Wants') {
      return [
        {'icon': 'assets/Dining.png', 'name': 'Dining', 'id': '005'},
        {'icon': 'assets/Travel.png', 'name': 'Travel', 'id': '007'},
        {'icon': 'assets/Shopping.png', 'name': 'Shopping', 'id': '008'},
        {'icon': 'assets/Personal Care.png', 'name': 'Personal Care', 'id': '014'},
      ];
    } else {
      return [
        {'icon': 'assets/Savings.png', 'name': 'Savings', 'id': '041'},
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AddBudget(userId: widget.userId),
          ),
        );
        return false;
      },
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Budget Allocation'),
            bottom: TabBar(
              tabs: [
                Tab(text: 'Needs'),
                Tab(text: 'Wants'),
                Tab(text: 'Savings'),
              ],
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Budget: ₱${totalBudget.toStringAsFixed(2)}'),
                    Text('Total Expenses: ₱${totalExpenses.toStringAsFixed(2)}'),
                    Text('Remaining Budget: ₱${remainingBudget.toStringAsFixed(2)}'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    CategoryListView(type: 'Needs', expenses: expenses, categories: getCategories('Needs')),
                    CategoryListView(type: 'Wants', expenses: expenses, categories: getCategories('Wants')),
                    CategoryListView(type: 'Savings', expenses: expenses, categories: getCategories('Savings')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryListView extends StatelessWidget {
  final String type;
  final Map<String, String> expenses;
  final List<Map<String, String>> categories;

  CategoryListView({
    required this.type,
    required this.expenses,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final amount = expenses[category['id']] ?? '0.00';

        return ListTile(
          leading: Image.asset(
            category['icon']!,
            width: 24,
            height: 24,
          ),
          title: Text(category['name']!),
          trailing: Text('₱$amount'),
        );
      },
    );
  }
}
