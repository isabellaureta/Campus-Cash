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
            crossAxisCount: 4,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 0.9,
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
                        fontSize: 12,
                        letterSpacing: .8,
                        height: 1,
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


