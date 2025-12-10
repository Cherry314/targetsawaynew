// lib/screens/progress_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/score_entry.dart';
import '../data/dropdown_values.dart';
import '../main.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  ProgressScreenState createState() => ProgressScreenState();
}

class ProgressScreenState extends State<ProgressScreen> {
  String? selectedPractice;
  String? selectedCaliber;
  String? selectedFirearmId;

  List<ScoreEntry> filteredEntries = [];

  void _filterEntries() {
    final box = Hive.box<ScoreEntry>('scores');
    final allEntries = box.values.toList().cast<ScoreEntry>();

    setState(() {
      filteredEntries = allEntries.where((entry) {
        final matchesPractice = selectedPractice == null || entry.practice == selectedPractice;
        final matchesCaliber = selectedCaliber == null || entry.caliber == selectedCaliber;
        final matchesFirearm = selectedFirearmId == null || entry.firearmId == selectedFirearmId;
        return matchesPractice && matchesCaliber && matchesFirearm;
      }).toList();

      filteredEntries.sort((a, b) => a.date.compareTo(b.date));
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.primaryColor;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    Widget dropdowns = isLandscape
        ? Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _buildPracticeDropdown(primaryColor)),
        const SizedBox(width: 8),
        Expanded(child: _buildCaliberDropdown(primaryColor)),
        const SizedBox(width: 8),
        Expanded(child: _buildFirearmDropdown(primaryColor)),
      ],
    )
        : Column(
      children: [
        _buildPracticeDropdown(primaryColor),
        const SizedBox(height: 8),
        _buildCaliberDropdown(primaryColor),
        const SizedBox(height: 8),
        _buildFirearmDropdown(primaryColor),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Graph'),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              dropdowns,
              const SizedBox(height: 16),
              Expanded(
                child: filteredEntries.isEmpty
                    ? Center(
                  child: Text(
                    'Select filters to display graph',
                    style: TextStyle(color: primaryColor),
                  ),
                )
                    : _buildLineChart(primaryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPracticeDropdown(Color primaryColor) {
    return DropdownButtonFormField<String>(
      initialValue: selectedPractice,
      decoration: InputDecoration(
        labelText: 'Practice',
        labelStyle: TextStyle(color: primaryColor),
        border: const OutlineInputBorder(),
      ),
      items: DropdownValues.practices
          .map((p) => DropdownMenuItem(
          value: p, child: Text(p, style: TextStyle(color: primaryColor))))
          .toList(),
      onChanged: (v) {
        setState(() => selectedPractice = v);
        _filterEntries();
      },
    );
  }

  Widget _buildCaliberDropdown(Color primaryColor) {
    return DropdownButtonFormField<String>(
      initialValue: selectedCaliber,
      decoration: InputDecoration(
        labelText: 'Calibre',
        labelStyle: TextStyle(color: primaryColor),
        border: const OutlineInputBorder(),
      ),
      items: DropdownValues.calibers
          .map((c) => DropdownMenuItem(
          value: c, child: Text(c, style: TextStyle(color: primaryColor))))
          .toList(),
      onChanged: (v) {
        setState(() => selectedCaliber = v);
        _filterEntries();
      },
    );
  }

  Widget _buildFirearmDropdown(Color primaryColor) {
    return DropdownButtonFormField<String>(
      initialValue: selectedFirearmId,
      decoration: InputDecoration(
        labelText: 'Firearm ID',
        labelStyle: TextStyle(color: primaryColor),
        border: const OutlineInputBorder(),
      ),
      items: DropdownValues.firearmIds
          .map((f) => DropdownMenuItem(
          value: f, child: Text(f, style: TextStyle(color: primaryColor))))
          .toList(),
      onChanged: (v) {
        setState(() => selectedFirearmId = v);
        _filterEntries();
      },
    );
  }
//---------------------------


  Widget _buildLineChart(Color primaryColor) {
    if (filteredEntries.isEmpty) return const SizedBox.shrink();

    final spots = filteredEntries
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.score.toDouble()))
        .toList();

    // Extract dates
    final dates = filteredEntries.map((e) => e.date).toList();

    // Unique years for range indicators
    final yearRanges = <int, List<int>>{};
    for (int i = 0; i < dates.length; i++) {
      final year = dates[i].year;
      yearRanges.putIfAbsent(year, () => []).add(i);
    }

    // Y-axis unique scores
    final yValues = filteredEntries.map((e) => e.score).toSet().toList()..sort();

    // Add top and bottom padding to prevent line from being clipped
    double minY = yValues.isNotEmpty ? yValues.first.toDouble() : 0;
    double maxY = yValues.isNotEmpty ? yValues.last.toDouble() : 0;
    double yRange = maxY - minY;
    if (yRange == 0) yRange = maxY * 0.1; // avoid zero range
    minY = minY - yRange * 0.1;
    maxY = maxY + yRange * 0.1;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0, left: 8.0, bottom: 30.0),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(enabled: true),
          gridData: FlGridData(show: false),
          clipData: FlClipData.all(),
          titlesData: FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (yValues.contains(value.toInt())) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(fontSize: 12, color: primaryColor),
                      textAlign: TextAlign.right,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
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
                        style: TextStyle(fontSize: 10, color: primaryColor),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: spots.isNotEmpty ? spots.length - 1.toDouble() : 0,
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 3,
              dotData: FlDotData(show: true),
              color: primaryColor,
            ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: [],
            verticalLines: [],
          ),
          betweenBarsData: [],
        ),
      ),
    );
  }



}
