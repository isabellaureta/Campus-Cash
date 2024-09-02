import 'package:expense_repository/repositories.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
    double income = double.parse(incomeController.text);
    double percent = double.parse(percentController.text);

    if (incomeType == 'Weekly') {
      income *= 4; // Convert weekly income to monthly
    }

    double savings = income * (percent / 100);

    setState(() {
      totalSavings = savings;
      excessMoney = income - savings;
      showResult = true;

      // Initialize TextEditingControllers for each category
      for (var category in selectedCategories) {
        _controllers[category.name] = TextEditingController();
      }
    });
  }

  void _allocate(String category, String amount) {
    setState(() {
      allocations[category] = amount;
      excessMoney = excessMoney -
          allocations.values.fold(0.0, (sum, amount) => sum + (double.tryParse(amount) ?? 0.0));
    });
  }

  void _suggestAllocations() {
    setState(() {
      allocations.clear();
      double totalAllocated = 0.0;

      for (var category in selectedCategories) {
        double allocatedAmount = excessMoney * (allocationPercentages[category.name] ?? 0.0);
        allocations[category.name] = allocatedAmount.toStringAsFixed(2);
        _controllers[category.name]?.text = allocatedAmount.toStringAsFixed(2);
        totalAllocated += allocatedAmount;
      }

      excessMoney -= totalAllocated;
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
          allocate: _allocate,
          suggestAllocations: _suggestAllocations,
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
              items: <String>['Monthly', 'Weekly']
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
  final Function(String, String) allocate;
  final VoidCallback suggestAllocations;

  ShowAllocationPage({
    required this.selectedCategories,
    required this.controllers,
    required this.excessMoney,
    required this.allocate,
    required this.suggestAllocations,
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
                      // Update the parent state with the modified selected categories
                      setState(() {
                        widget.suggestAllocations(); // Recalculate allocations based on updated categories
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Show Allocation'),
        actions: [
          IconButton(
            icon: Icon(Icons.auto_awesome), // Changed icon to auto_awesome
            onPressed: widget.suggestAllocations, // Transferred function to icon
          ),
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
              onPressed: widget.suggestAllocations,
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