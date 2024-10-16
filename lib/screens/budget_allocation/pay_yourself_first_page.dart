import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_repository/repositories.dart';
import 'package:flutter/material.dart';

import 'PayYourselfFirstRecords.dart';

class PayYourselfFirstPage extends StatefulWidget {
  @override
  _PayYourselfFirstPageState createState() => _PayYourselfFirstPageState();
}

class _PayYourselfFirstPageState extends State<PayYourselfFirstPage> {
  TextEditingController incomeController = TextEditingController();
  TextEditingController percentController = TextEditingController();
  String incomeType = 'Monthly';
  double totalSavings = 0.0;
  double excessMoney = 0.0;

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
      // Parse and validate inputs
      final income = double.parse(incomeController.text);
      final percent = double.parse(percentController.text);
      double savings = 0.0;

      // Calculate savings based on income type
      if (incomeType == 'Weekly') {
        savings = income * (percent / 100);
      } else if (incomeType == 'Every 15th of the Month') {
        savings = income * (percent / 100);
      } else {
        savings = income * (percent / 100);
      }

      setState(() {
        totalSavings = savings;
        excessMoney = income - savings;
        showResult = true;
      });

    } catch (e) {
      // Show an error if parsing fails
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
          totalSavings: totalSavings,
          totalIncome: double.parse(incomeController.text),
          incomeType: incomeType,
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
            DropdownButton<String>(
              value: incomeType,
              onChanged: (String? newValue) {
                setState(() {
                  incomeType = newValue!;
                });
              },
              items: <String>['Monthly', 'Weekly', 'Every 15th']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
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
                'Total Savings: \$${totalSavings.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 10),
              Text(
                'Excess Money: \$${excessMoney.toStringAsFixed(2)}',
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
  final String incomeType;
  final Function(String, String) allocate;

  ShowAllocationPage({
    required this.selectedCategories,
    required this.controllers,
    required this.excessMoney,
    required this.totalSavings,
    required this.totalIncome,
    required this.incomeType,
    required this.allocate,
  });

  @override
  _ShowAllocationPageState createState() => _ShowAllocationPageState();
}

class _ShowAllocationPageState extends State<ShowAllocationPage> {
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
                                  widget.controllers[category.name] = TextEditingController();
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

  Future<void> _saveDataToFirestore() async {
    Map<String, dynamic> allocationsData = {};
    widget.selectedCategories.forEach((category) {
      allocationsData[category.name] = {
        'categoryId': category.categoryId,
        'amount': widget.controllers[category.name]?.text ?? '0',
        'icon': category.icon,
      };
    });

    await FirebaseFirestore.instance.collection('PayYourselfFirst').add({
      'incomeType': widget.incomeType,
      'totalIncome': widget.totalIncome,
      'totalSavings': widget.totalSavings,
      'excessMoney': widget.excessMoney,
      'allocations': allocationsData,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data Saved Successfully')),
    );
  }

  void _navigateToRecordsPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PayYourselfFirstRecords()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            Text('Remaining Income for Allocation: \$${widget.excessMoney.toStringAsFixed(2)}'),
            Expanded(
              child: ListView.builder(
                itemCount: widget.selectedCategories.length,
                itemBuilder: (context, index) {
                  final category = widget.selectedCategories[index];
                  return ListTile(
                    title: Row(
                      children: [
                        Image.asset(
                          category.icon,
                          width: 24,
                          height: 24,
                          color: Color(category.color),
                        ),
                        SizedBox(width: 8),
                        Text(category.name),
                      ],
                    ),
                    trailing: Container(
                      width: 100,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Amount',
                        ),
                        onChanged: (value) {
                          widget.allocate(category.name, value);
                        },
                        controller: widget.controllers[category.name],
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
                onPressed: () async {
                  await _saveDataToFirestore();
                  _navigateToRecordsPage(context);
                },
              child: Text('Continue'),
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
