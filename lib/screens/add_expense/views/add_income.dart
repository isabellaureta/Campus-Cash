import 'package:expense_repository/expense_repository.dart';
import 'package:expenses_tracker/screens/add_expense/blocs/create_expense_bloc/create_expense_bloc.dart';
import 'package:expenses_tracker/screens/add_expense/blocs/get_categories_bloc/get_categories_bloc.dart';
import 'package:expenses_tracker/screens/add_expense/views/category_creation2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AddIncome extends StatefulWidget {
  const AddIncome({super.key});

  @override
  State<AddIncome> createState() => _AddIncomeState();
}

class _AddIncomeState extends State<AddIncome> {
  TextEditingController incomeController = TextEditingController();
  TextEditingController category2Controller = TextEditingController();
  TextEditingController dateController = TextEditingController();
  // DateTime selectDate = DateTime.now();
  late Income income;
  bool isLoading = false;

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
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(
                              FontAwesomeIcons.dollarSign,
                              size: 16,
                              color: Colors.grey,
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 32,
                      ),
                      TextFormField(
                        controller: category2Controller,
                        textAlignVertical: TextAlignVertical.center,
                        readOnly: true,
                        onTap: () {},
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: income.category2 == Category2.empty ? Colors.white : Color(income.category2.color),
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
                                var newCategory2 = await getCategoryCreation2(context);
                                setState(() {
                                  state.categories2.insert(0, newCategory2);
                                });
                              },
                              icon: const Icon(
                                FontAwesomeIcons.plus,
                                size: 16,
                                color: Colors.grey,
                              )
                          ),
                          hintText: 'Category2',
                          border: const OutlineInputBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12)), borderSide: BorderSide.none),
                        ),
                      ),
                      Container(
                        height: 200,
                        width: MediaQuery.of(context).size.width,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                        ),
                        child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ListView.builder(
                                itemCount: state.categories2.length,
                                itemBuilder: (context, int i) {
                                  return Card(
                                    child: ListTile(
                                      onTap: () {
                                        setState(() {
                                          income.category2 = state.categories2[i];
                                          category2Controller.text = income.category2.name;
                                        });
                                      },
                                      leading: Image.asset(
                                        'assets/${state.categories2[i].icon}.png',
                                        scale: 2,
                                      ),
                                      title: Text(state.categories2[i].name),
                                      tileColor: Color(state.categories2[i].color),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () {
                                          // Dispatch delete category event
                                          context.read<GetCategoriesBloc2>().add(DeleteCategory2(state.categories2[i]));
                                        },
                                      ),
                                    ),
                                  );
                                }
                            )
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
                          DateTime? newDate = await showDatePicker(context: context, initialDate: income.date, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));

                          if (newDate != null) {
                            setState(() {
                              dateController.text = DateFormat('dd/MM/yyyy').format(newDate);
                              // selectDate = newDate;
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
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
