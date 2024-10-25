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
        // No date change for All Time view
          break;
      }
      generateChartData();
    });
  }

  void generateChartData() {
    Map<String, ChartData> aggregatedData = {};
    DateTime weekEndDate = selectedDate.add(Duration(days: 6));

    for (var expense in widget.expenses) {
      bool isIncluded = false;

      // Check if the expense date matches the selected view criteria
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

      // Aggregate data if the date matches the selected view
      if (isIncluded) {
        if (selectedType == 'Expenses' && expense.date != null) {
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
        } else if (selectedType == 'Income' && expense.date != null) {
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
        } else if (selectedType == 'Expense Flow') {
          DateTime day = DateTime(expense.date.year, expense.date.month, expense.date.day);
          dailyExpenseData.update(
            day,
                (value) => value + expense.amount.toDouble(), // Convert to double
            ifAbsent: () => expense.amount.toDouble(), // Ensure double on insertion as well
          );
        }
      }
    }

    setState(() {
      chartData = selectedType != 'Expense Flow' ? aggregatedData.values.toList() : [];
    });
  }


  double getTotalAmount() {
    return chartData.fold(0, (sum, item) => sum + item.totalAmount);
  }

  void _changeMonth(bool increment) {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + (increment ? 1 : -1),
      );

      if (selectedMonth.month > 12) {
        selectedMonth = DateTime(selectedMonth.year + 1, 1);
      } else if (selectedMonth.month < 1) {
        selectedMonth = DateTime(selectedMonth.year - 1, 12);
      }

      // Trigger data regeneration based on the new selected month
      generateChartData();
    });
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
    body: SingleChildScrollView(  // NEW: Make the content scrollable
    child: Column(
    children: [
    // Header Section (Static)
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
          SizedBox(height: 8.0),
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
                    '\₱550.00  ',
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
                    '    \₱147.00',
                    style: TextStyle(color: Colors.green, fontSize: 20),
                  ),
                ],
              ),
              // Add a SizedBox for spacing between columns
              SizedBox(width: 16.0),
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.filter_list, color: Colors.black),
                    onPressed: () {
                      // Showing the PopupMenu when the filter icon is pressed
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
                            selectedView = value; // Update view based on selection
                            _changeDate(false); // Reset date display for new view
                          });
                        }
                      });
                    },
                  ),
                  Text(selectedType),
                ],
              ),
            ],
          ),
        ],
      ),
    ),

      SingleChildScrollView( // Make the Column scrollable
        child: Column(
          mainAxisSize: MainAxisSize.min,  // Ensure Column doesn't take infinite height
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
                items: <String>['Expenses', 'Income', 'Expense Flow', 'Income Flow']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
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
                    labelFormat: '\₱{value}', // Show currency format
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
            Flexible(
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
                    ),
                    enableTooltip: true,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.0),
            if (selectedType == 'Expense Flow')
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text(
                      "October, 2024",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                      ),
                      itemCount: 31,
                      itemBuilder: (context, index) {
                        final day = DateTime(2024, 10, index + 1);
                        final expense = dailyExpenseData[day] ?? 0.0;
                        return Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("${index + 1}", style: TextStyle(fontSize: 14)),
                              Text("\$${expense.toStringAsFixed(2)}", style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        );
                        },
                    ),
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
                        SizedBox(height: 9),
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
  int totalAmount; // Changed to mutable so it can be aggregated
  final int color;
  final String icon;

  ChartData(this.categoryName, this.totalAmount, this.color, this.icon);
}
