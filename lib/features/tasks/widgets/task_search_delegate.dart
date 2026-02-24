import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../../../core/theme/colorsettings.dart';
import 'smart_task_card.dart';

class TaskSearchDelegate extends SearchDelegate {
  final List<TaskModel> tasks;
  final AppColors colors;
  final Function(TaskModel) onTaskCheck;

  TaskSearchDelegate({
    required this.tasks,
    required this.colors,
    required this.onTaskCheck,
  });

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: AppBarTheme(
        backgroundColor: colors.bgMain,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textMain),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: colors.textSecondary.withOpacity(0.5)),
        border: InputBorder.none,
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          color: colors.textMain,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      scaffoldBackgroundColor: colors.bgMain,
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.clear, color: colors.textMain),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: colors.textMain),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  Widget _buildList() {
    final results = tasks.where((t) {
      final q = query.toLowerCase();
      final titleMatch = t.title.toLowerCase().contains(q);
      final descMatch = t.description?.toLowerCase().contains(q) ?? false;
      return titleMatch || descMatch;
    }).toList();

    return Container(
      color: colors.bgTop,
      child: results.isEmpty
          ? Center(
              child: Text(
                "No results found",
                style: TextStyle(color: colors.textSecondary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: results.length,
              itemBuilder: (context, index) => SmartTaskCard(
                task: results[index],
                colors: colors,
                onCheck: () {
                  onTaskCheck(results[index]);
                  // Optional: close(context, null); // Close search on check?
                },
                onLongPress: () {},
              ),
            ),
    );
  }
}
