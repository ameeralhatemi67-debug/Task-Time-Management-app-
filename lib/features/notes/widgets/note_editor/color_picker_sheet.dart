import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';

class ColorPickerSheet extends StatefulWidget {
  final AppColors colors;
  final Color currentColor;
  final Function(Color) onColorSelected;

  const ColorPickerSheet({
    super.key,
    required this.colors,
    required this.currentColor,
    required this.onColorSelected,
  });

  @override
  State<ColorPickerSheet> createState() => _ColorPickerSheetState();
}

class _ColorPickerSheetState extends State<ColorPickerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Color _tempColor;

  static final List<Color> _recentColors = [
    Colors.black,
    Colors.blue,
    Colors.grey,
    Colors.grey.shade800,
    Colors.grey.shade900,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tempColor = widget.currentColor;
  }

  // --- Grid Generation Logic (13 Columns x 10 Rows) ---
  List<Color> _generateSamsungGrid() {
    List<Color> grid = [];
    final List<double> hues = [
      0,
      15,
      30,
      45,
      60,
      90,
      120,
      150,
      180,
      210,
      240,
      270,
      300,
    ];

    // Row 1: Grayscale
    for (int i = 0; i < 13; i++) {
      int val = 255 - ((i * 255) ~/ 12);
      grid.add(Color.fromARGB(255, val, val, val));
    }

    // Rows 2-10: Colors
    for (int row = 0; row < 9; row++) {
      for (double hue in hues) {
        final HSLColor hsl = HSLColor.fromAHSL(
          1.0,
          hue,
          1.0,
          0.9 - (row * 0.1),
        );
        grid.add(hsl.toColor());
      }
    }
    return grid;
  }

  void _saveToRecents(Color color) {
    setState(() {
      if (_recentColors.contains(color)) _recentColors.remove(color);
      _recentColors.insert(0, color);
      if (_recentColors.length > 5) _recentColors.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Dark Theme to match reference
    final Color panelBg = const Color(0xFF1C1C1C);
    final Color textCol = Colors.white;
    // Fix Overflow: Use screen percentage instead of fixed height
    final double sheetHeight = MediaQuery.of(context).size.height * 0.65;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 15),

          // 1. TABS
          Container(
            height: 32,
            width: 240,
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: const Color(0xFF555555),
                borderRadius: BorderRadius.circular(16),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              tabs: const [
                Tab(text: "Swatches"),
                Tab(text: "Spectrum"),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // 2. CONTENT
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // A. SWATCHES
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: GridView.count(
                    crossAxisCount: 13,
                    crossAxisSpacing: 1,
                    mainAxisSpacing: 1,
                    childAspectRatio: 1.0,
                    children: _generateSamsungGrid()
                        .map(
                          (c) => GestureDetector(
                            onTap: () => setState(() => _tempColor = c),
                            child: Container(color: c),
                          ),
                        )
                        .toList(),
                  ),
                ),

                // B. SPECTRUM
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        ColorPicker(
                          pickerColor: _tempColor,
                          onColorChanged: (c) => setState(() => _tempColor = c),
                          enableAlpha: false,
                          displayThumbColor: true,
                          paletteType: PaletteType.hsvWithHue,
                          pickerAreaHeightPercent: 0.6, // Reduced height
                          pickerAreaBorderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. BOTTOM PANEL
          Container(
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              20,
            ), // Added bottom padding
            color: panelBg,
            child: SafeArea(
              // Ensures it doesn't overlap gesture bar
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min, // Shrink to fit
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 25,
                        decoration: BoxDecoration(
                          color: _tempColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                      ),
                      const SizedBox(width: 15),
                      _buildInfoTag(
                        "Hex",
                        "#${_tempColor.value.toRadixString(16).substring(2).toUpperCase()}",
                        textCol,
                      ),
                      const SizedBox(width: 15),
                      _buildInfoTag("R", "${_tempColor.red}", textCol),
                      const SizedBox(width: 10),
                      _buildInfoTag("G", "${_tempColor.green}", textCol),
                      const SizedBox(width: 10),
                      _buildInfoTag("B", "${_tempColor.blue}", textCol),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ..._recentColors.take(5).map(
                            (c) => GestureDetector(
                              onTap: () => setState(() => _tempColor = c),
                              child: Container(
                                margin: const EdgeInsets.only(right: 10),
                                width: 30,
                                height: 30, // Slightly smaller
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24),
                                ),
                              ),
                            ),
                          ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _saveToRecents(_tempColor);
                          widget.onColorSelected(_tempColor);
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Done",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTag(String label, String value, Color textColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 9),
        ),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
