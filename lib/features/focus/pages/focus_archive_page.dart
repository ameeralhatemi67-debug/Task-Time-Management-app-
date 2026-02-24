import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import '../../../../data/repositories/focus_repository.dart';
// REMOVED UNUSED IMPORT: focus_task_model.dart

class FocusArchivePage extends StatelessWidget {
  const FocusArchivePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final repo = FocusRepository();

    return Scaffold(
      backgroundColor: colors.bgMain,
      appBar: AppBar(
        backgroundColor: colors.bgMain,
        elevation: 0,
        leading: BackButton(color: colors.textMain),
        title:
            Text("Archived Sessions", style: TextStyle(color: colors.textMain)),
      ),
      body: ValueListenableBuilder(
        valueListenable: repo.box.listenable(),
        builder: (context, box, _) {
          final tasks = repo.getArchivedTasks();

          if (tasks.isEmpty) {
            return Center(
              child: Text("No history yet",
                  style: TextStyle(color: colors.textSecondary)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final t = tasks[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: colors.bgMiddle.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.history, color: colors.textSecondary, size: 20),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.title,
                              style: TextStyle(
                                  color: colors.textMain,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.lineThrough)),
                          Text(
                            "${t.targetDurationSeconds ~/ 60}m • ${t.dateCreated.toString().split(' ')[0]}",
                            style: TextStyle(
                                color: colors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.unarchive, color: Colors.blue),
                      onPressed: () {
                        t.isArchived = false;
                        t.save();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
