import 'package:expense_repository/repositories.dart';
import 'package:campuscash/screens/addIncomeExpense/blocs/create_expense_bloc/create_expense_bloc.dart';
import 'package:campuscash/screens/addIncomeExpense/blocs/get_categories_bloc/get_categories_bloc.dart';
import 'package:campuscash/screens/addIncomeExpense/views/category_creation2.dart';
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

  final List<Category2> predefinedCategories = [
  Category2(icon: 'Allowance', name: 'Allowance', color: 0xFFE57373, categoryId2: '011'),
  Category2(icon: 'Scholarship', name: 'Scholarship', color: 0xFF81C784, categoryId2: '022'),
  Category2(icon: 'Grants', name: 'Grants', color: 0xFF64B5F6, categoryId2: '033'),
  Category2(icon: 'Part-Time Job', name: 'Part-Time Job', color: 0xFFFFD54F, categoryId2: '044'),
  Category2(icon: 'Freelance', name: 'Freelance', color: 0xFFBA68C8, categoryId2: '055'),
  Category2(icon: 'Stipends', name: 'Stipends', color: 0xFF4DB6AC, categoryId2: '066'),
  Category2(icon: 'Salary', name: 'Salary', color: 0xFFAED581, categoryId2: '077'),
  Category2(icon: 'Internships', name: 'Internships', color: 0xFF7986CB, categoryId2: '088'),
  Category2(icon: 'Loans', name: 'Loans', color: 0xFF4DB6AC, categoryId2: '066'),
  Category2(icon: 'Savings', name: 'Savings', color: 0xFF4DB6AC, categoryId2: '066'),
  Category2(icon: 'Gifts', name: 'Gifts', color: 0xFF4DB6AC, categoryId2: '066'),
  Category2(icon: 'Awards', name: 'Awards', color: 0xFF4DB6AC, categoryId2: '066'),
  Category2(icon: 'Investments', name: 'Investments', color: 0xFF4DB6AC, categoryId2: '066'),
  Category2(icon: 'Business', name: 'Business', color: 0xFF4DB6AC, categoryId2: '066'),
  Category2(icon: 'Refunds', name: 'Refunds', color: 0xFF4DB6AC, categoryId2: '066'),
  Category2(icon: 'Crypto', name: 'Crypto', color: 0xFF4DB6AC, categoryId2: '066'),
  Category2(icon: 'Pre-owned Sales', name: 'Pre-owned Sales', color: 0xFF4DB6AC, categoryId2: '066'),
  Category2(icon: 'Others', name: 'Others', color: 0xFF4DB6AC, categoryId2: '066'),
];

  @override
  void initState() {
    dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    income = Income.empty;
    income.incomeId = const Uuid().v1();
    super.initState();
  }





  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateIncomeBloc, CreateIncomeState>(
      listener: (context, state) {
        if(state is CreateIncomeSuccess) {
          Navigator.pop(context, income);
        } else if(state is CreateIncomeLoading) {
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
          body: BlocBuilder<GetCategoriesBloc2, GetCategoriesState2>(
            builder: (context, state) {
              if (state is GetCategoriesSuccess2) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Add Income",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
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
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                              'assets/${income.category2.icon}.png',
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
                                      income.category2 = predefinedCategories[i];
                                      categoryController.text = income.category2.name;
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
                              ? const Center(child: CircularProgressIndicator())
                              : TextButton(
                              onPressed: () {
                                setState(() {
                                  income.amount = int.parse(incomeController.text);
                                });

                                context.read<CreateIncomeBloc>().add(CreateIncome(income));
                              },
                              style: TextButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: const Text(
                                'Save',
                                style: TextStyle(fontSize: 22, color: Colors.white),
                              )
                          ),
                        ),


                      ],
                    ),
                  ),
                );
              } else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
