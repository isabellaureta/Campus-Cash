import 'package:expense_repository/repositories.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class ChartScreen extends StatefulWidget {
  final List<Expense> expenses;
  final List<Income> income;

  const ChartScreen({Key? key, required this.expenses, required this.income}) : super(key: key);

  @override
  _ChartScreenState createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  List<ChartData> chartData = [];
  String selectedType = 'Expenses'; // Default selection

  @override
  void initState() {
    super.initState();
    generateChartData();
  }

  void generateChartData() {
    Map<String, ChartData> aggregatedData = {};

    if (selectedType == 'Expenses') {
      for (var expense in widget.expenses) {
        if (aggregatedData.containsKey(expense.category.name)) {
          aggregatedData[expense.category.name]!.totalAmount += expense.amount;
        } else {
          aggregatedData[expense.category.name] = ChartData(
            expense.category.name,
            expense.amount,
            expense.category.color,
            expense.category.icon,
          );
        }
      }
    } else if (selectedType == 'Income') {
      for (var income in widget.income) {
        if (aggregatedData.containsKey(income.category2.name)) {
          aggregatedData[income.category2.name]!.totalAmount += income.amount;
        } else {
          aggregatedData[income.category2.name] = ChartData(
            income.category2.name,
            income.amount,
            income.category2.color,
            income.category2.icon,
          );
        }
      }
    }else if (selectedType == 'Expense Flow') {

    }

    setState(() {
      chartData = aggregatedData.values.toList();
    });
  }

  double getTotalAmount() {
    return chartData.fold(0, (sum, item) => sum + item.totalAmount);
  }

  @override
  Widget build(BuildContext context) {
    double totalAmount = getTotalAmount();
    return Scaffold(
      appBar: AppBar(
        title: Text('Chart Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButton<String>(
                value: selectedType,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedType = newValue!;
                    generateChartData();
                  });
                },
                items: <String>['Expenses', 'Income', 'Expense Flow', 'Income Flow'].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: SfCircularChart(
                legend: const Legend(
                  isVisible: true,
                  position: LegendPosition.right,
                  overflowMode: LegendItemOverflowMode.wrap,
                  iconHeight: 18,
                  iconWidth: 18,
                ),
                series: <CircularSeries>[
                  PieSeries<ChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (ChartData data, _) => data.categoryName,
                    yValueMapper: (ChartData data, _) => data.totalAmount,
                    pointColorMapper: (ChartData data, _) => Color(data.color),
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.inside,
                      connectorLineSettings: ConnectorLineSettings(
                        type: ConnectorType.line,
                      ),
                      textStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(2.0, 2.0),
                            blurRadius: 3.0,
                            color: Color.fromARGB(255, 0, 0, 0), // Shadow color
                          ),
                        ]
                      ),
                    ),
                    enableTooltip: true,
                  ),
                ],
              ),
            ),
            ...chartData.map((data) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
            )).toList(),

            SizedBox(height: 16.0),
            ...chartData.map((data) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Color(data.color),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Image.asset(
                        'assets/${data.icon}.png',
                        scale: 2,
                        color: Colors.white,
                      ),
                    ],
                  ),

                  SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              textAlign: TextAlign.left,
                              data.categoryName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              textAlign: TextAlign.left,
                              '    ${data.totalAmount}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              textAlign: TextAlign.right,
                              '${((data.totalAmount / totalAmount) * 100).toStringAsFixed(2)}%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            Container(
                              width: (data.totalAmount / totalAmount) * MediaQuery.of(context).size.width,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Color(data.color),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 9),

                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}

class ChartData {
  final String categoryName;
  int totalAmount; // Changed to mutable so it can be aggregated
  final int color;
  final String icon;

  ChartData(this.categoryName, this.totalAmount, this.color, this.icon);
}
