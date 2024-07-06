import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:campuscash/auth/bloc/auth_bloc.dart';
import 'package:campuscash/auth/bloc/auth_event.dart';


class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController _email = TextEditingController();
  TextEditingController dateOfBirth = TextEditingController();
  TextEditingController password = TextEditingController();


  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('userDetails').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          //_email.text = userDetails?.email ?? '';
          //dateOfBirth.text = userDetails?.dateOfBirth ?? '';
        });
      } else {
        // Handle the case where the document does not exist
        print('User document does not exist');
      }
    } else {
      // Handle the case where the user is not authenticated
      print('User is not authenticated');
    }
  }

  Future<void> updateUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;

  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.grey.withOpacity(0.05),
      body: getBody(size),
    );
  }

  Widget getBody(Size size) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildHeader(size),
          SizedBox(height: 50),
          buildUserDetailsForm(),
        ],
      ),
    );
  }

  Widget buildHeader(Size size) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.01),
          spreadRadius: 10,
          blurRadius: 3,
        ),
      ]),
      child: Padding(
        padding: const EdgeInsets.only(top: 60, right: 20, left: 20, bottom: 25),
        child: Column(
          children: [
            buildProfileHeader(),
            SizedBox(height: 25),
            buildProfileInfo(size),
            SizedBox(height: 25),
            buildBudgetCard(),
          ],
        ),
      ),
    );
  }

  Widget buildProfileHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Profile",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        IconButton(
          icon: Icon(Icons.logout),
          onPressed: () {
            context.read<AuthBloc>().add(AuthEventLogOut());
            Navigator.of(context).pushReplacementNamed('/welcome');
          },
        ),
      ],
    );
  }

  Widget buildProfileInfo(Size size) {
    return Row(
      children: [
        Container(
          width: (size.width - 40) * 0.4,
          child: Stack(
            children: [
              RotatedBox(
                quarterTurns: -2,
                child: CircularPercentIndicator(
                  circularStrokeCap: CircularStrokeCap.round,
                  backgroundColor: Colors.grey.withOpacity(0.3),
                  radius: 110.0,
                  lineWidth: 6.0,
                  percent: 0.53,
                  progressColor: Colors.pinkAccent,
                ),
              ),
              Positioned(
                top: 16,
                left: 13,
                child: Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: (size.width - 40) * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              SizedBox(height: 10),
              Text(
                "Budget: 73.50",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black.withOpacity(0.4)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildBudgetCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.tertiary,
            Theme.of(context).colorScheme.secondary,
            Theme.of(context).colorScheme.primary,
          ],
          transform: GradientRotation(pi / 4),
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.pinkAccent.withOpacity(0.01),
            spreadRadius: 10,
            blurRadius: 3,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 25, bottom: 25),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "...",
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.white),
                ),
                SizedBox(height: 10),
                Text(
                  "00.90",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
                ),
              ],
            ),
            GestureDetector(
              onTap: updateUserDetails,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(13.0),
                  child: Text(
                    "Update",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildUserDetailsForm() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTextField("Email", _email),
          SizedBox(height: 20),
          buildTextField("Date of birth", dateOfBirth),
          SizedBox(height: 20),
          buildTextField("Password", password, obscureText: true),
        ],
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller, {bool obscureText = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Color(0xff67727d)),
        ),
        TextField(
          controller: controller,
          cursorColor: Colors.black,
          obscureText: obscureText,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black),
          decoration: InputDecoration(hintText: label, border: InputBorder.none),
        ),
      ],
    );
  }
}
