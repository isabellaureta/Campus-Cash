import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_repository/repositories.dart';
import 'package:flutter/material.dart';
import '503020_records.dart';


class BudgetInputPage extends StatelessWidget {
  final String userId;

  BudgetInputPage({required this.userId});

  final _budgetController = TextEditingController();
  String? _selectedFrequency;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Budget and Frequency'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('503020').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final totalBudget = data['totalBudget'] ?? 0.0;
            final totalExpenses = data['totalExpenses'] ?? 0.0;
            final remainingBudget = totalBudget - totalExpenses;

            return BudgetSummaryPage(
              totalBudget: totalBudget,
              totalExpenses: totalExpenses,
              remainingBudget: remainingBudget,
              expenses: {}, // Fetch expenses from Firestore
              userId: userId,
            );
          }

          return Padding(
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
                            userId: userId,
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
          );
        },
      ),
    );
  }
}


class Budget503020Page extends StatefulWidget {
  final double totalBudget;
  final String frequency;
  final String userId; // Add userId parameter


  Budget503020Page({required this.totalBudget, required this.frequency, required this.userId}); // Accept userId

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

  final Map<String, String> _expenses = {};
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _needsAllocation.keys.forEach((categoryId) {
      _controllers[categoryId] = TextEditingController();
    });
    _getWantsCategories().forEach((category) {
      _controllers[category.categoryId] = TextEditingController();
    });
    _getSavingsCategories().forEach((category) {
      _controllers[category.categoryId] = TextEditingController();
    });
  }

  double _calculateCategoryExpenses(Iterable<String> categoryIds) {
    return categoryIds.fold(0, (sum, categoryId) {
      final value = double.tryParse(_expenses[categoryId] ?? '0') ?? 0;
      return sum + value;
    });
  }

  void _updateExpense(String categoryId, String amount) {
    setState(() {
      double parsedAmount = double.tryParse(amount) ?? 0;
      _totalExpenses -= double.tryParse(_expenses[categoryId] ?? '0') ?? 0;
      _totalExpenses += parsedAmount;
      _expenses[categoryId] = amount;

      _needsExpenses = _calculateCategoryExpenses(_needsAllocation.keys);
      _wantsExpenses = _calculateCategoryExpenses(_getWantsCategories().map((e) => e.categoryId));
      _savingsExpenses = _calculateCategoryExpenses(_getSavingsCategories().map((e) => e.categoryId));
    });
  }

  Future<void> _saveBudgetToFirestore() async {
    final userId = widget.userId; // Use the userId from the widget
    final totalBudget = widget.totalBudget;
    final frequency = widget.frequency;

    final firestore = FirebaseFirestore.instance;
    final userDocRef = firestore.collection('503020').doc(userId);

    // Save user budget info
    await userDocRef.set({
      'userId': userId,
      'totalBudget': totalBudget,
      'frequency': frequency,
    });

    // Save Needs categories
    final needsCollectionRef = userDocRef.collection('Needs');
    _needsAllocation.forEach((categoryId, _) async {
      final amount = double.tryParse(_expenses[categoryId] ?? '0') ?? 0;
      final category = predefinedCategories.firstWhere((cat) => cat.categoryId == categoryId);
      await needsCollectionRef.doc(categoryId).set({
        'categoryId': categoryId,
        'name': category.name,
        'amount': amount,
        'icon': category.icon,
        'color': category.color,
        'dateCreated': DateTime.now().toIso8601String(),
      });
    });

    // Save Wants categories
    final wantsCollectionRef = userDocRef.collection('Wants');
    _getWantsCategories().forEach((category) async {
      final amount = double.tryParse(_expenses[category.categoryId] ?? '0') ?? 0;
      await wantsCollectionRef.doc(category.categoryId).set({
        'categoryId': category.categoryId,
        'name': category.name,
        'amount': amount,
        'icon': category.icon,
        'color': category.color,
        'dateCreated': DateTime.now().toIso8601String(),
      });
    });

    // Save Savings categories
    final savingsCollectionRef = userDocRef.collection('Savings');
    _getSavingsCategories().forEach((category) async {
      final amount = double.tryParse(_expenses[category.categoryId] ?? '0') ?? 0;
      await savingsCollectionRef.doc(category.categoryId).set({
        'categoryId': category.categoryId,
        'name': category.name,
        'amount': amount,
        'icon': category.icon,
        'color': category.color,
        'dateCreated': DateTime.now().toIso8601String(),
      });
    });
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
          LinearProgressIndicator(
            value: expenses / budget,
            backgroundColor: Colors.grey[300],
            color: Colors.blue,
          ),
          SizedBox(height: 16.0),
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final categoryExpense = _expenses[category.categoryId] ?? '';
                final _expenseController = _controllers[category.categoryId]!;

                _expenseController.text = categoryExpense;

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
                      controller: _expenseController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        prefixText: '₱',
                        hintText: '0.00',
                      ),
                      onChanged: (value) {
                        final textSelection = _expenseController.selection;
                        _updateExpense(category.categoryId, value);
                        _expenseController.value = _expenseController.value.copyWith(
                          selection: textSelection,
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  final Set<String> needsCategoryIds = {
    '011', '012', '013', '015', '017', '018', '023', '026', '038', '039'
  };

  final Set<String> wantsCategoryIds = {
    '005', '007', '008', '014'
  };

  final Set<String> savingsCategoryIds = {
    '041'
  };

  List<Category> _getNeedsCategories() {
    return predefinedCategories.where((category) => needsCategoryIds.contains(category.categoryId)).toList();
  }

  List<Category> _getWantsCategories() {
    return predefinedCategories.where((category) => wantsCategoryIds.contains(category.categoryId)).toList();
  }

  List<Category> _getSavingsCategories() {
    return predefinedCategories.where((category) => savingsCategoryIds.contains(category.categoryId)).toList();
  }

  void _navigateToSummaryPage() async {
    final remainingBudget = widget.totalBudget - _totalExpenses;

    // Save data to Firestore
    await _saveBudgetToFirestore();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BudgetSummaryPage(
          totalBudget: widget.totalBudget,
          totalExpenses: _totalExpenses,
          remainingBudget: remainingBudget,
          expenses: _expenses,
          userId: widget.userId, // Pass the userId
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final totalBudget = widget.totalBudget;
    final needsBudget = totalBudget * 0.50;
    final wantsBudget = totalBudget * 0.30;
    final savingsBudget = totalBudget * 0.20;

    return Scaffold(
      appBar: AppBar(
        title: Text('50-30-20 Budget Allocation'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Needs'),
            Tab(text: 'Wants'),
            Tab(text: 'Savings'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildBudgetSummary(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryTab('Needs', needsBudget, _needsExpenses, _getNeedsCategories()),
                _buildCategoryTab('Wants', wantsBudget, _wantsExpenses, _getWantsCategories()),
                _buildCategoryTab('Savings', savingsBudget, _savingsExpenses, _getSavingsCategories()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _navigateToSummaryPage,
              child: Text('Save Allocation'),
            ),
          ),
        ],
      ),
    );
  }
}