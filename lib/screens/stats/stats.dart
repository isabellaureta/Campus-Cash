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
  String selectedType = 'Expenses';
  Map<DateTime, double> dailyExpenseData = {};
  Map<DateTime, double> dailyIncomeData = {};
  DateTime selectedMonth = DateTime.now();
  String selectedView = 'Monthly';
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    generateChartData();
  }

  void _changeDate(bool increment) {
    setState(() {
      switch (selectedView) {
        case 'Daily':
          selectedDate = selectedDate.add(Duration(days: increment ? 1 : -1));
          break;
        case 'Weekly':
          selectedDate = selectedDate.add(Duration(days: increment ? 7 : -7));
          break;
        case 'Monthly':
          selectedDate = DateTime(
            selectedDate.year,
            selectedDate.month + (increment ? 1 : -1),
          );
          break;
        case 'All Time':
          break;
      }
      generateChartData();
    });
  }

  void generateChartData() {
    Map<String, ChartData> aggregatedData = {};
    DateTime weekEndDate = selectedDate.add(Duration(days: 6));
    dailyExpenseData = {};
    dailyIncomeData = {};

    for (var expense in widget.expenses) {
      bool isIncluded = false;
      switch (selectedView) {
        case 'Daily':
          isIncluded = expense.date.year == selectedDate.year &&
              expense.date.month == selectedDate.month &&
              expense.date.day == selectedDate.day;
          break;
        case 'Weekly':
          isIncluded = expense.date.isAfter(selectedDate.subtract(const Duration(days: 1))) &&
              expense.date.isBefore(weekEndDate.add(const Duration(days: 1)));
          break;
        case 'Monthly':
          isIncluded = expense.date.year == selectedDate.year &&
              expense.date.month == selectedDate.month;
          break;
        case 'All Time':
          isIncluded = true;
          break;
      }

      if (isIncluded) {
        if (selectedType == 'Expenses') {
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
        } else if (selectedType == 'Expense Flow' || selectedType == 'Transaction Analysis') {
          DateTime day = DateTime(expense.date.year, expense.date.month, expense.date.day);
          dailyExpenseData.update(
            day,
                (value) => value + expense.amount.toDouble(),
            ifAbsent: () => expense.amount.toDouble(),
          );
        }
      }
    }

      for (var income in widget.income) {
        bool isIncluded = false;

        switch (selectedView) {
          case 'Daily':
            isIncluded = income.date.year == selectedDate.year &&
                income.date.month == selectedDate.month &&
                income.date.day == selectedDate.day;
            break;
          case 'Weekly':
            isIncluded = income.date.isAfter(selectedDate.subtract(const Duration(days: 1))) &&
                income.date.isBefore(weekEndDate.add(const Duration(days: 1)));
            break;
          case 'Monthly':
            isIncluded = income.date.year == selectedDate.year &&
                income.date.month == selectedDate.month;
            break;
          case 'All Time':
            isIncluded = true;
            break;
        }

        if (isIncluded) {
          if (selectedType == 'Income') {
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
          } else if (selectedType == 'Income Flow' || selectedType == 'Transaction Analysis') {
            DateTime day = DateTime(income.date.year, income.date.month, income.date.day);
            dailyIncomeData.update(
              day,
                  (value) => value + income.amount.toDouble(),
              ifAbsent: () => income.amount.toDouble(),
            );
          }
      }
    }

    setState(() {
      chartData = (selectedType == 'Expense Flow' || selectedType == 'Income Flow' || selectedType == 'Transaction Analysis')
          ? []
          : aggregatedData.values.toList();
      calculateTotalExpenses();
      calculateTotalIncome();
    });
  }

  double getTotalAmount() {
    return chartData.fold(0, (sum, item) => sum + item.totalAmount);
  }

  double calculateTotalExpenses() {
    double total = 0;
    for (var expense in widget.expenses) {
      bool isIncluded = false;
      switch (selectedView) {
        case 'Daily':
          isIncluded = expense.date.year == selectedDate.year &&
              expense.date.month == selectedDate.month &&
              expense.date.day == selectedDate.day;
          break;
        case 'Weekly':
          DateTime weekEndDate = selectedDate.add(Duration(days: 6));
          isIncluded = expense.date.isAfter(selectedDate.subtract(const Duration(days: 1))) &&
              expense.date.isBefore(weekEndDate.add(const Duration(days: 1)));
          break;
        case 'Monthly':
          isIncluded = expense.date.year == selectedDate.year &&
              expense.date.month == selectedDate.month;
          break;
        case 'All Time':
          isIncluded = true;
          break;
      }
      if (isIncluded) {
        total += expense.amount.toDouble();
      }
    }
    return total;
  }

  double calculateTotalIncome() {
    double total = 0;
    for (var income in widget.income) {
      bool isIncluded = false;
      switch (selectedView) {
        case 'Daily':
          isIncluded = income.date.year == selectedDate.year &&
              income.date.month == selectedDate.month &&
              income.date.day == selectedDate.day;
          break;
        case 'Weekly':
          DateTime weekEndDate = selectedDate.add(Duration(days: 6));
          isIncluded = income.date.isAfter(selectedDate.subtract(const Duration(days: 1))) &&
              income.date.isBefore(weekEndDate.add(const Duration(days: 1)));
          break;
        case 'Monthly':
          isIncluded = income.date.year == selectedDate.year &&
              income.date.month == selectedDate.month;
          break;
        case 'All Time':
          isIncluded = true;
          break;
      }
      if (isIncluded) {
        total += income.amount.toDouble();
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    String displayedDate;
    switch (selectedView) {
      case 'Daily':
        displayedDate = DateFormat.yMMMd().format(selectedDate);
        break;
      case 'Weekly':
        DateTime weekEnd = selectedDate.add(Duration(days: 6));
        displayedDate =
        "${DateFormat.yMMMd().format(selectedDate)} - ${DateFormat.yMMMd().format(weekEnd)}";
        break;
      case 'Monthly':
        displayedDate = DateFormat.yMMMM().format(selectedDate);
        break;
      default:
        displayedDate = "All Time";
        break;
    }
    double totalAmount = getTotalAmount();
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction Statistics'),
      ),
    body: SingleChildScrollView(
    child: Column(
    children: [

    Container(
    padding: const EdgeInsets.all(8.0),
      color: Colors.grey[200],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => _changeDate(false),
                icon: Icon(Icons.arrow_back),
              ),
              Text(
                displayedDate,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => _changeDate(true),
                icon: Icon(Icons.arrow_forward),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXPENSE',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                  Text(
                    '\₱${calculateTotalExpenses().toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.red, fontSize: 20),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'INCOME',
                    style: TextStyle(color: Colors.green, fontSize: 14),
                  ),
                  Text(
                    '\₱${calculateTotalIncome().toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.green, fontSize: 20),
                  ),
                ],
              ),
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.filter_list, color: Colors.black),
                    onPressed: () {

                      showMenu(
                        context: context,
                        position: RelativeRect.fromLTRB(100, 100, 0, 0),
                        items: [
                          PopupMenuItem(
                            value: 'Daily',
                            child: Text('Daily'),
                          ),
                          PopupMenuItem(
                            value: 'Weekly',
                            child: Text('Weekly'),
                          ),
                          PopupMenuItem(
                            value: 'Monthly',
                            child: Text('Monthly'),
                          ),
                          PopupMenuItem(
                            value: 'All Time',
                            child: Text('All Time'),
                          ),
                        ],
                      ).then((value) {
                        if (value != null) {
                          setState(() {
                            selectedView = value;
                            if (value == 'Transaction Analysis') {
                              selectedType = 'Transaction Analysis';
                            } else {
                              _changeDate(false);
                            }
                          });
                        }
                      }
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),

      SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: DropdownButton<String>(
                value: selectedType,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedType = newValue!;
                    generateChartData();
                  });
                },
                items: <String>['Expenses', 'Income', 'Transaction Analysis']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
            if (selectedType == 'Transaction Analysis')
              SizedBox(
                height: 300,
                child: SfCartesianChart(
                  primaryXAxis: DateTimeAxis(dateFormat: DateFormat.yMMMd()),
                  primaryYAxis: NumericAxis(labelFormat: '\₱{value}'),
                  legend: Legend(isVisible: true, position: LegendPosition.bottom),
                  series: <CartesianSeries>[
                    ColumnSeries<MapEntry<DateTime, double>, DateTime>(
                      dataSource: dailyExpenseData.entries.toList(),
                      xValueMapper: (MapEntry<DateTime, double> entry, _) => entry.key,
                      yValueMapper: (MapEntry<DateTime, double> entry, _) => entry.value,
                      color: Colors.red,
                      name: 'Expenses',
                    ),
                    ColumnSeries<MapEntry<DateTime, double>, DateTime>(
                      dataSource: dailyIncomeData.entries.toList(),
                      xValueMapper: (MapEntry<DateTime, double> entry, _) => entry.key,
                      yValueMapper: (MapEntry<DateTime, double> entry, _) => entry.value,
                      color: Colors.green,
                      name: 'Income',
                    ),
                  ],
                ),
              ),

            if (selectedType == 'Expense Flow')
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SfCartesianChart(
                  primaryXAxis: DateTimeAxis(
                    dateFormat: DateFormat.d(),
                    intervalType: DateTimeIntervalType.days,
                    interval: 1,
                  ),
                  primaryYAxis: NumericAxis(
                    labelFormat: '\₱{value}',
                  ),
                  series: <CartesianSeries>[
                    LineSeries<MapEntry<DateTime, double>, DateTime>(
                      dataSource: dailyExpenseData.entries.toList(),
                      xValueMapper: (MapEntry<DateTime, double> entry, _) => entry.key,
                      yValueMapper: (MapEntry<DateTime, double> entry, _) => entry.value,
                      markerSettings: MarkerSettings(isVisible: true),
                    ),
                  ],
                ),
              ),
            if (selectedType == 'Income Flow')
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SfCartesianChart(
                  primaryXAxis: DateTimeAxis(
                    dateFormat: DateFormat.d(),
                    intervalType: DateTimeIntervalType.days,
                    interval: 1,
                  ),
                  primaryYAxis: NumericAxis(
                    labelFormat: '\₱{value}',
                  ),
                  series: <CartesianSeries>[
                    LineSeries<MapEntry<DateTime, double>, DateTime>(
                      dataSource: dailyIncomeData.entries.toList(),
                      xValueMapper: (MapEntry<DateTime, double> entry, _) => entry.key,
                      yValueMapper: (MapEntry<DateTime, double> entry, _) => entry.value,
                      markerSettings: MarkerSettings(isVisible: true),
                    ),
                  ],
                ),
              ),
            Flexible(
              child: SfCircularChart(
                series: <CircularSeries>[
                  PieSeries<ChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (ChartData data, _) => data.categoryName,
                    yValueMapper: (ChartData data, _) => data.totalAmount,
                    pointColorMapper: (ChartData data, _) => Color(data.color),
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.inside,
                    ),
                    enableTooltip: true,
                  ),
                ],
              ),
            ),
            if (selectedType == 'Expense Flow')
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [

                  ],
                ),
              ),
            if (selectedType == 'Income Flow')
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                  ],
                ),
              ),
            ...chartData.map((data) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stack(
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
                          '${data.icon}',
                          scale: 2,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
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
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              textAlign: TextAlign.right,
                              '${((data.totalAmount / totalAmount) * 100).toStringAsFixed(2)}%',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
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
                              width: (data.totalAmount / totalAmount) *
                                  MediaQuery.of(context).size.width,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Color(data.color),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ))
                .toList(),
          ],
        ),
      ),
    ]
      )
    ));
  }
}

class ChartData {
  final String categoryName;
  int totalAmount;
  final int color;
  final String icon;
  ChartData(this.categoryName, this.totalAmount, this.color, this.icon);
}
