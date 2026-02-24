import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import '../../../data/repositories/task_repository.dart';
import 'task_count_indicator.dart'; // Ensure this import points to the file in this folder

class CalendarStrip extends StatefulWidget {
  final AppColors colors;
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const CalendarStrip({
    super.key,
    required this.colors,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<CalendarStrip> createState() => _CalendarStripState();
}

class _CalendarStripState extends State<CalendarStrip> {
  final TaskRepository _repo = TaskRepository();
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // Start at a high number to allow scrolling back
    _pageController = PageController(initialPage: 1000);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _jumpToToday() {
    widget.onDateSelected(DateTime.now());
    _pageController.animateToPage(
      1000,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _jumpToToday,
      child: Container(
        height: 85,
        color: Colors.transparent,
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            // Optional: Auto-select first day of week on swipe?
            // For now, we just let the user browse.
          },
          itemBuilder: (context, pageIndex) {
            // Calculate the Monday (or start) of the visible week
            final today = DateTime.now();
            final weekStart = today
                .subtract(Duration(days: today.weekday - 1))
                .add(Duration(days: (pageIndex - 1000) * 7));

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (dayIndex) {
                final date = weekStart.add(Duration(days: dayIndex));
                final isSelected = _isSameDay(date, widget.selectedDate);
                final isToday = _isSameDay(date, DateTime.now());

                // Get data from Repo
                final status = _repo.getIndicatorStatusForDay(date);
                final count = status == -1 ? 1 : status;
                final isHighPriority = status == -1;

                return GestureDetector(
                  onTap: () => widget.onDateSelected(date),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E').format(date)[0],
                        style: TextStyle(
                          color: widget.colors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? widget.colors.highlight
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: isToday && !isSelected
                              ? Border.all(color: widget.colors.highlight)
                              : null,
                        ),
                        child: Text(
                          "${date.day}",
                          style: TextStyle(
                            color: isSelected
                                ? widget.colors.textHighlighted
                                : widget.colors.textMain,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TaskCountIndicator(
                        count: count,
                        hasHighPriority: isHighPriority,
                        colors: widget.colors,
                        isSelected: isSelected,
                      ),
                    ],
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
