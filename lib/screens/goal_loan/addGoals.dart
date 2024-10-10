import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddGoalPage extends StatefulWidget {
  @override
  _AddGoalPageState createState() => _AddGoalPageState();
}

class _AddGoalPageState extends State<AddGoalPage> {
  IconData _selectedIcon = FontAwesomeIcons.user; // Default icon as an IconData
  Color _selectedColor = Colors.green;
  double _goalAmount = 0.0;
  double _savedAmount = 0.0;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  final TextEditingController _goalNameController = TextEditingController();

  void _chooseIcon() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 200,
          child: GridView.builder(
            itemCount: icons.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
            ),
            itemBuilder: (BuildContext context, int index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIcon = icons[index]; // Directly store the selected IconData
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 3,
                      color: _selectedIcon == icons[index]
                          ? Colors.green
                          : Colors.grey,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icons[index], size: 30, color: _selectedColor), // Display the Font Awesome icon
                ),
              );
            },
          ),
        );
      },
    );
  }


  void _chooseColor() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (Color color) {
                setState(() {
                  _selectedColor = color;
                });
              },
              showLabel: false,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Select'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
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
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
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
      'iconCodePoint': _selectedIcon.codePoint, // Store codePoint of the icon
      'iconFontFamily': _selectedIcon.fontFamily, // Store fontFamily of the icon
      'color': _selectedColor.value.toRadixString(16),
      'goalAmount': _goalAmount,
      'savedAmount': _savedAmount,
      'startDate': _startDate,
      'endDate': _endDate,
    });
    Navigator.pop(context);
  }





  final List<IconData> icons = [
    FontAwesomeIcons.car,
    FontAwesomeIcons.home,
    FontAwesomeIcons.bicycle,
    FontAwesomeIcons.camera,
    FontAwesomeIcons.coffee,
    FontAwesomeIcons.heart,
    FontAwesomeIcons.user,
    FontAwesomeIcons.shoppingCart,
    FontAwesomeIcons.wallet,
    FontAwesomeIcons.umbrella,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Goal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Container(
              height: 70, // Adjust the height as needed
              child: TextField(
                controller: _goalNameController,
                decoration: InputDecoration(
                  labelText: 'Goal Name',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(width: 3.0), // Set the width of the border
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(width: 3.0, color: Colors.grey), // Set the width and color of the border when enabled
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(width: 3.0, color: Colors.blue), // Set the width and color of the border when focused
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0), // Adjust the vertical padding
                  labelStyle: TextStyle(fontSize: 18),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                GestureDetector(
                  onTap: _chooseIcon,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: _selectedColor,
                    child: Icon(
                      _selectedIcon, // Directly use IconData, no need for int.parse
                      size: 30,
                      color: Colors.white, // Adjust the icon color if needed
                    ),
                  ),
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
            Spacer(),
            ElevatedButton(
              onPressed: _saveGoal,
              child: Text('Set Goal'),
            ),
          ],
        ),
      ),
    );
  }
}
