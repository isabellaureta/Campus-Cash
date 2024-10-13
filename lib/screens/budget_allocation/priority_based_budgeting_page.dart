import 'package:flutter/material.dart';
import 'package:expense_repository/repositories.dart';

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

class AllocationPage2 extends StatefulWidget {
  final List<Category> selectedCategories;

  AllocationPage2({required this.selectedCategories});

  @override
  _AllocationPage2State createState() => _AllocationPage2State();
}

class _AllocationPage2State extends State<AllocationPage2> {
  final TextEditingController _incomeController = TextEditingController();
  String _incomeType = 'Monthly';

  // A map to store the amount entered for each category
  Map<Category, TextEditingController> categoryAmountControllers = {};

  @override
  void initState() {
    super.initState();
    // Initialize controllers for each category
    for (var category in widget.selectedCategories) {
      categoryAmountControllers[category] = TextEditingController();
    }
  }

  @override
  void dispose() {
    // Dispose all the controllers when the widget is disposed
    for (var controller in categoryAmountControllers.values) {
      controller.dispose();
    }
    _incomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
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
                setState(() {
                  _incomeType = newValue!;
                });
              },
              items: <String>['Monthly', 'Weekly'].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: widget.selectedCategories.length,
                itemBuilder: (context, index) {
                  final category = widget.selectedCategories[index];
                  final controller = categoryAmountControllers[category]!;  // Get the controller for the category

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: Image.asset(
                        category.icon,
                        width: 40,  // Adjust the icon width
                        height: 40,  // Adjust the icon height
                      ),
                      title: Text(
                        category.name,
                        style: const TextStyle(fontSize: 14), // Smaller font size
                      ),
                      subtitle: SizedBox(
                        height: 40,  // Make the text field smaller in height
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),  // Reduce padding inside the text field
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
