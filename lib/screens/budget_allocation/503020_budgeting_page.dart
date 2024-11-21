import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_repository/repositories.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '503020_records.dart';

class BudgetInputPage extends StatefulWidget {
  final String userId;

  BudgetInputPage({required this.userId});

  @override
  State<BudgetInputPage> createState() => _BudgetInputPageState();
}

class _BudgetInputPageState extends State<BudgetInputPage> {
  final _budgetController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Budget'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('503020').doc(widget.userId).get(),
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
              expenses: {},
              userId: widget.userId,
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
                ElevatedButton(
                  onPressed: () {
                    if (_budgetController.text.isNotEmpty) {
                      double totalBudget = double.parse(_budgetController.text);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Budget503020Page(
                            totalBudget: totalBudget,
                            userId: widget.userId,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter a budget')),
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
  final String userId;

  Budget503020Page({required this.totalBudget, required this.userId});

  @override
  _Budget503020PageState createState() => _Budget503020PageState();
}

class _Budget503020PageState extends State<Budget503020Page> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _totalExpenses = 0;
  double _needsExpenses = 0;
  double _wantsExpenses = 0;
  double _savingsExpenses = 0;

  final Map<String, bool> _modifiedCategories = {};
  final List<Category2> savingsCategories = predefinedCategories2;

  final Map<String, String> _expenses = {};
  final Map<String, TextEditingController> _controllers = {};

  List<Category> _getCategoriesForTab(Set<String> categoryIds) {
    return predefinedCategories.where((category) => categoryIds.contains(category.categoryId)).toList();
  }

  Set<String> needsCategoryIds = {
    '011', '012', '013', '015', '017', '018', '023', '026', '038', '039'
  };

  Set<String> wantsCategoryIds = {
    '005', '007', '008', '014'
  };

  Set<String> savingsCategoryIds = {
    '041'
  };

  List<Category2> _getSavingsCategoriesForTab(Set<String> categoryIds) {
    return predefinedCategories2.where((category) => categoryIds.contains(category.categoryId2)).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeControllers();
  }

  void _initializeControllers() {
    needsCategoryIds.forEach((categoryId) {
      _controllers[categoryId] = TextEditingController();
    });
    wantsCategoryIds.forEach((categoryId) {
      _controllers[categoryId] = TextEditingController();
    });
    savingsCategoryIds.forEach((categoryId) {
      _controllers[categoryId] = TextEditingController();
    });
  }

  double _calculateCategoryExpenses(Iterable<String> categoryIds) {
    return categoryIds.fold(0, (sum, categoryId) {
      final value = double.tryParse(_expenses[categoryId] ?? '0') ?? 0;
      return sum + value;
    });
  }

  void _updateExpense(String categoryId, String amount, double tabBudget, String tabName) {
    setState(() {
      double parsedAmount = double.tryParse(amount) ?? 0;
      double currentTabExpenses = _calculateCategoryExpenses(
          tabName == 'Needs' ? needsCategoryIds :
          tabName == 'Wants' ? wantsCategoryIds : savingsCategoryIds);

      double previousAmount = double.tryParse(_expenses[categoryId] ?? '0') ?? 0;
      double newTotalExpenses = currentTabExpenses - previousAmount + parsedAmount;
      if (newTotalExpenses > tabBudget) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$tabName balance limit exceeded!')),
        );
        return;
      }

      _totalExpenses -= previousAmount;
      _totalExpenses += parsedAmount;

      _expenses[categoryId] = amount;
      _modifiedCategories[categoryId] = true;

      _needsExpenses = _calculateCategoryExpenses(needsCategoryIds);
      _wantsExpenses = _calculateCategoryExpenses(wantsCategoryIds);
      _savingsExpenses = _calculateCategoryExpenses(savingsCategoryIds);

      _adjustTotalBudgetAfterExpense(tabName, parsedAmount);
      String categoryType = (needsCategoryIds.contains(categoryId))
          ? 'Needs'
          : (wantsCategoryIds.contains(categoryId))
          ? 'Wants'
          : (savingsCategoryIds.contains(categoryId))
          ? 'Savings'
          : 'Custom';

      if (categoryType != 'Custom') {
        _updateCategoryBudget(widget.userId, categoryType, categoryId, parsedAmount.toInt());
      }
    });
  }

  Future<void> _saveBudgetToFirestore() async {
    final userId = widget.userId;
    final firestore = FirebaseFirestore.instance;
    final userDocRef = firestore.collection('503020').doc(userId);
    final snapshot = await userDocRef.get();

    final totalBudget = snapshot.exists ? (snapshot['totalBudget'] ?? widget.totalBudget) : widget.totalBudget;
    final totalExpenses = snapshot.exists ? (snapshot['totalExpenses'] ?? 0.0) : 0.0;

    final calculatedRemainingBudget = totalBudget - totalExpenses;

    final needsBudget = totalBudget * 0.50;
    final wantsBudget = totalBudget * 0.30;
    final savingsBudget = totalBudget * 0.20;

    await userDocRef.set({
      'userId': userId,
      'totalBudget': totalBudget,
      'totalExpenses': totalExpenses,
      'remainingBudget': calculatedRemainingBudget,
      'needsBudget': needsBudget,
      'wantsBudget': wantsBudget,
      'savingsBudget': savingsBudget,
    }, SetOptions(merge: true));

    final needsCollectionRef = userDocRef.collection('Needs');
    for (String categoryId in needsCategoryIds) {
      if (_expenses[categoryId] != null && _expenses[categoryId]!.isNotEmpty) {
        final amount = double.tryParse(_expenses[categoryId]!) ?? 0;
        final category = predefinedCategories.firstWhere((cat) => cat.categoryId == categoryId);
        await needsCollectionRef.doc(categoryId).set({
          'categoryId': categoryId,
          'name': category.name,
          'amount': amount,
          'originalAmount': amount,
          'icon': category.icon,
          'color': category.color,
        });
      }
    }

    final wantsCollectionRef = userDocRef.collection('Wants');
    for (String categoryId in wantsCategoryIds) {
      if (_expenses[categoryId] != null && _expenses[categoryId]!.isNotEmpty) {
        final amount = double.tryParse(_expenses[categoryId]!) ?? 0;
        final category = predefinedCategories.firstWhere((cat) => cat.categoryId == categoryId);
        await wantsCollectionRef.doc(categoryId).set({
          'categoryId': categoryId,
          'name': category.name,
          'amount': amount,
          'originalAmount': amount,
          'icon': category.icon,
          'color': category.color,
        });
      }
    }

    final savingsCollectionRef = userDocRef.collection('Savings');
    for (String categoryId in savingsCategoryIds) {
      if (_expenses[categoryId] != null && _expenses[categoryId]!.isNotEmpty) {
        final amount = double.tryParse(_expenses[categoryId]!) ?? 0;
        final category = predefinedCategories2.firstWhere((cat) => cat.categoryId2 == categoryId);
        await savingsCollectionRef.doc(categoryId).set({
          'categoryId': categoryId,
          'name': category.name,
          'amount': amount,
          'icon': category.icon,
          'color': category.color,
        });
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BudgetSummaryPage(
          userId: userId,
          totalExpenses: totalExpenses,
          remainingBudget: calculatedRemainingBudget,
          totalBudget: totalBudget,
          expenses: _expenses,
        ),
      ),
    );
  }


  Future<void> _adjustTotalBudgetAfterExpense(String categoryName, double amount) async {
    final userId = widget.userId;
    final userDocRef = FirebaseFirestore.instance.collection('503020').doc(userId);
    DocumentSnapshot snapshot = await userDocRef.get();
    if (snapshot.exists) {
      double totalBudget = snapshot['totalBudget'] ?? 0.0;
      double totalExpenses = snapshot['totalExpenses'] ?? 0.0;

      totalExpenses += amount;
      await userDocRef.update({
        'totalExpenses': totalExpenses,
        'remainingBudget': totalBudget - totalExpenses,
      });
    }
  }

  Future<void> _updateCategoryBudget(String userId, String categoryType, String categoryId, int expenseAmount) async {
    try {
      final budgetDocRef = FirebaseFirestore.instance.collection('503020').doc(userId);
      DocumentSnapshot categoryDoc = await budgetDocRef.collection(categoryType).doc(categoryId).get();

      if (categoryDoc.exists) {
        Map<String, dynamic> categoryData = categoryDoc.data() as Map<String, dynamic>;
        double currentAmount = categoryData['amount'] ?? 0.0;
        double updatedAmount = currentAmount - expenseAmount;
        if (updatedAmount < 0) updatedAmount = 0;
        await budgetDocRef.collection(categoryType).doc(categoryId).update({
          'amount': updatedAmount,
        });
      }
    } catch (e) {
      print('Failed to update budget for category $categoryId: ${e.toString()}');
      rethrow;
    }
  }

  void _showEditCategoryPopup(BuildContext context) {
    int currentTabIndex = _tabController.index;

    Set<String> currentTabCategories;
    List<dynamic> selectableCategories;
    String categoryType;

    if (currentTabIndex == 0) {
      currentTabCategories = needsCategoryIds;
      categoryType = "Needs";
      selectableCategories = predefinedCategories;
    } else if (currentTabIndex == 1) {
      currentTabCategories = wantsCategoryIds;
      categoryType = "Wants";
      selectableCategories = predefinedCategories;
    } else {
      currentTabCategories = savingsCategoryIds;
      categoryType = "Savings";
      selectableCategories = predefinedCategories2;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateInPopup) {
            return Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Select $categoryType Categories', style: TextStyle(fontSize: 18)),
                  Expanded(
                    child: ListView.builder(
                      itemCount: selectableCategories.length,
                      itemBuilder: (context, index) {
                        final category = selectableCategories[index];
                        final categoryId = category is Category ? category.categoryId : category.categoryId2;
                        final isSelected = currentTabCategories.contains(categoryId);
                        final isAlreadyInAnotherTab = needsCategoryIds.contains(categoryId) ||
                            wantsCategoryIds.contains(categoryId) ||
                            savingsCategoryIds.contains(categoryId);
                        return CheckboxListTile(
                          title: Text(category.name),
                          value: isSelected,
                          onChanged: (value) {
                            setStateInPopup(() {
                              if (isAlreadyInAnotherTab && !isSelected) return;

                              if (value == true) {
                                currentTabCategories.add(categoryId);
                              } else {
                                currentTabCategories.remove(categoryId);
                              }
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          secondary: isAlreadyInAnotherTab
                              ? Icon(Icons.lock, color: Colors.grey)
                              : null,
                        );
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                      });
                      Navigator.pop(context);
                    },
                    child: Text('Done'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBudgetSummary() {
    final totalBudgetToSpend = widget.totalBudget * 0.50 + widget.totalBudget * 0.30;
    final remainingBudget = totalBudgetToSpend - _totalExpenses;
    final numberFormat = NumberFormat('#,##0.00');

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Budget: ₱${numberFormat.format(widget.totalBudget)}',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 8.0),
          Text(
            'Total Budget to Spend: ₱${numberFormat.format(totalBudgetToSpend)}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.0),
          Text(
            'Total Expenses: ₱${numberFormat.format(_totalExpenses)}',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16.0),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(String categoryName, double budget, double expenses, List<dynamic> categories) {
    final numberFormat = NumberFormat('#,##0.00'); // Define the formatter
    final List<dynamic> tabCategories = (categoryName == 'Savings')
        ? _getSavingsCategoriesForTab(savingsCategoryIds)
        : categories;
    final double progress = expenses / budget;

    Color progressColor;
    if (progress >= 0.90) {
      progressColor = Colors.red;
    } else if (progress >= 0.75) {
      progressColor = Colors.orange.shade700;
    } else if (progress >= 0.60) {
      progressColor = Colors.yellow.shade700;
    } else {
      progressColor = Colors.blue;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$categoryName Budget: ₱${numberFormat.format(budget)}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            'Expenses: ₱${numberFormat.format(expenses)}',
            style: TextStyle(fontSize: 16),
          ),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            color: progressColor,
          ),
          SizedBox(height: 16.0),
          Expanded(
            child: ListView.builder(
              itemCount: tabCategories.length,
              itemBuilder: (context, index) {
                final category = tabCategories[index];

                final categoryId = category is Category ? category.categoryId : category.categoryId2;
                final categoryName = category.name;
                final categoryIcon = category.icon;

                if (!_controllers.containsKey(categoryId)) {
                  _controllers[categoryId] = TextEditingController();
                }

                final _expenseController = _controllers[categoryId]!;
                _expenseController.text = _expenses[categoryId] ?? '';

                return ListTile(
                  leading: Image.asset(
                    categoryIcon,
                    width: 24.0,
                    height: 24.0,
                  ),
                  title: Text(categoryName),
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

                        _updateExpense(
                          categoryId,
                          value,
                          budget,  // Pass the budget for this tab
                          categoryName,  // Pass the tab name for error messaging
                        );
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

  @override
  Widget build(BuildContext context) {
    final totalBudget = widget.totalBudget;
    final needsBudget = totalBudget * 0.50;
    final wantsBudget = totalBudget * 0.30;
    final savingsBudget = totalBudget * 0.20;

    return Scaffold(
      appBar: AppBar(
        title: Text('50-30-20 Budget Allocation'),
        actions: [
          if (_tabController.index != 2)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => _showEditCategoryPopup(context),
            ),
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveBudgetToFirestore, // Save to Firestore
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
      body: Column(
        children: [
          _buildBudgetSummary(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Needs Tab
                Column(
                  children: [
                    Expanded(child: _buildCategoryTab('Needs', needsBudget, _needsExpenses, _getCategoriesForTab(needsCategoryIds))),
                  ],
                ),
                // Wants Tab
                Column(
                  children: [
                    Expanded(child: _buildCategoryTab('Wants', wantsBudget, _wantsExpenses, _getCategoriesForTab(wantsCategoryIds))),
                  ],
                ),
                // Savings Tab - uses predefined savings categories directly
                Column(
                  children: [
                    Expanded(child: _buildCategoryTab('Savings', savingsBudget, _savingsExpenses, savingsCategories)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}