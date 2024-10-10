import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_repository/repositories.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'envelope_records.dart';

class Envelope {
  final Category category;
  String allocatedBudget;
  String remainingBudget;

  Envelope({
    required this.category,
    required this.allocatedBudget,
    required this.remainingBudget,
  });
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
  bool isSaving = false;
  String? warningMessage;

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

  @override
  void initState() {
    super.initState();
    remainingIncome = widget.income;

    for (var category in filteredCategories) {
      _controllers[category.name] = TextEditingController();
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

      remainingIncome = widget.income - totalAllocated;

      if (remainingIncome < 0) {
        warningMessage = 'Exceeding remaining income';
      } else {
        warningMessage = null; // Clear the warning message if within limits
      }
    });
  }

  void _showCategorySelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
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
                            modalSetState(() {
                              if (value == true) {
                                selectedCategories.add(category);
                              } else {
                                selectedCategories.remove(category);

                                // Clear the allocation and controller for unselected categories
                                _controllers[category.name]?.clear();
                                allocations.remove(category.name);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Update the main state when Done is pressed
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

  Future<void> _saveToFirestore() async {
    setState(() {
      isSaving = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');

      String userId = user.uid;

      DocumentReference userDocRef = FirebaseFirestore.instance.collection('envelopeAllocations').doc(userId);

      Map<String, double> validAllocations = {};
      for (var entry in allocations.entries) {
        if (entry.value.isNotEmpty && double.tryParse(entry.value) != null) {
          // Find the category by name
          Category? category = predefinedCategories.firstWhere((cat) => cat.name == entry.key);

          // Parse the allocated amount
          double allocatedAmount = double.tryParse(entry.value) ?? 0.0;

          // Remaining budget is the same as allocated budget initially
          double remainingBudget = allocatedAmount;

          // Save to Firestore
          await userDocRef.collection('envelopes').doc(category.categoryId).set({
            'categoryName': category.name,
            'categoryId': category.categoryId,
            'allocatedAmount': allocatedAmount,
            'remainingBudget': remainingBudget,
          });

          // Include only categories with valid allocation amounts
          validAllocations[category.name] = allocatedAmount;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Allocations saved successfully!')),
      );

      // Navigate to the EnvelopeBudgetingPage with filtered allocations
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EnvelopeBudgetingPage(
            allocations: validAllocations,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save allocations: $e')),
      );
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Allocate Your Budget'),
        actions: [
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
            Text('Remaining Income: \₱${remainingIncome.toStringAsFixed(2)}',
                style: TextStyle(
                  color: remainingIncome < 0 ? Colors.red : Colors.black, // Change color if exceeding
                )
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
                        controller: _controllers[category.name],
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: (isSaving || remainingIncome < 0) ? null : _saveToFirestore,
              child: isSaving ? CircularProgressIndicator() : Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}

