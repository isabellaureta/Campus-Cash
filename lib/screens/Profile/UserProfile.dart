import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import '../home/views/login_view.dart';
import '../home/views/welcome_view.dart';
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
  List<Map<String, dynamic>> _recurringExpenses = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _fetchRecurringExpenses();
  }

  void _loadUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _emailController.text = user.email ?? '';
      });
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _nameController.text = userDoc['name'] ?? '';
        _profileImageUrl = userDoc['profileImageUrl'];
        _notificationsEnabled = userDoc['notificationsEnabled'] ?? false;
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

  Future<void> _updateUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'name': _nameController.text,
        'profileImageUrl': _profileImageUrl,
        'notificationsEnabled': _notificationsEnabled,
        'notificationHour': _selectedTime.hour,
        'notificationMinute': _selectedTime.minute,
      });

      if (_emailController.text != user.email) {
        await user.updateEmail(_emailController.text);
      }

      if (_notificationsEnabled) {
        _notificationHelper.scheduleDailyNotification(_selectedTime);
      } else {
        _notificationHelper.cancelNotification();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile Updated!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _deleteAccount() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Account'),
          content: Text('Are you sure you want to delete your account? This action cannot be undone.'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                User? user = _auth.currentUser;
                if (user != null) {
                  try {
                    await _firestore.collection('users').doc(user.uid).delete();
                    await user.delete();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const WelcomeView()),
                          (route) => false,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete account: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
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
        await _updateUserProfile();
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
      if (_notificationsEnabled) {
        _notificationHelper.scheduleDailyNotification(_selectedTime);
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Logout', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                await _auth.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginView()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.pink.shade300;
    final Color secondaryColor = Colors.blue.shade300;
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Account'),
        backgroundColor: secondaryColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: secondaryColor,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : (_profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null) as ImageProvider?,
                child: _imageFile == null && _profileImageUrl == null
                    ? Icon(Icons.add_a_photo, color: Colors.white, size: 40)
                    : null,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: primaryColor),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: secondaryColor),
                ),
              ),
            ),
            SizedBox(height: 16),
          TextField(
            controller: _emailController,
            readOnly: true, // Makes the field non-editable
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: TextStyle(color: primaryColor),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: primaryColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: secondaryColor),
              ),
            ),
          ),
            SizedBox(height: 16),
            SwitchListTile(
              activeColor: primaryColor,
              title: Text('Enable Notifications', style: TextStyle(color: Colors.pink)),
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
            SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              onPressed: _updateUserProfile,
              child: Text('Update Profile', style: TextStyle(color: Colors.white)),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              onPressed: _showLogoutDialog,
              child: Text('Logout', style: TextStyle(color: Colors.white)),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
              onPressed: _deleteAccount,
              child: Text('Delete Account', style: TextStyle(color: Colors.white)),
            ),
            SizedBox(height: 16),
            if (_recurringExpenses.isNotEmpty) ...[
              const Text(
                'Recurring Expenses:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Column(
                children: _recurringExpenses.map((expense) {
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade300,
                        child: Image.asset(expense['category']['icon']),
                      ),
                      title: Text(expense['category']['name']),
                      subtitle: Text(
                        'Amount: ₱${expense['amount']} | Date: ${DateFormat('dd/MM/yyyy').format((expense['date'] as Timestamp).toDate())}',
                      ),
                      onTap: () => _showRecurringExpenseDetails(context, expense),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),

      ),
    );
  }

  void _showRecurringExpenseDetails(BuildContext context, Map<String, dynamic> expense) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Recurring Expense Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Category: ${expense['category']['name']}'),
              Text('Amount: ₱${expense['amount']}'),
              Text('Frequency: ${expense['frequency']}'),
              Text('Start Date: ${DateFormat('dd/MM/yyyy').format((expense['startDate'] as Timestamp).toDate())}'),
              Text('End Date: ${DateFormat('dd/MM/yyyy').format((expense['endDate'] as Timestamp).toDate())}'),
              if (expense['description'] != null)
                Text('Description: ${expense['description']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await _stopRecurringExpense(expense['docId']);
                Navigator.pop(context);
              },
              child: const Text('Stop Recurring'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _stopRecurringExpense(String docId) async {
    try {
      await _firestore.collection('expenses').doc(docId).update({
        'isRecurring': false,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recurring expense stopped successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _fetchRecurringExpenses(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to stop recurring expense: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Future<void> _fetchRecurringExpenses() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('expenses')
        .where('userId', isEqualTo: user.uid)
        .where('isRecurring', isEqualTo: true)
        .get();

    setState(() {
      _recurringExpenses = snapshot.docs.map((doc) {
        final data = doc.data();
        data['docId'] = doc.id; // Include document ID for deletion
        return data;
      }).toList();
    });
  }
}
