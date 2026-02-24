import 'package:flutter/material.dart';
import '../models/habit_model.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';

class HabitProgressGrid extends StatelessWidget {
  final HabitModel habit;
  final AppColors colors;
  final bool isInteractive;
  final Function(DateTime)? onDateToggled;

  final double barWidth;
  final double barHeight;
  final double spacing;

  const HabitProgressGrid({
    super.key,
    required this.habit,
    required this.colors,
    this.isInteractive = false,
    this.onDateToggled,
    this.barWidth = 12.0,
    this.barHeight = 36.0,
    this.spacing = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    switch (habit.type) {
      case HabitType.weekly:
        return _buildWeeklyProgressView();
      case HabitType.monthly:
        return _buildMonthlyProgressView();
      case HabitType.yearly:
        return _buildYearlyView();
    }
  }

  // ---------------------------------------------------------------------------
  // 1. WEEKLY VIEW
  // ---------------------------------------------------------------------------
  Widget _buildWeeklyProgressView() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    final int totalCount = habit.completedDaysList.length;
    final int completedCycles = (totalCount / 7).floor();

    final double barsSectionWidth = (barWidth * 7) + (spacing * 6);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // GRID (Right Side in Edit Mode? Or Left? Usually Grid is main)
        SizedBox(
          height: barHeight,
          width: barsSectionWidth,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final date = startOfWeek.add(Duration(days: index));
              final bool isFilled = habit.isCompletedOn(date);

              return GestureDetector(
                onTap: isInteractive ? () => onDateToggled?.call(date) : null,
                child: _buildPill(isFilled, barWidth, barHeight),
              );
            }),
          ),
        ),

        // PROGRESSION INDICATOR (Right Side)
        if (completedCycles > 0) ...[
          const SizedBox(width: 8),
          _buildWeeklyIndicators(completedCycles),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2. MONTHLY VIEW
  // ---------------------------------------------------------------------------
  Widget _buildMonthlyProgressView() {
    const int cycleLength = 30;
    final int totalCount = habit.completedDaysList.length;
    final int completedCycles = (totalCount / cycleLength).floor();

    final double squareSize = barWidth;
    final double gridWidth = (squareSize * 10) + (spacing * 9);
    final double gridHeight = (squareSize * 3) + (spacing * 2);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // GRID
        SizedBox(
          width: gridWidth,
          height: gridHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (rowIndex) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(10, (colIndex) {
                  // Index logic: 0 is 29 days ago, 29 is today
                  final int index = (rowIndex * 10) + colIndex;
                  final now = DateTime.now();
                  final date = now.subtract(Duration(days: 29 - index));

                  final bool isFilled = habit.isCompletedOn(date);

                  return GestureDetector(
                    onTap:
                        isInteractive ? () => onDateToggled?.call(date) : null,
                    child: _buildPill(isFilled, squareSize, squareSize),
                  );
                }),
              );
            }),
          ),
        ),

        // PROGRESSION INDICATOR
        if (completedCycles > 0) ...[
          const SizedBox(width: 8),
          _buildMonthlyIndicators(completedCycles, gridHeight),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 3. YEARLY VIEW
  // ---------------------------------------------------------------------------
  Widget _buildYearlyView() {
    const int cycleLength = 365;
    final int totalCount = habit.completedDaysList.length;
    final int completedCycles = (totalCount / cycleLength).floor();

    final int totalColumns = (365 / 7).ceil();
    final double squareSize = barWidth;
    final double gridHeight = (squareSize * 7) + (spacing * 6);
    final double gridWidth =
        (squareSize * totalColumns) + (spacing * (totalColumns - 1));

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // SCROLLABLE GRID
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              height: gridHeight,
              width: gridWidth,
              child: Row(
                children: List.generate(totalColumns, (colIndex) {
                  return Row(
                    children: [
                      Column(
                        children: List.generate(7, (rowIndex) {
                          final int dayIndex = (colIndex * 7) + rowIndex;
                          if (dayIndex >= 365)
                            return SizedBox(
                                width: squareSize, height: squareSize);

                          // Generic Year Grid: Jan 1 to Dec 31
                          final now = DateTime.now();
                          final startOfYear = DateTime(now.year, 1, 1);
                          final date =
                              startOfYear.add(Duration(days: dayIndex));

                          final bool isFilled = habit.isCompletedOn(date);

                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: rowIndex < 6 ? spacing : 0,
                            ),
                            child: GestureDetector(
                              onTap: isInteractive
                                  ? () => onDateToggled?.call(date)
                                  : null,
                              child:
                                  _buildPill(isFilled, squareSize, squareSize),
                            ),
                          );
                        }),
                      ),
                      if (colIndex < totalColumns - 1) SizedBox(width: spacing),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),

        // PROGRESSION INDICATOR
        if (completedCycles > 0) ...[
          const SizedBox(width: 8),
          _buildYearlyIndicators(completedCycles, gridHeight),
        ],
      ],
    );
  }

  // --- INDICATOR LOGIC ---

  Widget _buildWeeklyIndicators(int cycles) {
    if (cycles >= 7) {
      return _buildStaticPill(height: barHeight); // Tier 3
    }
    if (cycles >= 4) {
      int count = cycles - 3;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
            count,
            (i) => Padding(
                  padding: EdgeInsets.only(bottom: i < count - 1 ? 2.0 : 0),
                  child: _buildStaticPill(height: 6), // Small Pill
                )),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
          cycles,
          (i) => Padding(
                padding: EdgeInsets.only(bottom: i < cycles - 1 ? 2.0 : 0),
                child: _buildStaticPill(
                    height: 4, width: 4, isCircle: true), // Dot
              )),
    );
  }

  Widget _buildMonthlyIndicators(int cycles, double height) {
    if (cycles >= 5) {
      return _buildStaticPill(height: height); // Tier 3
    }
    if (cycles >= 3) {
      int count = cycles - 2;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
            count,
            (i) => Padding(
                  padding: EdgeInsets.only(bottom: i < count - 1 ? 2.0 : 0),
                  child: _buildStaticPill(height: 12), // Medium Pill
                )),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
          cycles,
          (i) => Padding(
                padding: EdgeInsets.only(bottom: i < cycles - 1 ? 2.0 : 0),
                child: _buildStaticPill(height: 6), // Small Pill
              )),
    );
  }

  Widget _buildYearlyIndicators(int cycles, double totalHeight) {
    int pieces = cycles > 5 ? 5 : cycles;
    double spacingTotal = (pieces - 1) * 2.0;
    double pieceHeight = (totalHeight - spacingTotal) / pieces;

    return SizedBox(
      height: totalHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(pieces, (i) {
          return _buildStaticPill(height: pieceHeight);
        }),
      ),
    );
  }

  Widget _buildStaticPill(
      {required double height, double width = 4, bool isCircle = false}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.textMain,
        borderRadius: BorderRadius.circular(isCircle ? width : 2),
      ),
    );
  }

  Widget _buildPill(bool isFilled, double w, double h) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: w,
      height: h,
      decoration: BoxDecoration(
        color:
            isFilled ? colors.textMain : colors.textSecondary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
