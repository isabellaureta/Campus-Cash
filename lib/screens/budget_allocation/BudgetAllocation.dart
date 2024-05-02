import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetAllocationScreen extends StatefulWidget {
  const BudgetAllocationScreen({super.key});

  @override
  _BudgetAllocationScreenState createState() => _BudgetAllocationScreenState();
}

class _BudgetAllocationScreenState extends State<BudgetAllocationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _incomeController = TextEditingController();
  final List<String> _expenseCategories = [
    'Housing',
    'Food',
    'Transportation',
    'Education',
    'Personal',
    'Health',
  ];
  final Map<String, double> _categoryAllocations = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Allocation'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _incomeController,
                  decoration: const InputDecoration(
                    labelText: 'Budget',
                    hintText: 'Enter your monthly income',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your monthly income';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Categories:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Column(
                  children: _buildExpenseCategoryFields(),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildExpenseCategoryFields() {
    return _expenseCategories.map((category) {
      return TextFormField(
        decoration: InputDecoration(
          labelText: category,
          hintText: 'Enter allocation for $category',
        ),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter allocation for $category';
          }
          return null;
        },
        onChanged: (value) {
          _categoryAllocations[category] = double.parse(value);
        },
      );
    }).toList();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Save data to Firebase Firestore
      _saveDataToFirestore();
    }
  }

  void _saveDataToFirestore() {
    // Replace this with your Firebase Firestore code to save data
    FirebaseFirestore.instance.collection('budget_allocations').add({
      'income': double.parse(_incomeController.text),
      'expense_allocations': _categoryAllocations,
    }).then((value) {
      // Data saved successfully
      print('Data saved to Firestore');
      // You can navigate to another screen or show a success message here
    }).catchError((error) {
      // Handle errors here
      print('Error saving data: $error');
      // You can show an error message to the user
    });
  }

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }
}

void main() {
  runApp(MaterialApp(
    home: BudgetAllocationScreen(),
  ));
}
