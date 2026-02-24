import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';

class ThemeTestView extends StatefulWidget {
  final String pageName;
  const ThemeTestView({super.key, required this.pageName});

  @override
  State<ThemeTestView> createState() => _ThemeTestViewState();
}

class _ThemeTestViewState extends State<ThemeTestView> {
  bool isTaskDone = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Center(
      child: SingleChildScrollView(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.bgBottom,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Layer 1: Bottom",
                style: TextStyle(color: colors.textSecondary, fontSize: 10),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.bgMiddle,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      "Layer 2: Middle",
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: colors.bgTop,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            widget.pageName,
                            style: TextStyle(
                              color: colors.textMain,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Checking 10-Color System",
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // NEW: 10th Color Test
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  colors.highlight, // Background is Highlight
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Highlighted Text",
                              style: TextStyle(
                                color: colors
                                    .textHighlighted, // Text is 10th color
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                          Divider(color: colors.textSecondary.withOpacity(0.2)),
                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isTaskDone ? "Status: DONE" : "Status: UNDONE",
                                style: TextStyle(
                                  color: isTaskDone
                                      ? colors.done
                                      : colors.undone,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Transform.scale(
                                scale: 1.2,
                                child: Checkbox(
                                  value: isTaskDone,
                                  activeColor: colors.highlight,
                                  checkColor: colors.textHighlighted,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      isTaskDone = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
