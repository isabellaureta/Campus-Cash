import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../screens/goal/flutter_toast.dart';
import '../../screens/goal/button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../screens/goal/text_field.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _AddNewGoalScreenState();
}

class _AddNewGoalScreenState extends State<GoalScreen> {
  TextEditingController dateController = TextEditingController();

  final DatabaseReference stocksRef = FirebaseDatabase.instance.ref().child('stocks');

  final user = FirebaseAuth.instance.currentUser!;
  final amountController = TextEditingController();
  final nameController = TextEditingController();

  String? checkValid(value) {
    if (value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return OrientationBuilder(
              builder: (BuildContext context, Orientation orientation) {
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                    child: Form(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: constraints.maxWidth * 0.03,
                              ),
                              const Text(
                                'Add new goal',
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                    fontSize: 28, fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: constraints.maxHeight * 0.01,
                          ),
                          Text(
                            'Goal name',
                            style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500),
                          ),
                          SizedBox(
                            height: constraints.maxHeight * 0.02,
                          ),
                          CustomTextField(
                            hint: 'Goal',
                            iconName: Icons.description,
                            controller: nameController,
                            validator: checkValid,
                            keyboardType: TextInputType.text,
                          ),
                          SizedBox(
                            height: constraints.maxHeight * 0.02,
                          ),
                          Text(
                            'Target amount',
                            style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500),
                          ),
                          SizedBox(
                            height: constraints.maxHeight * 0.02,
                          ),
                          CustomTextField(
                              hint: 'Amount',
                              iconName: Icons.money,
                              controller: amountController,
                              validator: checkValid,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ]),

                          SizedBox(height: constraints.maxHeight * 0.02),
                          Text(
                            'Already saved',
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(
                            height: constraints.maxHeight * 0.02,
                          ),
                          CustomTextField(
                              hint: 'Amount',
                              iconName: Icons.money,
                              controller: amountController,
                              validator: checkValid,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ]),
                          SizedBox(height: constraints.maxHeight * 0.02),

                          Text(
                            'Target Date',
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: constraints.maxHeight * 0.02),

                          TextFormField(
                            controller: dateController,
                            textAlignVertical: TextAlignVertical.center,
                            readOnly: true,
                            onTap: () async {
                              DateTime? newDate = await showDatePicker(context: context,firstDate: DateTime.now(), lastDate: DateTime(2100),);
                              if (newDate != null) {
                                setState(() {
                                  dateController.text = DateFormat('dd/MM/yyyy').format(newDate);
                                  // selectDate = newDate;
                                });
                              }
                              },
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(
                                FontAwesomeIcons.calendar,
                                size: 16,
                                color: Colors.grey,
                              ),
                              hintText: 'Date',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),

                          SizedBox(
                            height: constraints.maxHeight * 0.05,
                          ),
                          TButton(
                            constraints: constraints,
                            btnColor: Theme.of(context).primaryColor,
                            btnText: 'Continue',
                            onPressed: () async {
                              // Show a dialog instead of ToastMessage
                              await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Success!'),
                                    content: const Text('Goal saved successfully!'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
