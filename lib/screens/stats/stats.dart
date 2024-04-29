import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({Key? key}) : super(key: key);

  @override
  _ChartScreenState createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  List<ChartData> chartData = [];


  @override
  void initState() {
    super.initState();
    // Call a function to fetch data from Firebase when the screen initializes
    fetchDataFromFirebase();
  }

  Future<void> fetchDataFromFirebase() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .get();

      List<ChartData> data = querySnapshot.docs.map((doc) {
        return ChartData(
          doc['name'], // Category name
          doc['totalExpenses'], // Total expenses
          doc['color'], // Color code
        );
      }).toList();

      setState(() {
        chartData = data;
      });
    } catch (error) {
      print("Error fetching data: $error");
    }
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
