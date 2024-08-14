import 'package:expense_repository/repositories.dart';
import 'package:flutter/material.dart';

import 'envelope_records.dart';

class Envelope {
  final Category category;
  String allocatedBudget;
  String remainingBudget;

  Envelope({
    required this.category,
    required this.allocatedBudget,
  }) : remainingBudget = allocatedBudget;
}


// Define the allowed category names
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

// Filter predefinedCategories to include only the allowed categories
final List<Category> filteredCategories = predefinedCategories.where((category) {
  return allowedCategoryNames.contains(category.name);
}).toList();

class IncomeInputPage extends StatefulWidget {
  @override
  _IncomeInputPageState createState() => _IncomeInputPageState();
}

class _IncomeInputPageState extends State<IncomeInputPage> {
  TextEditingController incomeController = TextEditingController();
  String frequency = 'Monthly';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Enter Your Income')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: incomeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Income Amount'),
            ),
            DropdownButton<String>(
              value: frequency,
              items: <String>['Weekly', 'Every 15th', 'Monthly'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  frequency = newValue!;
                });
              },
            ),
            ElevatedButton(
              onPressed: () {
                double income = double.parse(incomeController.text);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AllocationPage(income: income, frequency: frequency),
                  ),
                );
              },
              child: Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}

class AllocationPage extends StatefulWidget {
  final double income;
  final String frequency;

  AllocationPage({required this.income, required this.frequency});

  @override
  _AllocationPageState createState() => _AllocationPageState();
}

class _AllocationPageState extends State<AllocationPage> {
  final Map<String, String> allocations = {};
  double remainingIncome = 0.0;
  List<Category> selectedCategories = filteredCategories;

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

  @override
  void initState() {
    super.initState();
    remainingIncome = widget.income;
  }

  void _allocate(String category, String amount) {
    setState(() {
      allocations[category] = amount;
      remainingIncome = widget.income -
          allocations.values.fold(0.0, (sum, amount) => sum + (double.tryParse(amount) ?? 0.0));
    });
  }


  void _suggestAllocations() {
    setState(() {
      allocations.clear();
      remainingIncome = widget.income;

      double totalAllocated = 0.0;

      for (var category in selectedCategories) {
        double allocatedAmount = widget.income * (allocationPercentages[category.name] ?? 0.0);
        allocations[category.name] = allocatedAmount.toStringAsFixed(2);
        totalAllocated += allocatedAmount;
      }

      remainingIncome = widget.income - totalAllocated;
    });
  }



  void _showCategorySelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: EdgeInsets.all(16.0),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Select Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: ListView(
                      children: predefinedCategories.map((category) {
                        return CheckboxListTile(
                          title: Text(category.name),
                          value: selectedCategories.contains(category),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedCategories.add(category);
                              } else {
                                selectedCategories.remove(category);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _suggestAllocations(); // Recalculate allocations based on selected categories
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
        title: Text('Allocate Your Budget'),
        actions: [
          IconButton(
            icon: Icon(Icons.auto_awesome),
            onPressed: _suggestAllocations,
          ),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _showCategorySelection,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Remaining Income: \$${remainingIncome.toStringAsFixed(2)}'),
            Expanded(
              child: ListView.builder(
                itemCount: selectedCategories.length,
                itemBuilder: (context, index) {
                  final category = selectedCategories[index];
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
                        controller: TextEditingController(
                          text: allocations[category.name] ?? '',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EnvelopeBudgetingPage(
                      allocations: allocations.map((key, value) => MapEntry(key, double.tryParse(value) ?? 0.0)),
                    ),
                  ),
                );

              },
              child: Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: IncomeInputPage(),
  ));
}
