import 'package:flutter/material.dart';
import 'package:expense_repository/repositories.dart';

class PriorityBasedBudgetingPage extends StatefulWidget {
  @override
  _PriorityBasedBudgetingPageState createState() => _PriorityBasedBudgetingPageState();
}

class _PriorityBasedBudgetingPageState extends State<PriorityBasedBudgetingPage> {
  List<Category> selectedCategories = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Priority-Based Budgeting'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Priority-Based Budgeting',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Priority-based budgeting helps you allocate funds according to your financial priorities. '
                  'This approach ensures that the most important expenses, such as tuition, rent, and essential supplies, are covered first, '
                  'followed by secondary needs and wants. This budgeting method is especially useful for college students managing limited resources.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CategorySelectionPage(onSelectionDone: (selected) {
                      setState(() {
                        selectedCategories = selected;
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RankCategoriesPage(
                          selectedCategories: selectedCategories,
                          onRankingDone: (rankedCategories) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AllocationPage(selectedCategories: rankedCategories)),
                            );
                          },
                        )),
                      );
                    })),
                  );
                },
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategorySelectionPage extends StatefulWidget {
  final void Function(List<Category>) onSelectionDone;

  CategorySelectionPage({required this.onSelectionDone});

  @override
  _CategorySelectionPageState createState() => _CategorySelectionPageState();
}

class _CategorySelectionPageState extends State<CategorySelectionPage> {
  List<Category> selectedCategories = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Categories'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,  // 4 items per row
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 0.9, // Adjust this value to change the height of the boxes
          ),
          itemCount: predefinedCategories.length,
          itemBuilder: (context, index) {
            final category = predefinedCategories[index];
            final isSelected = selectedCategories.contains(category);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selectedCategories.remove(category);
                  } else {
                    selectedCategories.add(category);
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.greenAccent : Colors.white,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(category.icon, height: 50, width: 50),
                    const SizedBox(height: 8),
                    Text(
                      category.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,           // Font size of the text
                        letterSpacing: .8,     // Adjusts the spacing between characters
                        height: 1,            // Adjusts the line height (line spacing)
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          widget.onSelectionDone(selectedCategories);
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}

class RankCategoriesPage extends StatefulWidget {
  final List<Category> selectedCategories;
  final void Function(List<Category>) onRankingDone;

  RankCategoriesPage({required this.selectedCategories, required this.onRankingDone});

  @override
  _RankCategoriesPageState createState() => _RankCategoriesPageState();
}

class _RankCategoriesPageState extends State<RankCategoriesPage> {
  late List<Category> rankedCategories;

  @override
  void initState() {
    super.initState();
    rankedCategories = List.from(widget.selectedCategories);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rank Categories'),
      ),
      body: ReorderableListView(
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final Category item = rankedCategories.removeAt(oldIndex);
            rankedCategories.insert(newIndex, item);
          });
        },
        children: List.generate(rankedCategories.length, (index) {
          final category = rankedCategories[index];
          return ListTile(
            key: ValueKey(category.categoryId),
            leading: Image.asset(category.icon),
            title: Text(category.name),
            trailing: const Icon(Icons.drag_handle),
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          widget.onRankingDone(rankedCategories);
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}

class AllocationPage extends StatelessWidget {
  final List<Category> selectedCategories;

  AllocationPage({required this.selectedCategories});

  @override
  Widget build(BuildContext context) {
    final TextEditingController _incomeController = TextEditingController();
    String _incomeType = 'Monthly';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Allocate Funds'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Your Income',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _incomeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter your income',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: _incomeType,
              onChanged: (String? newValue) {
                _incomeType = newValue!;
              },
              items: <String>['Monthly', 'Weekly'].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final income = double.tryParse(_incomeController.text);
                if (income != null) {
                  _allocateBudget(income);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid income amount')),
                  );
                }
              },
              child: const Text('Allocate'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: selectedCategories.length,
                itemBuilder: (context, index) {
                  final category = selectedCategories[index];
                  return ListTile(
                    leading: Image.asset(category.icon),
                    title: Text(category.name),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _allocateBudget(double income) {
    double remainingIncome = income;
    final Map<String, double> allocatedBudget = {};

    for (final category in selectedCategories) {
      if (remainingIncome > 0) {
        // Allocate a fixed percentage of remaining income based on priority
        double allocation = remainingIncome * 0.1; // Example: 10% of remaining income
        allocatedBudget[category.name] = allocation;
        remainingIncome -= allocation;
      } else {
        allocatedBudget[category.name] = 0;
      }
    }

    // Here you would update the UI or database with the allocatedBudget
    print('Allocated Budget: $allocatedBudget');
  }
}
