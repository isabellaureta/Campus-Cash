import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PayYourselfFirstPage extends StatefulWidget {
  @override
  _PayYourselfFirstPageState createState() => _PayYourselfFirstPageState();
}

class _PayYourselfFirstPageState extends State<PayYourselfFirstPage> {
  TextEditingController incomeController = TextEditingController();
  TextEditingController percentController = TextEditingController();
  String incomeType = 'Monthly';
  double totalSavings = 0.0;
  double excessMoney = 0.0;

  void calculateSavingsAndExcessMoney() {
    double income = double.parse(incomeController.text);
    double percent = double.parse(percentController.text);

    if (incomeType == 'Weekly') {
      income *= 4; // Convert weekly income to monthly
    }

    double savings = income * (percent / 100);

    setState(() {
      totalSavings = savings;
      excessMoney = income - savings;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pay Yourself First')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: incomeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Income'),
            ),
            DropdownButton<String>(
              value: incomeType,
              onChanged: (String? newValue) {
                setState(() {
                  incomeType = newValue!;
                });
              },
              items: <String>['Monthly', 'Weekly']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            TextField(
              controller: percentController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Percent of Income to Save'),
            ),
            ElevatedButton(
              onPressed: calculateSavingsAndExcessMoney,
              child: Text('Calculate Savings and Excess Money'),
            ),
            SizedBox(height: 20),
            Text(
              'Total Savings: \$${totalSavings.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 10),
            Text(
              'Excess Money: \$${excessMoney.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
