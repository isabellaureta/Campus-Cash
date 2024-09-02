import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_repository/repositories.dart';
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
    totalBudget = widget.totalBudget;
    totalExpenses = widget.totalExpenses;
    remainingBudget = widget.remainingBudget;
    expenses = widget.expenses;
  }

  Future<void> _saveBudgetToFirestore() async {
    final userId = widget.userId;
    final firestore = FirebaseFirestore.instance;
    final userDocRef = firestore.collection('503020').doc(userId);

    // Save user budget info
    await userDocRef.set({
      'userId': userId,
      'totalBudget': totalBudget,
      'totalExpenses': totalExpenses,
      'remainingBudget': remainingBudget,
    });

    // Save Needs categories
    final needsCollectionRef = userDocRef.collection('Needs');
    widget.expenses.forEach((categoryId, amount) async {
      final category = predefinedCategories.firstWhere((cat) => cat.categoryId == categoryId);
      await needsCollectionRef.doc(categoryId).set({
        'categoryId': categoryId,
        'name': category.name,
        'amount': double.tryParse(amount) ?? 0.0,
        'icon': category.icon,
        'color': category.color,
        'dateCreated': DateTime.now().toIso8601String(),
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data saved successfully!')),
    );

    // Navigate back to AddBudget page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AddBudget(userId: userId)),
    );
  }



  // Define the getCategories method to return category lists based on the type
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
    } else if (type == 'Savings') {
      return [
        {'icon': 'assets/Savings.png', 'name': 'Savings', 'id': '041'},
      ];
    } else {
      return [];
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _saveBudgetToFirestore,
                  child: Text('Save to Firestore'),
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
