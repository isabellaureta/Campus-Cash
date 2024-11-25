import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_repository/repositories.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class PayYourselfFirstPage extends StatefulWidget {
  @override
  _PayYourselfFirstPageState createState() => _PayYourselfFirstPageState();
}

class _PayYourselfFirstPageState extends State<PayYourselfFirstPage> {
  TextEditingController incomeController = TextEditingController();
  TextEditingController percentController = TextEditingController();
  double totalSavings = 0.0;
  double excessMoney = 0.0;
  double totalIncome = 0.0;

  bool showResult = false;
  final Map<String, String> allocations = {};

  List<Category> selectedCategories = predefinedCategories
      .where((category) => allowedCategoryNames.contains(category.name))
      .toList();
  final Map<String, TextEditingController> _controllers = {};

  final Map<String, double> allocationPercentages = {
    'House': 0.25,
    'Utilities': 0.10,
    'Meals': 0.15,
    'Snacks/Coffee': 0.05,
    'Medical': 0.10,
    'Insurance': 0.05,
    'Education': 0.20,
    'Tuition Fees': 0.05,
    'School Supplies': 0.02,
    'Public Transpo': 0.03,
    'Savings': 0.10,
  };

  void calculateSavingsAndExcessMoney() {
    try {
      final income = double.parse(incomeController.text);
      final percent = double.parse(percentController.text);
      final savings = income * (percent / 100);

      setState(() {
        totalIncome = income;
        totalSavings = savings;
        excessMoney = income - savings;
        showResult = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter valid numeric values for income and percent')),
      );
    }
  }

  void _allocate(String category, String amount) {
    setState(() {
      allocations[category] = amount;
      excessMoney = excessMoney -
          allocations.values.fold(0.0, (sum, amount) => sum + (double.tryParse(amount) ?? 0.0));
    });
  }

  void _navigateToShowAllocation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShowAllocationPage(
          selectedCategories: selectedCategories,
          controllers: _controllers,
          excessMoney: excessMoney,
          totalIncome: totalIncome,
          totalSavings: totalSavings,
          allocate: _allocate,
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,##0.00');
    return Scaffold(
      appBar: AppBar(
        title: Text('Pay Yourself First'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: incomeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Income'),
            ),
            TextField(
              controller: percentController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Percent of Income to Save'),
            ),
            ElevatedButton(
              onPressed: calculateSavingsAndExcessMoney,
              child: Text('Calculate Savings and Excess Money'),
            ),
            if (showResult) ...[
              SizedBox(height: 20),
              Text(
                'Total Savings: \$${numberFormat.format(totalSavings)}',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 10),
              Text(
                'Excess Money: \$${numberFormat.format(excessMoney)}',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _navigateToShowAllocation,
                child: Text('Show Allocation'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
class ShowAllocationPage extends StatefulWidget {
  final List<Category> selectedCategories;
  final Map<String, TextEditingController> controllers;
  final double excessMoney;
  final double totalSavings;
  final double totalIncome;
  final Function(String, String) allocate;

  ShowAllocationPage({
    required this.selectedCategories,
    required this.controllers,
    required this.excessMoney,
    required this.totalSavings,
    required this.allocate,
    required this.totalIncome,
  });

  @override
  _ShowAllocationPageState createState() => _ShowAllocationPageState();
}

class _ShowAllocationPageState extends State<ShowAllocationPage> {
  final Map<String, String> allocations = {};
  double remainingIncome = 0.0;
  bool isSaving = false;
  String? warningMessage;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    remainingIncome = widget.excessMoney;
    for (var category in widget.selectedCategories) {
      _controllers[category.name] = widget.controllers[category.name] ?? TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _allocate(String category, String amount) {
    setState(() {
      allocations[category] = amount;

      double totalAllocated = allocations.values.fold(0.0, (sum, amount) {
        return sum + (double.tryParse(amount) ?? 0.0);
      });
      remainingIncome = widget.excessMoney - totalAllocated;
      if (remainingIncome < 0) {
        warningMessage = 'Exceeding remaining income';
      } else {
        warningMessage = null;
      }
    });
  }

  Future<void> _saveDataToFirestore() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');
      String userId = user.uid;
      DocumentReference userDocRef = FirebaseFirestore.instance.collection('PayYourselfFirst').doc(userId);
      Map<String, dynamic> allocationsData = {};
      for (var entry in allocations.entries) {
        double allocatedAmount = double.tryParse(entry.value) ?? 0.0;
        final category = predefinedCategories.firstWhere(
              (cat) => cat.name == entry.key,
          orElse: () => throw Exception('Category not found: ${entry.key}'),
        );

        allocationsData[category.categoryId] = {
          'categoryName': category.name,
          'categoryId': category.categoryId,
          'amount': allocatedAmount,
          'allocatedAmount': allocatedAmount,
          'icon': category.icon ?? 'assets/${category.name.toLowerCase()}.png',
        };
      }
      await userDocRef.set({
        'totalIncome': widget.totalIncome,
        'totalSavings': widget.totalSavings,
        'excessMoney': widget.excessMoney,
        'yourselfExpenses': 0.0,
        'remainingYourself': widget.excessMoney,
        'allocations': allocationsData,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Allocations saved successfully!')),
      );
      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save allocations: $e')),
      );
    }
  }

  void _showCategorySelection(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.all(16.0),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select Categories',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: ListView(
                      children: predefinedCategories.map((category) {
                        return CheckboxListTile(
                          title: Text(category.name),
                          value: widget.selectedCategories.contains(category),
                          onChanged: (bool? value) {
                            setModalState(() {
                              if (value == true) {
                                setState(() {
                                  widget.selectedCategories.add(category);
                                  widget.controllers[category.name] =
                                      TextEditingController();
                                });
                              } else {
                                setState(() {
                                  widget.selectedCategories.remove(category);
                                  widget.controllers.remove(category.name);
                                });
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
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

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,##0.00');
    return Scaffold(
      appBar: AppBar(
        title: Text('Show Allocation'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => _showCategorySelection(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Remaining Income: \₱${numberFormat.format(remainingIncome)}',
              style: TextStyle(
                color: remainingIncome < 0 ? Colors.red : Colors.black,
              ),
            ),
            if (warningMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  warningMessage!,
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.selectedCategories.length,
                itemBuilder: (context, index) {
                  final category = widget.selectedCategories[index];
                  final controller = _controllers[category.name];

                  return ListTile(
                    title: Text(category.name),
                    trailing: Container(
                      width: 100,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Amount',
                        ),
                        onChanged: (value) {
                          _allocate(category.name, value);
                        },
                        controller: controller,
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: (isSaving || remainingIncome < 0) ? null : _saveDataToFirestore,
              child: isSaving ? CircularProgressIndicator() : Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}

const List<String> allowedCategoryNames = [
  'House',
  'Utilities',
  'Meals',
  'Snacks/Coffee',
  'Medical',
  'Insurance',
  'Education',
  'Tuition Fees',
  'School Supplies',
  'Public Transpo',
  'Savings',
];
