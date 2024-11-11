import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_repository/repositories.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../blocs/create_expense_bloc/create_expense_bloc.dart';
import 'category_creation.dart';

class AddExpense extends StatefulWidget {
  const AddExpense({super.key});

  @override
  State<AddExpense> createState() => _AddExpenseState();
}

class _AddExpenseState extends State<AddExpense> {
  TextEditingController expenseController = TextEditingController();
  TextEditingController categoryController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  late Expense expense;
  bool isLoading = false;

  bool isRecurring = false;
  String selectedFrequency = 'Weekly';
  TextEditingController startDateController = TextEditingController();
  TextEditingController endDateController = TextEditingController();
  bool noEndDate = false;

  @override
  void initState() {
    dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    expense = Expense.empty;
    expense.expenseId = const Uuid().v1();
    super.initState();
  }

  Future<bool> checkIfBudgetExists(String userId) async {
    final firestore = FirebaseFirestore.instance;

    // Define the document references for each required budgeting technique
    final budgetDoc = firestore.collection('budgets').doc(userId);
    final budgetingDoc503020 = firestore.collection('503020').doc(userId);
    final envelopeAllocationsDoc = firestore.collection('envelopeAllocations').doc(userId);
    final payYourselfFirstDoc = firestore.collection('PayYourselfFirst').doc(userId);
    final priorityBasedDoc = firestore.collection('PriorityBased').doc(userId);

    // Check each document for existence
    final budgetSnapshot = await budgetDoc.get();
    final budgeting503020Snapshot = await budgetingDoc503020.get();
    final envelopeAllocationsSnapshot = await envelopeAllocationsDoc.get();
    final payYourselfFirstSnapshot = await payYourselfFirstDoc.get();
    final priorityBasedSnapshot = await priorityBasedDoc.get();

    // Return true if at least one budgeting technique exists, false if all are missing
    return budgetSnapshot.exists ||
        budgeting503020Snapshot.exists ||
        envelopeAllocationsSnapshot.exists ||
        payYourselfFirstSnapshot.exists ||
        priorityBasedSnapshot.exists;
  }


  void showAlertDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Notice'),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateExpenseBloc, CreateExpenseState>(
      listener: (context, state) {
        if (state is CreateExpenseSuccess) {
          Navigator.pop(context, expense);
        } else if (state is CreateExpenseLoading) {
          setState(() {
            isLoading = true;
          });
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.background,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Add Expense",
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: TextFormField(
                      controller: expenseController,
                      textAlignVertical: TextAlignVertical.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(
                          FontAwesomeIcons.pesoSign,
                          size: 16,
                          color: Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 32,
                  ),

                  TextFormField(
                    controller: categoryController,
                    textAlignVertical: TextAlignVertical.center,
                    readOnly: true,
                    onTap: () {},
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: expense.category == Category.empty
                          ? Colors.white
                          : Color(expense.category.color),
                      prefixIcon: expense.category == Category.empty
                          ? const Icon(
                        FontAwesomeIcons.list,
                        size: 16,
                        color: Colors.grey,
                      )
                          : Image.asset(
                        '${expense.category.icon}',
                        scale: 2,
                      ),
                      suffixIcon: IconButton(
                          onPressed: () async {
                            var newCategory = await getCategoryCreation(context);
                            setState(() {
                              predefinedCategories.insert(0, newCategory);
                            });
                          },
                          icon: const Icon(
                            FontAwesomeIcons.plus,
                            size: 16,
                            color: Colors.grey,
                          )),
                      hintText: 'Category',
                      border: const OutlineInputBorder(
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(12)),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  Container(
                    height: 400,
                    width: MediaQuery.of(context).size.width,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(12)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5, // Number of columns
                          mainAxisSpacing: 10.0,
                          crossAxisSpacing: 11.0,
                          childAspectRatio: 0.5, // Adjust the item height
                        ),
                        itemCount: predefinedCategories.length,
                        itemBuilder: (context, int i) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                expense.category = predefinedCategories[i];
                                categoryController.text = expense.category.name;
                              });
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Color(predefinedCategories[i].color),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.asset(
                                      '${predefinedCategories[i].icon}',
                                      fit: BoxFit.contain,
                                      height: 50,
                                      width: 50,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Center(
                                  child: Text(
                                    predefinedCategories[i].name,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  TextFormField(
                    controller: dateController,
                    textAlignVertical: TextAlignVertical.center,
                    readOnly: true,
                    onTap: () async {
                      DateTime? newDate = await showDatePicker(
                          context: context,
                          initialDate: expense.date,
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365)));

                      if (newDate != null) {
                        setState(() {
                          dateController.text =
                              DateFormat('dd/MM/yyyy').format(newDate);
                          expense.date = newDate;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(
                        FontAwesomeIcons.clock,
                        size: 16,
                        color: Colors.grey,
                      ),
                      hintText: 'Date',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  TextFormField(
                    controller: descriptionController,
                    textAlignVertical: TextAlignVertical.center,
                    maxLines: 3,  // Allows multi-line input
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(
                        FontAwesomeIcons.pen,
                        size: 16,
                        color: Colors.grey,
                      ),
                      hintText: 'Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  CheckboxListTile(
                    title: Text("Set as recurring"),
                    value: isRecurring,
                    onChanged: (value) {
                      setState(() {
                        isRecurring = value ?? false;
                      });
                    },
                  ),

                  if (isRecurring) ...[
                    DropdownButtonFormField<String>(
                      value: selectedFrequency,
                      items: [
                        'Daily',
                        'Weekly',
                        'Semi-monthly',
                        'Monthly',
                        'Quarterly',
                        'Semi-annually',
                        'Annually'
                      ]
                          .map((frequency) => DropdownMenuItem(
                        value: frequency,
                        child: Text(frequency),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedFrequency = value!;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Frequency',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),

                    // Start Date Picker
                    TextFormField(
                      controller: startDateController,
                      readOnly: true,
                      onTap: () async {
                        DateTime? newStartDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (newStartDate != null) {
                          startDateController.text =
                              DateFormat('dd/MM/yyyy').format(newStartDate);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Starts on',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),

                    // End Date Picker
                    TextFormField(
                      controller: endDateController,
                      readOnly: true,
                      enabled: !noEndDate,
                      onTap: () async {
                        DateTime? newEndDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (newEndDate != null) {
                          endDateController.text =
                              DateFormat('dd/MM/yyyy').format(newEndDate);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Ends on',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    CheckboxListTile(
                      title: Text("Set end date to never"),
                      value: noEndDate,
                      onChanged: (value) {
                        setState(() {
                          noEndDate = value ?? false;
                        });
                      },
                    ),
                  ],

                  SizedBox(
                    width: double.infinity,
                    height: kToolbarHeight,
                    child: isLoading
                        ? const Center(
                        child: CircularProgressIndicator())
                        : TextButton(
                        onPressed: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            log('No authenticated user found.');
                            return;
                          }

                          // Check if budget exists before proceeding
                          final expenseExists = await checkIfBudgetExists(user.uid);


                          // Parse the expense amount entered by the user
                          double expenseAmount = double.tryParse(expenseController.text) ?? 0.0;



                          // Update the expense amount in the state if within budget
                          setState(() {
                            expense.amount = expenseAmount.toInt();
                            expense.description = descriptionController.text;  // Set description from the controller

                          });

                          // Prepare recurring options if the expense is marked as recurring
                          final String? frequency = isRecurring ? selectedFrequency : null;
                          final DateTime? startDate = isRecurring && startDateController.text.isNotEmpty
                              ? DateFormat('dd/MM/yyyy').parse(startDateController.text)
                              : null;
                          final DateTime? endDate = isRecurring && !noEndDate && endDateController.text.isNotEmpty
                              ? DateFormat('dd/MM/yyyy').parse(endDateController.text)
                              : null;

                          // Add the expense event to the Bloc
                          context.read<CreateExpenseBloc>().add(
                            CreateExpense(
                              expense: expense,
                              isRecurring: isRecurring,
                              frequency: frequency,
                              startDate: startDate,
                              endDate: endDate,
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                              fontSize: 22, color: Colors.white),
                        )),
                  )

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<double> _fetchRemainingBudget(String userId) async {
    // Fetch the remaining budget from Firestore
    DocumentSnapshot budgetDoc = await FirebaseFirestore.instance
        .collection('budgets')
        .doc(userId)
        .get();

    return budgetDoc.exists ? (budgetDoc['remaining'] ?? 0).toDouble() : 0.0;
  }

  Future<void> _attemptCreateExpense() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      log('No authenticated user found.');
      return;
    }

    final expenseExists = await checkIfBudgetExists(user.uid);


    // Retrieve remaining budget
    double remainingBudget = await _fetchRemainingBudget(user.uid);

    // Get the expense amount from the controller and parse to double
    double expenseAmount = double.parse(expenseController.text);

    // Check if the expense exceeds the remaining budget
    if (expenseAmount > remainingBudget) {
      showAlertDialog(context, 'Expense exceeds your remaining budget of ₱${remainingBudget.toStringAsFixed(2)}.');
      return;
    }

    // Set expense amount in state and prepare additional details for recurring expenses
    setState(() {
      expense.amount = expenseAmount.toInt();
    });

    final String? frequency = isRecurring ? selectedFrequency : null;
    final DateTime? startDate = isRecurring && startDateController.text.isNotEmpty
        ? DateFormat('dd/MM/yyyy').parse(startDateController.text)
        : null;
    final DateTime? endDate = isRecurring && !noEndDate && endDateController.text.isNotEmpty
        ? DateFormat('dd/MM/yyyy').parse(endDateController.text)
        : null;

    // Dispatch the CreateExpense event to the bloc
    context.read<CreateExpenseBloc>().add(
      CreateExpense(
        expense: expense,
        isRecurring: isRecurring,
        frequency: frequency,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }
}
