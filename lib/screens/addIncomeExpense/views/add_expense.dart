import 'package:expense_repository/repositories.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../blocs/create_expense_bloc/create_expense_bloc.dart';
import '../blocs/get_categories_bloc/get_categories_bloc.dart';
import '../views/category_creation2.dart';
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
  late Expense expense;
  bool isLoading = false;

  final List<Category> predefinedCategories = [
    Category(icon: 'Education', name: 'Education', color: 0xFFE57373, categoryId: '011'),
    Category(icon: 'Tuition Fees', name: 'Tuition Fees', color: 0xFF81C784, categoryId: '012'),
    Category(icon: 'School Supplies', name: 'School Supplies', color: 0xFF64B5F6, categoryId: '013'),
    Category(icon: 'Subscriptions', name: 'Subscriptions', color: 0xFFFFD54F, categoryId: '014'),
    Category(icon: 'Public Transpo', name: 'Public Transpo', color: 0xFFBA68C8, categoryId: '015'),
    Category(icon: 'Booked Transpo', name: 'Booked Transpo', color: 0xFF4DB6AC, categoryId: '016'),
    Category(icon: 'House', name: 'House', color: 0xFFAED581, categoryId: '017'),
    Category(icon: 'Utilities', name: 'Utilities', color: 0xFF7986CB, categoryId: '018'),

    Category(icon: 'Laundry', name: 'Laundry', color: 0xFF7986CB, categoryId: '019'),
    Category(icon: 'Family', name: 'Family', color: 0xFF7986CB, categoryId: '021'),
    Category(icon: 'Load', name: 'Load', color: 0xFF7986CB, categoryId: '022'),
    Category(icon: 'Groceries', name: 'Groceries', color: 0xFF7986CB, categoryId: '023'),
    Category(icon: 'Fitness', name: 'Fitness', color: 0xFF7986CB, categoryId: '024'),
    Category(icon: 'Dining', name: 'Dining', color: 0xFF7986CB, categoryId: '025'),
    Category(icon: 'Meals', name: 'Meals', color: 0xFF7986CB, categoryId: '026'),

    Category(icon: 'Snacks', name: 'Snacks/Coffee', color: 0xFF7986CB, categoryId: '027'),
    Category(icon: 'Printing', name: 'Printing', color: 0xFF7986CB, categoryId: '028'),
    Category(icon: 'Organizations', name: 'Organizations', color: 0xFF7986CB, categoryId: '029'),
    Category(icon: 'Online Courses', name: 'Online Courses', color: 0xFF7986CB, categoryId: '031'),
    Category(icon: 'School Events', name: 'School Events', color: 0xFF7986CB, categoryId: '032'),
    Category(icon: 'Sports', name: 'Sports', color: 0xFF7986CB, categoryId: '033'),
    Category(icon: 'Shopping', name: 'Shopping', color: 0xFF7986CB, categoryId: '034'),
    Category(icon: 'Online Shopping', name: 'Online Shopping', color: 0xFF7986CB, categoryId: '035'),
    Category(icon: 'Friends', name: 'Friends', color: 0xFF7986CB, categoryId: '036'),

    Category(icon: 'Entertainment', name: 'Entertainment', color: 0xFF7986CB, categoryId: '037'),
    Category(icon: 'Medical', name: 'Medical', color: 0xFF7986CB, categoryId: '038'),
    Category(icon: 'Insurance', name: 'Insurance', color: 0xFF7986CB, categoryId: '039'),
    Category(icon: 'Savings', name: 'Savings', color: 0xFF7986CB, categoryId: '041'),
    Category(icon: 'Investments', name: 'Investments', color: 0xFF7986CB, categoryId: '042'),
    Category(icon: 'Credit Cards', name: 'Credit Cards', color: 0xFF7986CB, categoryId: '043'),
    Category(icon: 'Gifts', name: 'Gifts', color: 0xFF7986CB, categoryId: '044'),
    Category(icon: 'Travel', name: 'Travel', color: 0xFF7986CB, categoryId: '045'),
    Category(icon: 'Outings', name: 'Outings', color: 0xFF7986CB, categoryId: '046'),

    Category(icon: 'Gas', name: 'Gas', color: 0xFF7986CB, categoryId: '047'),
    Category(icon: 'Vehicle', name: 'Vehicle', color: 0xFF7986CB, categoryId: '048'),
    Category(icon: 'Loans', name: 'Loans', color: 0xFF7986CB, categoryId: '049'),
    Category(icon: 'Partner', name: 'Partner', color: 0xFF7986CB, categoryId: '051'),
    Category(icon: 'Business', name: 'Business', color: 0xFF7986CB, categoryId: '052'),
    Category(icon: 'Personal Care', name: 'Personal Care', color: 0xFF7986CB, categoryId: '053'),
    Category(icon: 'Clothing', name: 'Clothing', color: 0xFF7986CB, categoryId: '054'),
    Category(icon: 'Others', name: 'Others', color: 0xFF7986CB, categoryId: '055'),
  ];

  @override
  void initState() {
    dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    expense = Expense.empty;
    expense.expenseId = const Uuid().v1();
    super.initState();
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
                        'assets/${expense.category.icon}.png',
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
                                      'assets/${predefinedCategories[i].icon}.png',
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
                    height: 32,
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: kToolbarHeight,
                    child: isLoading
                        ? const Center(
                        child: CircularProgressIndicator())
                        : TextButton(
                        onPressed: () {
                          setState(() {
                            expense.amount = int.parse(
                                expenseController.text);
                          });

                          context
                              .read<CreateExpenseBloc>()
                              .add(CreateExpense(expense));
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
