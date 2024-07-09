import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PayYourselfFirstPage extends StatefulWidget {
  @override
  _PayYourselfFirstPageState createState() => _PayYourselfFirstPageState();
}

class _PayYourselfFirstPageState extends State<PayYourselfFirstPage> {
  TextEditingController incomeController = TextEditingController();
  TextEditingController savingsController = TextEditingController();
  String incomeType = 'Monthly';
  double excessMoney = 0.0;

  void calculateExcessMoney() {
    double income = double.parse(incomeController.text);
    double savings = double.parse(savingsController.text);

    if (incomeType == 'Weekly') {
      income *= 4; // Convert weekly income to monthly
    }

    setState(() {
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
              controller: savingsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Total Savings'),
            ),
            ElevatedButton(
              onPressed: calculateExcessMoney,
              child: Text('Calculate Excess Money'),
            ),
            SizedBox(height: 20),
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
