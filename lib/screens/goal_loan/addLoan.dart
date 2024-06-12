import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MeToThemPage extends StatefulWidget {
  @override
  _MeToThemPageState createState() => _MeToThemPageState();
}

class _MeToThemPageState extends State<MeToThemPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  void _addLoan() {
    FirebaseFirestore.instance.collection('loans').add({
      'name': _nameController.text,
      'amount': int.parse(_amountController.text),
      'type': 'utangMo',
    }).then((_) {
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Me to Them'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addLoan,
              child: Text('Add Loan'),
            ),
          ],
        ),
      ),
    );
  }
}
