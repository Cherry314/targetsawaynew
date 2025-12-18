// lib/screens/progress_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/score_entry.dart';
import '../data/dropdown_values.dart';
import '../main.dart';
import '../widgets/app_drawer.dart';
import '../widgets/help_icon_button.dart';
import '../utils/help_content.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  ProgressScreenState createState() => ProgressScreenState();
}

enum ChartType { straight, curved, bar, stepped }

class ProgressScreenState extends State<ProgressScreen> {
  String? selectedPractice;
  String? selectedCaliber;
  String? selectedFirearmId;
  ChartType selectedChartType = ChartType.straight;

  List<ScoreEntry> filteredEntries = [];
  int? selectedLineChartIndex;
  int? selectedBarChartIndex;

  void _filterEntries() {
    final box = Hive.box<ScoreEntry>('scores');
    final allEntries = box.values.toList().cast<ScoreEntry>();

    setState(() {
      filteredEntries = allEntries.where((entry) {
        final matchesPractice = selectedPractice == null ||
            entry.practice == selectedPractice;
        final matchesCaliber = selectedCaliber == null ||
            entry.caliber == selectedCaliber;
        final matchesFirearm = selectedFirearmId == null ||
            entry.firearmId == selectedFirearmId;
        return matchesPractice && matchesCaliber && matchesFirearm;
      }).toList();

      filteredEntries.sort((a, b) => a.date.compareTo(b.date));

      // Reset selections when filters change
      selectedLineChartIndex = null;
      selectedBarChartIndex = null;
    });
  }

  String _getChartTypeLabel(ChartType type) {
    switch (type) {
      case ChartType.straight:
        return 'Straight Line';
      case ChartType.curved:
        return 'Curved Line';
      case ChartType.bar:
        return 'Bar Chart';
      case ChartType.stepped:
        return 'Stepped Line';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.primaryColor;
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
      drawer: const AppDrawer(currentRoute: 'progress'),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Progress Graph',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: const [
          HelpIconButton(
            title: 'Progress Graph Help',
            content: HelpContent.progressScreen,
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: Column(
        children: [
          // Compact Filter Section
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                          Icons.filter_list, color: primaryColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Filters",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _buildPracticeDropdown(primaryColor, isDark)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _buildCaliberDropdown(primaryColor, isDark)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _buildFirearmDropdown(primaryColor, isDark)),
                  ],
                ),
              ],
            ),
          ),

          // Chart Type Selector
          if (filteredEntries.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.show_chart, color: primaryColor, size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    'Chart Style:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<ChartType>(
                      initialValue: selectedChartType,
                      isDense: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                      ),
                      items: ChartType.values
                          .map((type) =>
                          DropdownMenuItem(
                            value: type,
                            child: Text(
                              _getChartTypeLabel(type),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedChartType = value;
                            selectedLineChartIndex = null;
                            selectedBarChartIndex = null;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Chart Section
          Expanded(
            child: filteredEntries.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_graph,
                    size: 64,
                    color: primaryColor.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select filters to display graph',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
                : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildChart(primaryColor, isDark),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildPracticeDropdown(Color primaryColor, bool isDark) {
    return DropdownButtonFormField<String>(
      initialValue: selectedPractice,
      isDense: true,
      isExpanded: true,
      style: TextStyle(
        fontSize: 13,
        color: isDark ? Colors.white : Colors.black,
      ),
      decoration: InputDecoration(
        labelText: 'Practice',
        labelStyle: const TextStyle(fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
      ),
      items: DropdownValues.practices
          .map((p) =>
          DropdownMenuItem(
            value: p,
            child: Text(p, style: const TextStyle(fontSize: 13)),
          ))
          .toList(),
      onChanged: (v) {
        setState(() => selectedPractice = v);
        _filterEntries();
      },
    );
  }

  Widget _buildCaliberDropdown(Color primaryColor, bool isDark) {
    return DropdownButtonFormField<String>(
      initialValue: selectedCaliber,
      isDense: true,
      isExpanded: true,
      style: TextStyle(
        fontSize: 13,
        color: isDark ? Colors.white : Colors.black,
      ),
      decoration: InputDecoration(
        labelText: 'Caliber',
        labelStyle: const TextStyle(fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
      ),
      items: DropdownValues.calibers
          .map((c) =>
          DropdownMenuItem(
            value: c,
            child: Text(c, style: const TextStyle(fontSize: 13)),
          ))
          .toList(),
      onChanged: (v) {
        setState(() => selectedCaliber = v);
        _filterEntries();
      },
    );
  }

  Widget _buildFirearmDropdown(Color primaryColor, bool isDark) {
    return DropdownButtonFormField<String>(
      initialValue: selectedFirearmId,
      isDense: true,
      isExpanded: true,
      style: TextStyle(
        fontSize: 13,
        color: isDark ? Colors.white : Colors.black,
      ),
      decoration: InputDecoration(
        labelText: 'Firearm',
        labelStyle: const TextStyle(fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
      ),
      items: DropdownValues.firearmIds
          .map((f) =>
          DropdownMenuItem(
            value: f,
            child: Text(f, style: const TextStyle(fontSize: 13)),
          ))
          .toList(),
      onChanged: (v) {
        setState(() => selectedFirearmId = v);
        _filterEntries();
      },
    );
  }

  Widget _buildChart(Color primaryColor, bool isDark) {
    if (filteredEntries.isEmpty) return const SizedBox.shrink();

    // For bar chart, use a different method
    if (selectedChartType == ChartType.bar) {
      return _buildBarChart(primaryColor, isDark);
    }

    // For line charts (straight, curved, stepped)
    return _buildLineChart(primaryColor, isDark);
  }

  Widget _buildLineChart(Color primaryColor, bool isDark) {
    final spots = filteredEntries
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.score.toDouble()))
        .toList();

    // Extract dates
    final dates = filteredEntries.map((e) => e.date).toList();

    // Y-axis unique scores
    final yValues = filteredEntries.map((e) => e.score).toSet().toList()
      ..sort();

    // Add top and bottom padding to prevent line from being clipped
    double minY = yValues.isNotEmpty ? yValues.first.toDouble() : 0;
    double maxY = yValues.isNotEmpty ? yValues.last.toDouble() : 0;
    double yRange = maxY - minY;
    if (yRange == 0) yRange = maxY * 0.1; // avoid zero range
    minY = minY - yRange * 0.1;
    maxY = maxY + yRange * 0.1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Tap score dot for details',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: false,
                  touchSpotThreshold: 30,
                  touchCallback: (FlTouchEvent event,
                      LineTouchResponse? touchResponse) {
                    if (event is FlTapUpEvent || event is FlPanEndEvent) {
                      if (touchResponse != null &&
                          touchResponse.lineBarSpots != null &&
                          touchResponse.lineBarSpots!.isNotEmpty) {
                        final spot = touchResponse.lineBarSpots!.first;
                        setState(() {
                          if (selectedLineChartIndex == spot.x.toInt()) {
                            selectedLineChartIndex = null;
                          } else {
                            selectedLineChartIndex = spot.x.toInt();
                          }
                        });
                      } else {
                        // Tapped on empty area, clear selection
                        setState(() {
                          selectedLineChartIndex = null;
                        });
                      }
                    }
                  },
                  getTouchedSpotIndicator: (LineChartBarData barData,
                      List<int> spotIndexes) {
                    return spotIndexes.map((index) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: primaryColor.withValues(alpha: 0.5),
                          strokeWidth: 2,
                        ),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) =>
                              FlDotCirclePainter(
                                radius: 6,
                                color: primaryColor,
                                strokeWidth: 3,
                                strokeColor: Colors.white,
                              ),
                        ),
                      );
                    }).toList();
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) =>
                        primaryColor.withValues(alpha: 0.8),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final date = dates[spot.x.toInt()];
                        return LineTooltipItem(
                          'Score: ${spot.y.toInt()}\n${date.day}/${date
                              .month}/${date.year}',
                          const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
                showingTooltipIndicators: selectedLineChartIndex != null
                    ? [
                  ShowingTooltipIndicators([
                    LineBarSpot(
                      LineChartBarData(
                        spots: spots,
                        color: primaryColor,
                        isCurved: selectedChartType == ChartType.curved,
                        curveSmoothness: selectedChartType == ChartType.curved
                            ? 0.3
                            : 0,
                        isStepLineChart: selectedChartType == ChartType.stepped,
                        barWidth: 3,
                      ),
                      0,
                      spots[selectedLineChartIndex!],
                    ),
                  ])
                ]
                    : [],
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                clipData: FlClipData.all(),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < dates.length) {
                          final date = dates[index];
                          final dayMonth = "${date.day}/${date.month}";
                          return Transform.rotate(
                            angle: -1.57, // vertical
                            child: Text(
                              dayMonth,
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? Colors.grey[400] : Colors
                                    .grey[600],
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        width: 1),
                    bottom: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        width: 1),
                  ),
                ),
                minX: 0,
                maxX: spots.isNotEmpty ? spots.length - 1.toDouble() : 0,
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: selectedChartType == ChartType.curved,
                    curveSmoothness: selectedChartType == ChartType.curved
                        ? 0.3
                        : 0,
                    isStepLineChart: selectedChartType == ChartType.stepped,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: primaryColor,
                        );
                      },
                    ),
                    color: primaryColor,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withValues(alpha: 0.3),
                          primaryColor.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(Color primaryColor, bool isDark) {
    if (filteredEntries.isEmpty) return const SizedBox.shrink();

    // Extract dates
    final dates = filteredEntries.map((e) => e.date).toList();

    // Y-axis unique scores
    final yValues = filteredEntries.map((e) => e.score).toSet().toList()
      ..sort();

    // Add top and bottom padding
    double minY = yValues.isNotEmpty ? yValues.first.toDouble() : 0;
    double maxY = yValues.isNotEmpty ? yValues.last.toDouble() : 0;
    double yRange = maxY - minY;
    if (yRange == 0) yRange = maxY * 0.1;
    minY = minY - yRange * 0.1;
    maxY = maxY + yRange * 0.1;

    final barGroups = filteredEntries
        .asMap()
        .entries
        .map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.score.toDouble(),
            color: primaryColor,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            gradient: LinearGradient(
              colors: [
                primaryColor,
                primaryColor.withValues(alpha: 0.7),
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ],
        showingTooltipIndicators: selectedBarChartIndex == entry.key ? [0] : [],
      );
    }).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Tap bar for details',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                minY: minY,
                barTouchData: BarTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchCallback: (FlTouchEvent event,
                      BarTouchResponse? touchResponse) {
                    if (event is FlTapUpEvent) {
                      if (touchResponse != null && touchResponse.spot != null) {
                        final barIndex = touchResponse.spot!
                            .touchedBarGroupIndex;
                        setState(() {
                          if (selectedBarChartIndex == barIndex) {
                            selectedBarChartIndex = null;
                          } else {
                            selectedBarChartIndex = barIndex;
                          }
                        });
                      } else {
                        setState(() {
                          selectedBarChartIndex = null;
                        });
                      }
                    }
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => primaryColor.withValues(
                        alpha: 0.8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final date = dates[group.x.toInt()];
                      return BarTooltipItem(
                        'Score: ${rod.toY.toInt()}\n${date.day}/${date
                            .month}/${date.year}',
                        const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < dates.length) {
                          final date = dates[index];
                          final dayMonth = "${date.day}/${date.month}";
                          return Transform.rotate(
                            angle: -1.57,
                            child: Text(
                              dayMonth,
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? Colors.grey[400] : Colors
                                    .grey[600],
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      width: 1,
                    ),
                    bottom: BorderSide(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                ),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
