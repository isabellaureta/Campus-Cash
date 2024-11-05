import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'Budget.dart';
import 'BudgetAllocation.dart';

class BudgetSelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Budget Selection')),
      body: Center(
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.symmetric(horizontal: 16),
          children: [
            _buildBudgetOption(
              context,
              title: 'Budget',
              description: 'Manage your budget and track expenses',
              imagePath: 'assets/Budget.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Budget()),
                );
              },
            ),
            _buildBudgetOption(
              context,
              title: 'Budgeting Technique',
              description: 'Allocate funds and view spending categories',
              imagePath: 'assets/BudgetTechnique.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BudgetAllocation()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetOption(
      BuildContext context, {
        required String title,
        required String description,
        required String imagePath,
        required VoidCallback onTap,
        double height = 250,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 350,
        height: height,
        margin: EdgeInsets.symmetric(vertical: 10),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.pink.shade50, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.4),
              blurRadius: 8,
              offset: Offset(2, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.asset(imagePath, width: 100, height: 100),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,  // Center-align content vertically
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.agdasima(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.nunito(
                      fontSize: 17,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey),
          ],
        ),
      ),
    );
  }

}
