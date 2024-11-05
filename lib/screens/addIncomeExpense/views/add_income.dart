import 'dart:developer';

import 'package:campuscash/screens/addIncomeExpense/blocs/create_expense_bloc/create_expense_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_repository/repositories.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'category_creation.dart';

class AddIncome extends StatefulWidget {
  const AddIncome({super.key});

  @override
  State<AddIncome> createState() => _AddIncomeState();
}

class _AddIncomeState extends State<AddIncome> {
  TextEditingController incomeController = TextEditingController();
  TextEditingController categoryController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  late Income income;
  bool isLoading = false;

  @override
  void initState() {
    dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    income = Income.empty;
    income.incomeId = const Uuid().v1();
    super.initState();
  }

  Future<bool> checkIfBudgetExists(String userId) async {
    final firestore = FirebaseFirestore.instance;

    // Define the document references for each required budget technique
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
    return BlocListener<CreateIncomeBloc, CreateIncomeState>(
      listener: (context, state) {
        if (state is CreateIncomeSuccess) {
          Navigator.pop(context, income);
        } else if (state is CreateIncomeLoading) {
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
                    "Add Income",
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: TextFormField(
                      controller: incomeController,
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
                      fillColor: income.category2 == Category2.empty
                          ? Colors.white
                          : Color(income.category2.color),
                      prefixIcon: income.category2 == Category2.empty
                          ? const Icon(
                        FontAwesomeIcons.list,
                        size: 16,
                        color: Colors.grey,
                      )
                          : Image.asset(
                        '${income.category2.icon}',
                        scale: 2,
                      ),
                      suffixIcon: IconButton(
                          onPressed: () async {
                            var newCategory = await getCategoryCreation(context);
                            setState(() {
                              predefinedCategories2.insert(0, newCategory);
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
                        itemCount: predefinedCategories2.length,
                        itemBuilder: (context, int i) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                income.category2 = predefinedCategories2[i];
                                categoryController.text = income.category2.name;
                              });
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Color(predefinedCategories2[i].color),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.asset(
                                      '${predefinedCategories2[i].icon}',
                                      fit: BoxFit.contain,
                                      height: 50,
                                      width: 50,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Center(
                                  child: Text(
                                    predefinedCategories2[i].name,
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
                          initialDate: income.date,
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365)));

                      if (newDate != null) {
                        setState(() {
                          dateController.text =
                              DateFormat('dd/MM/yyyy').format(newDate);
                          income.date = newDate;
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
                    height: 32,
                  ),
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

                          // Check if any budget or budgeting technique document exists
                          final budgetExists = await checkIfBudgetExists(user.uid);
                          if (!budgetExists) {
                            // Show alert if no budgeting technique exists
                            showAlertDialog(context, 'Please add a Budget or Budgeting Technique first.');
                            return;
                          }

                          // If a budget document exists, proceed with saving the income
                          setState(() {
                            income.amount = int.parse(incomeController.text);
                          });

                          context.read<CreateIncomeBloc>().add(CreateIncome(income));
                        },


                        style: TextButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(12))),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                              fontSize: 22, color: Colors.white),
                        )),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
