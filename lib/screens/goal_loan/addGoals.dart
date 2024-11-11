import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddGoalPage extends StatefulWidget {
  @override
  _AddGoalPageState createState() => _AddGoalPageState();
}

class _AddGoalPageState extends State<AddGoalPage> {
  Color _selectedColor = Colors.red.shade100;
  double _goalAmount = 0.0;
  String _selectedFrequency = 'Daily';
  DateTime? _endDate;
  double _requiredSavings = 0.0;
  double _savedAmount = 0.0;
  final TextEditingController _goalNameController = TextEditingController();

  final List<Color> _defaultColors = [
    Colors.red.shade100,
    Colors.green.shade100,
    Colors.blue.shade100,
    Colors.yellow.shade100,
    Colors.purple.shade100,
    Colors.orange.shade100,
    Colors.pink.shade100,
    Colors.teal.shade100,
    Colors.blueGrey.shade100,
    Colors.cyan.shade100
  ];

  final List<String> _frequencies = ['Daily', 'Weekly', 'Monthly'];

  void _chooseColor() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pick a color'),
          content: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _defaultColors.map((color) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                  });
                  Navigator.of(context).pop();
                },
                child: CircleAvatar(
                  backgroundColor: color,
                  radius: 20,
                  child: _selectedColor == color
                      ? Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _pickEndDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _calculateRequiredSavings(); // Call the function to calculate savings
      });
    }
  }

  void _calculateRequiredSavings() {
    if (_endDate == null || _goalAmount <= 0) return;

    final duration = _endDate!.difference(DateTime.now());
    int periods;

    switch (_selectedFrequency) {
      case 'Daily':
        periods = duration.inDays;
        break;
      case 'Weekly':
        periods = (duration.inDays / 7).ceil();
        break;
      case 'Monthly':
        periods = (duration.inDays / 30).ceil();
        break;
      default:
        periods = 0;
    }

    setState(() {
      _requiredSavings = periods > 0 ? _goalAmount / periods : 0;
    });
  }

  Future<void> _saveGoal() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('goals')
          .doc(user.uid)
          .collection('userGoals') // Separate collection for each user's goals
          .add({
        'goalName': _goalNameController.text,
        'color': _selectedColor.value.toRadixString(16), // Store color as hex
        'goalAmount': _goalAmount,
        'savedAmount': _savedAmount,
        'frequency': _selectedFrequency, // Save selected frequency
        'endDate': _endDate,
        'requiredSavings': _requiredSavings, // Save calculated required savings
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Goal saved successfully')),
      );

      Navigator.pop(context); // Exit the page after saving
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save goal: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Goal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              TextField(
                controller: _goalNameController,
                decoration: InputDecoration(
                  labelText: 'Goal Name',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(width: 3.0),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(width: 3.0, color: Colors.grey),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(width: 3.0, color: Colors.blue),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
                  labelStyle: TextStyle(fontSize: 18),
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: _selectedColor,
                  ),
                  SizedBox(width: 20),
                  IconButton(
                    icon: Icon(Icons.color_lens, color: _selectedColor),
                    onPressed: _chooseColor,
                  ),
                ],
              ),
              SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Goal Amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _goalAmount = double.tryParse(value) ?? 0.0;
                  });
                },
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedFrequency,
                items: _frequencies.map((frequency) {
                  return DropdownMenuItem(
                    value: frequency,
                    child: Text(frequency),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFrequency = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Frequency',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: _pickEndDate,
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(width: 1, color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'End Date: ${_endDate != null ? DateFormat.yMd().format(_endDate!) : 'Select a date'}',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              if (_requiredSavings > 0) // Only show if there’s a required savings amount
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'You need to save ₱${_requiredSavings.toStringAsFixed(2)} $_selectedFrequency to reach your goal',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveGoal,
                child: Text('Set Goal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
