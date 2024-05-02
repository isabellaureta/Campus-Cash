import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_repository/expense_repository.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ChartScreen extends StatefulWidget {
  final List<Expense> expenses;

  const ChartScreen({Key? key, required this.expenses}) : super(key: key);

  @override
  _ChartScreenState createState() => _ChartScreenState();
}


class _ChartScreenState extends State<ChartScreen> {
  List<ChartData> chartData = [];


  @override
  void initState() {
    super.initState();
    generateChartData();
  }

  void generateChartData() {
    // Calculate total expenses for each category
    Map<String, int> categoryExpenses = {};
    widget.expenses.forEach((expense) {
      if (categoryExpenses.containsKey(expense.category.name)) {
        categoryExpenses[expense.category.name] =
            categoryExpenses[expense.category.name]! + expense.amount;
      } else {
        categoryExpenses[expense.category.name] = expense.amount;
      }
    });

    // Convert the map to a list of ChartData objects
    List<ChartData> data = [];
    categoryExpenses.forEach((category, totalExpenses) {
      // Use a color code based on category name (you can modify this as needed)
      int colorCode = category.hashCode;
      data.add(ChartData(category, totalExpenses, colorCode));
    });

    setState(() {
      chartData = data;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bar Chart'),
      ),
      body: Center(
        child: Container(
          child: SfCartesianChart(
            primaryXAxis: CategoryAxis(),
            series: <CartesianSeries>[
              StackedColumnSeries<ChartData, String>(
                dataSource: chartData,
                xValueMapper: (ChartData data, _) => data.categoryName,
                yValueMapper: (ChartData data, _) => data.totalExpenses,
                // Customizing data points color based on 'color' field
                pointColorMapper: (ChartData data, _) =>
                    Color(data.color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class ChartData {
  final String categoryName;
  final int totalExpenses;
  final int color;

  ChartData(this.categoryName, this.totalExpenses, this.color);
}
