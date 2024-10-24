import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  final TextEditingController _passwordController = TextEditingController();
  bool _notificationsEnabled = false;
  String? _profileImageUrl;
  File? _imageFile;
  final NotificationHelper _notificationHelper = NotificationHelper();
  TimeOfDay _selectedTime = TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() async {
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
      });
      if (_notificationsEnabled) {
        _notificationHelper.scheduleDailyNotification(_selectedTime);
      }
    }
  }

  void _updateUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'name': _nameController.text,  // Update the user's name in Firebase
        'profileImageUrl': _profileImageUrl,
        'notificationsEnabled': _notificationsEnabled,
        'notificationHour': _selectedTime.hour,
        'notificationMinute': _selectedTime.minute,
      });
      if (_emailController.text != user.email) {
        user.updateEmail(_emailController.text);
      }
      if (_notificationsEnabled) {
        _notificationHelper.scheduleDailyNotification(_selectedTime);
      } else {
        _notificationHelper.cancelNotification();
      }
    }
  }


  void _changePassword() async {
    User? user = _auth.currentUser;
    if (user != null) {
      user.updatePassword(_passwordController.text);
    }
  }

  void _deleteAccount() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).delete();
      user.delete();
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _profileImageUrl = null; // Reset the URL since a new image is picked
      });
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
      if (_notificationsEnabled) {
        _notificationHelper.scheduleDailyNotification(_selectedTime);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Page'),
      ),
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
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SwitchListTile(
              title: Text('Enable Notifications'),
              value: _notificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                if (value) {
                  _notificationHelper.scheduleDailyNotification(_selectedTime);
                } else {
                  _notificationHelper.cancelNotification();
                }
              },
            ),
            ElevatedButton(
              onPressed: () => _selectTime(context),
              child: Text('Select Notification Time'),
            ),
            ElevatedButton(
              onPressed: _updateUserProfile,
              child: Text('Update Profile'),
            ),
            ElevatedButton(
              onPressed: _deleteAccount,
              child: Text('Delete Account'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
