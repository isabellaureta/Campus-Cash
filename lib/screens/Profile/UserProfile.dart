import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../home/views/login_view.dart';
import 'Notifications.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _notificationsEnabled = false;
  String? _profileImageUrl;
  File? _imageFile;
  final NotificationHelper _notificationHelper = NotificationHelper();
  TimeOfDay _selectedTime = TimeOfDay(hour: 20, minute: 0);
  String _notificationFrequency = 'Daily'; // default to Daily
  int? _selectedDay; // Optional: day of the week (1 = Monday) or month (1-31)

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _nameController.text = userDoc['name'];
        _emailController.text = user.email!;
        _profileImageUrl = userDoc['profileImageUrl'];
        _notificationsEnabled = userDoc['notificationsEnabled'];
        _selectedTime = TimeOfDay(
          hour: (userDoc['notificationHour'] ?? 20) as int,
          minute: (userDoc['notificationMinute'] ?? 0) as int,
        );
        _notificationFrequency = userDoc['notificationFrequency'] ?? 'Daily';
        _selectedDay = userDoc['notificationDay'];
      });
      _updateNotificationSettings();
    }
  }

  Future<void> _updateUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'name': _nameController.text,
        'profileImageUrl': _profileImageUrl,
        'notificationsEnabled': _notificationsEnabled,
        'notificationHour': _selectedTime.hour,
        'notificationMinute': _selectedTime.minute,
        'notificationFrequency': _notificationFrequency,
        'notificationDay': _selectedDay,
      });
      if (_emailController.text != user.email) {
        await user.updateEmail(_emailController.text);
      }
      _updateNotificationSettings();
    }
  }

  void _updateNotificationSettings() {
    if (_notificationsEnabled) {
      _notificationHelper.scheduleNotification(
        _notificationFrequency,
        _selectedTime,
        _selectedDay,
      );
    } else {
      _notificationHelper.cancelNotification();
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _profileImageUrl = null;
      });
      String fileName = pickedFile.name;
      try {
        TaskSnapshot snapshot = await _storage.ref('profile_images/$fileName').putFile(_imageFile!);
        String downloadUrl = await snapshot.ref.getDownloadURL();
        setState(() {
          _profileImageUrl = downloadUrl;
        });
        await _updateUserProfile(); // Correctly calling the update method
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
      _updateNotificationSettings();
    }
  }

  Future<void> _selectDay(BuildContext context) async {
    // Choose the day for weekly/monthly notifications
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int initialDay = _notificationFrequency == 'Weekly' ? 1 : 1;
        int maxDays = _notificationFrequency == 'Weekly' ? 7 : 31;
        return AlertDialog(
          title: Text('Select Day'),
          content: DropdownButton<int>(
            value: _selectedDay,
            items: List.generate(maxDays, (index) => index + 1)
                .map((int day) => DropdownMenuItem<int>(
              value: day,
              child: Text(day.toString()),
            ))
                .toList(),
            onChanged: (int? value) {
              setState(() {
                _selectedDay = value;
              });
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }

  void _onFrequencyChanged(String? value) {
    setState(() {
      _notificationFrequency = value!;
      if (value == 'Daily') {
        _selectedDay = null; // Reset selected day if Daily is chosen
      }
      _updateNotificationSettings();
    });
  }

  void _testImmediateNotification() {
    _notificationHelper.scheduleNotification('Daily', TimeOfDay.now(), null);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Test notification scheduled')));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile Page')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : (_profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null) as ImageProvider?,
                child: _imageFile == null && _profileImageUrl == null ? Icon(Icons.add_a_photo) : null,
              ),
            ),
            TextField(controller: _nameController, decoration: InputDecoration(labelText: 'Name')),
            TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email')),
            SwitchListTile(
              title: Text('Enable Notifications'),
              value: _notificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                _updateNotificationSettings();
              },
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _notificationFrequency,
                    items: ['Daily', 'Weekly', 'Monthly'].map((String frequency) {
                      return DropdownMenuItem(
                        value: frequency,
                        child: Text(frequency),
                      );
                    }).toList(),
                    onChanged: _onFrequencyChanged,
                    decoration: InputDecoration(labelText: 'Frequency'),
                  ),
                ),
                if (_notificationFrequency != 'Daily')
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDay(context),
                  ),
              ],
            ),
            ElevatedButton(onPressed: () => _selectTime(context), child: Text('Select Notification Time')),
            ElevatedButton(onPressed: _updateUserProfile, child: Text('Update Profile')),
          ],
        ),
      ),
    );
  }
}
