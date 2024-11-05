import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddGoalPage extends StatefulWidget {
  @override
  _AddGoalPageState createState() => _AddGoalPageState();
}

class _AddGoalPageState extends State<AddGoalPage> {
  Color _selectedColor = Colors.red.shade100;
  double _goalAmount = 0.0;
  double _savedAmount = 0.0;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
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

  void _chooseColor() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pick a color'),
          content: Wrap(
            spacing: 10, // Spacing between color options
            runSpacing: 10,
            children: _defaultColors.map((color) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = color;
                  });
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: CircleAvatar(
                  backgroundColor: color,
                  radius: 20,
                  child: _selectedColor == color
                      ? Icon(Icons.check, color: Colors.white)
                      : null, // Show checkmark if selected
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _pickStartDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  void _pickEndDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),  // Default to the current date
      firstDate: DateTime.now(),    // Disallow past dates
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }


  Future<void> _saveGoal() async {
    await FirebaseFirestore.instance.collection('goals').add({
      'goalName': _goalNameController.text,
      'color': _selectedColor.value.toRadixString(16), // Store color
      'goalAmount': _goalAmount,
      'savedAmount': _savedAmount,
      'startDate': _startDate,
      'endDate': _endDate,
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Goal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Make the entire content scrollable
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Container(
                height: 70,
                child: TextField(
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
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: _selectedColor, // Show selected color
                  ),
                  SizedBox(width: 20),
                  IconButton(
                    icon: Icon(Icons.color_lens, color: _selectedColor), // Color picker button
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
              TextField(
                decoration: InputDecoration(
                  labelText: 'Already Saved Amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _savedAmount = double.tryParse(value) ?? 0.0;
                  });
                },
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: _pickStartDate,
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(width: 1, color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Start Date: ${DateFormat.yMd().format(_startDate)}',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              SizedBox(height: 10),
              GestureDetector(
                onTap: _pickEndDate,
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(width: 1, color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'End Date: ${_endDate != null ? DateFormat.yMd().format(_endDate!) : 'Until Forever'}',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Goal ₱${_goalAmount.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              LinearProgressIndicator(
                value: _goalAmount > 0 ? _savedAmount / _goalAmount : 0,
                minHeight: 20,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              SizedBox(height: 10),
              Text(
                'Saved: ₱${_savedAmount.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 18),
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
