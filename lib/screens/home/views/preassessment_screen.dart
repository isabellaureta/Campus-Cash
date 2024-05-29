import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PreAssessmentView extends StatefulWidget {
  const PreAssessmentView({Key? key}) : super(key: key);

  @override
  State<PreAssessmentView> createState() => _PreAssessmentViewState();
}

class _PreAssessmentViewState extends State<PreAssessmentView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  File? _profileImage;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _submit() {
    final name = _nameController.text;
    final budget = _budgetController.text;

    // Save the data or navigate to the next screen
    // For now, we just print the values
    print('Name: $name');
    print('Budget: $budget');
    if (_profileImage != null) {
      print('Profile Image: ${_profileImage!.path}');
    }

    // Navigate to the next screen or perform any additional actions
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pre-Assessment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Name'),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Enter your name',
              ),
            ),
            const SizedBox(height: 16.0),
            const Text('Profile Picture'),
            GestureDetector(
              onTap: _pickImage,
              child: _profileImage == null
                  ? const CircleAvatar(
                radius: 40,
                child: Icon(Icons.camera_alt, size: 40),
              )
                  : CircleAvatar(
                radius: 40,
                backgroundImage: FileImage(_profileImage!),
              ),
            ),
            const SizedBox(height: 16.0),
            const Text('Budget'),
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Enter your budget',
              ),
            ),
            const SizedBox(height: 24.0),
            Center(
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
