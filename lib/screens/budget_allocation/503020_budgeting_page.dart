import 'package:expense_repository/repositories.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BudgetInputPage(),
    );
  }
}

class BudgetInputPage extends StatelessWidget {
  final _budgetController = TextEditingController();
  final _frequencyController = TextEditingController();
  String? _selectedFrequency;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Budget and Frequency'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Total Budget',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              value: _selectedFrequency,
              hint: Text('Select Frequency'),
              items: [
                DropdownMenuItem(
                  value: 'Weekly',
                  child: Text('Weekly'),
                ),
                DropdownMenuItem(
                  value: 'Bi-Weekly',
                  child: Text('Every 15th of the Month'),
                ),
                DropdownMenuItem(
                  value: 'Monthly',
                  child: Text('Monthly'),
                ),
              ],
              onChanged: (value) {
                _selectedFrequency = value;
              },
              decoration: InputDecoration(
                labelText: 'Budget Frequency',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                if (_budgetController.text.isNotEmpty && _selectedFrequency != null) {
                  double totalBudget = double.parse(_budgetController.text);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Budget503020Page(
                        totalBudget: totalBudget,
                        frequency: _selectedFrequency!,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a budget and select a frequency')),
                  );
                }
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

class Budget503020Page extends StatefulWidget {
  final double totalBudget;
  final String frequency;

  Budget503020Page({required this.totalBudget, required this.frequency});

  @override
  _Budget503020PageState createState() => _Budget503020PageState();
}

class _Budget503020PageState extends State<Budget503020Page> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _totalExpenses = 0;
  double _needsExpenses = 0;
  double _wantsExpenses = 0;
  double _savingsExpenses = 0;

  final Map<String, double> _needsAllocation = {
    '011': 0.20,
    '012': 0.20,
    '013': 0.05,
    '015': 0.10,
    '017': 0.15,
    '018': 0.10,
    '023': 0.10,
    '026': 0.05,
    '038': 0.03,
    '039': 0.02,
  };

  final Map<String, double> _expenses = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _updateExpense(String categoryId, double amount) {
    setState(() {
      _totalExpenses -= _expenses[categoryId] ?? 0;
      _totalExpenses += amount;
      _expenses[categoryId] = amount;

      _needsExpenses = _calculateCategoryExpenses(_needsAllocation.keys);
      // Handle other categories if needed
    });
  }

  double _calculateCategoryExpenses(Iterable<String> categoryIds) {
    return categoryIds.fold(0, (sum, categoryId) => sum + (_expenses[categoryId] ?? 0));
  }

  Widget _buildBudgetSummary() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Budget: ₱${widget.totalBudget.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 16),
          ),
          Text(
            'Frequency: ${widget.frequency}',
            style: TextStyle(fontSize: 16),
          ),
          Text(
            'Total Expenses: ₱${_totalExpenses.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 16),
          ),
          Text(
            'Remaining Budget: ₱${(widget.totalBudget - _totalExpenses).toStringAsFixed(2)}',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(String categoryName, double budget, double expenses, List<Category> categories) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$categoryName Budget: ₱${budget.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            'Expenses: ₱${expenses.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 16),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final categoryExpense = _expenses[category.categoryId] ?? 0;
                final _expenseController = TextEditingController(text: categoryExpense.toString());
                return ListTile(
                  leading: Image.asset(
                    category.icon,
                    width: 24.0,
                    height: 24.0,
                  ),
                  title: Text(category.name),
                  trailing: SizedBox(
                    width: 100,
                    child: TextField(
                onChanged: (value) => _updateExpense(category.categoryId, value as double),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                prefixText: '₱',
                hintText: '0.0',
                    ),
                  ),
                ));
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Category> _getNeedsCategories() {
    return [
      Category(icon: 'assets/Education.png', name: 'Education', color: 0xFFE57373, categoryId: '011'),
      Category(icon: 'assets/Tuition Fees.png', name: 'Tuition Fees', color: 0xFF81C784, categoryId: '012'),
      Category(icon: 'assets/School Supplies.png', name: 'School Supplies', color: 0xFF64B5F6, categoryId: '013'),
      Category(icon: 'assets/Public Transpo.png', name: 'Public Transpo', color: 0xFFBA68C8, categoryId: '015'),
      Category(icon: 'assets/House.png', name: 'House', color: 0xFFAED581, categoryId: '017'),
      Category(icon: 'assets/Utilities.png', name: 'Utilities', color: 0xFF7986CB, categoryId: '018'),
      Category(icon: 'assets/Groceries.png', name: 'Groceries', color: 0xFF7986CB, categoryId: '023'),
      Category(icon: 'assets/Meals.png', name: 'Meals', color: 0xFF7986CB, categoryId: '026'),
      Category(icon: 'assets/Medical.png', name: 'Medical', color: 0xFF7986CB, categoryId: '038'),
      Category(icon: 'assets/Insurance.png', name: 'Insurance', color: 0xFF7986CB, categoryId: '039'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    double needsBudget = widget.totalBudget * 0.5;
    double wantsBudget = widget.totalBudget * 0.3;
    double savingsBudget = widget.totalBudget * 0.2;

    final needsCategories = _getNeedsCategories();

    return Scaffold(
      appBar: AppBar(
        title: Text('50/30/20 Budget Allocation'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Needs'),
            Tab(text: 'Wants'),
            Tab(text: 'Savings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryTab('Needs', needsBudget, _needsExpenses, needsCategories),
          _buildCategoryTab('Wants', wantsBudget, _wantsExpenses, []),  // Add wants categories here
          _buildCategoryTab('Savings', savingsBudget, _savingsExpenses, []),  // Add savings categories here
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: _buildBudgetSummary(),
      ),
    );
  }
}
