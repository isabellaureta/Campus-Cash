import 'package:campuscash/screens/goal_savings/addLoan.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'addGoals.dart';
import 'addLoan2.dart';

class CustomTabBarsPage extends StatefulWidget {
  const CustomTabBarsPage({super.key});

  @override
  State<CustomTabBarsPage> createState() => _CustomTabBarsPageState();
}

class _CustomTabBarsPageState extends State<CustomTabBarsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = const [
    Tab(text: 'Goals'),
    Tab(text: 'Loans'),
  ];

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  void _navigateToAddGoalPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddGoalPage()),
    );
  }

  void _navigateToAddLoanPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MeToThemPage()),
    );
  }

  Future<void> _deleteGoal(DocumentSnapshot document) async {
    try {
      await FirebaseFirestore.instance
          .collection('goals')
          .doc(document.id)
          .delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete goal: $e')),
      );
    }
  }

  void _navigateToMeToThem() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MeToThemPage()),
    );
  }

  void _navigateToThemToMe() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ThemToMePage()),
    );
  }

  Widget _buildLoanSummary(int utangSayo, int utangMo) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text('PHP $utangSayo',
                      style: TextStyle(color: Colors.red, fontSize: 20)),
                  Text('Utang Sayo'),
                ],
              ),
              Column(
                children: [
                  Text('PHP $utangMo',
                      style: TextStyle(color: Colors.green, fontSize: 20)),
                  Text('Utang Mo'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoanCard(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    bool isUtangSayo = data['type'] == 'utangSayo';

    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple,
          child: Text(data['name'][0]),
        ),
        title: Text(data['name']),
        trailing: Text(
          'PHP ${data['amount']}',
          style: TextStyle(
            color: isUtangSayo ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(isUtangSayo ? 'Utang Sayo' : 'Utang Mo'),
      ),
    );
  }

  Widget _buildGoalCard(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    double progress = data['goalAmount'] > 0
        ? data['savedAmount'] / data['goalAmount']
        : 0;

    return GestureDetector(
      onLongPress: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Delete Goal'),
              content: Text('Are you sure you want to delete this goal?'),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Delete'),
                  onPressed: () {
                    _deleteGoal(document);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
      child: Card(
        elevation: 4,
        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['goalName'],
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(int.parse('0xff${data['color']}')),
                    radius: 24,
                    child: Image.asset(
                      'assets/${data['icon']}.png',
                      fit: BoxFit.contain,
                      width: 30,
                      height: 30,
                    ),
                  ),
                  SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Goal: ₱${data['goalAmount'].toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Saved: ₱${data['savedAmount'].toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              SizedBox(height: 10),
              Text(
                '${(progress * 100).toStringAsFixed(2)}% Completed',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Goals and Loans'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _navigateToAddGoalPage,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    textStyle: TextStyle(fontSize: 18),
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Text('Add Goal'),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('goals').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final goals = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: goals.length,
                      itemBuilder: (context, index) {
                        return _buildGoalCard(goals[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          Column(
    children: [
    StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('loans').snapshots(),
    builder: (context, snapshot) {
    if (!snapshot.hasData) {
    return Center(child: CircularProgressIndicator());
    }

    final loans = snapshot.data!.docs;
    int utangSayo = 0;
    int utangMo = 0;

    loans.forEach((loan) {
    Map<String, dynamic> data = loan.data() as Map<String, dynamic>;
    if (data['type'] == 'utangSayo') {
    utangSayo += (data['amount'] as num).toInt();
    } else {
    utangMo += (data['amount'] as num).toInt();
    }
    });

    return _buildLoanSummary(utangSayo, utangMo);
    },
    ),
    Expanded(
    child: StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('loans').snapshots(),
    builder: (context, snapshot) {
    if (!snapshot.hasData) {
    return Center(child: CircularProgressIndicator());
    }

    final loans = snapshot.data!.docs;

    return ListView.builder(
    itemCount: loans.length,
    itemBuilder: (context, index) {
    return _buildLoanCard(loans[index]);
    },
    );
    },
    ),
    ),
    Padding(
    padding: const EdgeInsets.all(16.0),
    child: ElevatedButton(
    onPressed: _navigateToThemToMe,
    style: ElevatedButton.styleFrom(
    padding: EdgeInsets.symmetric(vertical: 16),
    textStyle: TextStyle(fontSize: 18),
    minimumSize: Size(double.infinity, 50),
    ),
    child: Text('Them to Me'),
    ),
    ),
    Padding(
    padding: const EdgeInsets.all(16.0),
    child: ElevatedButton(
    onPressed: _navigateToMeToThem,
    style: ElevatedButton.styleFrom(
    padding: EdgeInsets.symmetric(vertical: 16),
    textStyle: TextStyle(fontSize: 18),
    minimumSize: Size(double.infinity, 50),
    ),
    child: Text('Me to Them'),
    ),
    )],
      ),
    ]));
  }
}