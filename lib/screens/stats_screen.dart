// lib/screens/stats_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../models/score_entry.dart';
import '../data/dropdown_values.dart';
import '../main.dart';
import '../widgets/app_drawer.dart';
import '../widgets/help_icon_button.dart';
import '../utils/help_content.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  StatsScreenState createState() => StatsScreenState();
}

class StatsScreenState extends State<StatsScreen> {
  String selectedPractice = 'All';
  String selectedCaliber = 'All';
  String selectedFirearmId = 'All';
  String selectedDateRange = 'All';
  
  DateTime? customFromDate;
  DateTime? customToDate;
  
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  
  bool isFiltersExpanded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    fromDateController.dispose();
    toDateController.dispose();
    super.dispose();
  }

  // Get filter lists with "All" option
  List<String> get practiceFilterList {
    final favorites = DropdownValues.practices.where((p) => p.isNotEmpty).toList();
    return ['All', ...favorites];
  }

  List<String> get caliberFilterList {
    final favorites = DropdownValues.calibers.where((c) => c.isNotEmpty).toList();
    return ['All', ...favorites];
  }

  List<String> get firearmIdFilterList {
    final favorites = DropdownValues.firearmIds.where((f) => f.isNotEmpty).toList();
    return ['All', ...favorites];
  }

  List<String> get dateRangeOptions => [
    'All',
    'Last Month',
    'Last Quarter',
    'Last Year',
    'Custom',
  ];

  DateTime _getDateRangeStart() {
    final now = DateTime.now();
    switch (selectedDateRange) {
      case 'Last Month':
        return DateTime(now.year, now.month - 1, now.day);
      case 'Last Quarter':
        return DateTime(now.year, now.month - 3, now.day);
      case 'Last Year':
        return DateTime(now.year - 1, now.month, now.day);
      case 'Custom':
        return customFromDate ?? DateTime(2000);
      default:
        return DateTime(2000);
    }
  }

  DateTime _getDateRangeEnd() {
    final now = DateTime.now();
    switch (selectedDateRange) {
      case 'Custom':
        return customToDate ?? now;
      default:
        return now;
    }
  }

  List<ScoreEntry> _getFilteredEntries() {
    final box = Hive.box<ScoreEntry>('scores');
    final allEntries = box.values.toList().cast<ScoreEntry>();

    final startDate = _getDateRangeStart();
    final endDate = _getDateRangeEnd();

    return allEntries.where((entry) {
      final matchesPractice = (selectedPractice == 'All' || entry.practice == selectedPractice);
      final matchesCaliber = (selectedCaliber == 'All' || entry.caliber == selectedCaliber);
      final matchesFirearm = (selectedFirearmId == 'All' || entry.firearmId == selectedFirearmId);
      final matchesDateRange = entry.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          entry.date.isBefore(endDate.add(const Duration(days: 1)));
      
      return matchesPractice && matchesCaliber && matchesFirearm && matchesDateRange;
    }).toList();
  }

  Map<String, int> _calculateZoneTotals(List<ScoreEntry> entries) {
    final totals = {
      'X': 0,
      '10': 0,
      '9': 0,
      '8': 0,
      '7': 0,
      '6': 0,
      '5': 0,
      '4': 0,
      '3': 0,
      '2': 0,
      '1': 0,
      '0': 0,
    };

    for (final entry in entries) {
      totals['X'] = totals['X']! + (entry.scoreX ?? 0);
      totals['10'] = totals['10']! + (entry.score10 ?? 0);
      totals['9'] = totals['9']! + (entry.score9 ?? 0);
      totals['8'] = totals['8']! + (entry.score8 ?? 0);
      totals['7'] = totals['7']! + (entry.score7 ?? 0);
      totals['6'] = totals['6']! + (entry.score6 ?? 0);
      totals['5'] = totals['5']! + (entry.score5 ?? 0);
      totals['4'] = totals['4']! + (entry.score4 ?? 0);
      totals['3'] = totals['3']! + (entry.score3 ?? 0);
      totals['2'] = totals['2']! + (entry.score2 ?? 0);
      totals['1'] = totals['1']! + (entry.score1 ?? 0);
      totals['0'] = totals['0']! + (entry.score0 ?? 0);
    }

    return totals;
  }

  int _getTotalScore(Map<String, int> zoneTotals) {
    int total = 0;
    total += (zoneTotals['X'] ?? 0) * 10; // X counts as 10
    total += (zoneTotals['10'] ?? 0) * 10;
    total += (zoneTotals['9'] ?? 0) * 9;
    total += (zoneTotals['8'] ?? 0) * 8;
    total += (zoneTotals['7'] ?? 0) * 7;
    total += (zoneTotals['6'] ?? 0) * 6;
    total += (zoneTotals['5'] ?? 0) * 5;
    total += (zoneTotals['4'] ?? 0) * 4;
    total += (zoneTotals['3'] ?? 0) * 3;
    total += (zoneTotals['2'] ?? 0) * 2;
    total += (zoneTotals['1'] ?? 0) * 1;
    // 0 adds nothing
    return total;
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate 
          ? (customFromDate ?? DateTime.now())
          : (customToDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          customFromDate = picked;
          fromDateController.text = '${picked.day}/${picked.month}/${picked.year}';
        } else {
          customToDate = picked;
          toDateController.text = '${picked.day}/${picked.month}/${picked.year}';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = themeProvider.primaryColor;

    final filteredEntries = _getFilteredEntries();
    final zoneTotals = _calculateZoneTotals(filteredEntries);
    final totalScore = _getTotalScore(zoneTotals);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) {
          return;
        }
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
        drawer: const AppDrawer(currentRoute: 'stats'),
        appBar: AppBar(
          elevation: 0,
          title: const Text(
            'Score Stats',
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
              title: 'Score Stats Help',
              content: HelpContent.historyScreen, // You may want to add specific help content
            ),
          ],
        ),
        body: SafeArea(
          bottom: true,
          child: Column(
            children: [
              // Top panel - Collapsible Filters
              Container(
                margin: const EdgeInsets.all(12),
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
                    // Collapsible header
                    InkWell(
                      onTap: () {
                        setState(() {
                          isFiltersExpanded = !isFiltersExpanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.filter_list, color: primaryColor, size: 18),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              "Filters",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              isFiltersExpanded ? Icons.expand_less : Icons.expand_more,
                              color: primaryColor,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Expandable filter content
                    if (isFiltersExpanded) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // First row - Practice
                            _buildDropdown(
                              label: 'Practice',
                              value: selectedPractice,
                              items: practiceFilterList,
                              onChanged: (v) => setState(() => selectedPractice = v!),
                              primaryColor: primaryColor,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 12),
                            // Second row - Caliber + Firearm
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDropdown(
                                    label: 'Caliber',
                                    value: selectedCaliber,
                                    items: caliberFilterList,
                                    onChanged: (v) => setState(() => selectedCaliber = v!),
                                    primaryColor: primaryColor,
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: _buildDropdown(
                                    label: 'Firearm',
                                    value: selectedFirearmId,
                                    items: firearmIdFilterList,
                                    onChanged: (v) => setState(() => selectedFirearmId = v!),
                                    primaryColor: primaryColor,
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Third row - Date Range
                            _buildDropdown(
                              label: 'Date Range',
                              value: selectedDateRange,
                              items: dateRangeOptions,
                              onChanged: (v) => setState(() {
                                selectedDateRange = v!;
                                if (v != 'Custom') {
                                  customFromDate = null;
                                  customToDate = null;
                                  fromDateController.clear();
                                  toDateController.clear();
                                }
                              }),
                              primaryColor: primaryColor,
                              isDark: isDark,
                            ),
                            // Custom date range fields (if selected)
                            if (selectedDateRange == 'Custom') ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: fromDateController,
                                      readOnly: true,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? Colors.white : Colors.black,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'From Date',
                                        labelStyle: const TextStyle(fontSize: 12),
                                        hintText: 'Select date',
                                        suffixIcon: Icon(Icons.calendar_today, color: primaryColor, size: 16),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                                      onTap: () => _selectDate(context, true),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: toDateController,
                                      readOnly: true,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? Colors.white : Colors.black,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'To Date',
                                        labelStyle: const TextStyle(fontSize: 12),
                                        hintText: 'Select date',
                                        suffixIcon: Icon(Icons.calendar_today, color: primaryColor, size: 16),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                                      onTap: () => _selectDate(context, false),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Bottom panel - Stats table
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
                  child: filteredEntries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bar_chart,
                                size: 64,
                                color: primaryColor.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No data available for selected filters',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.table_chart, color: primaryColor, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Score Zone Statistics',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${filteredEntries.length} target${filteredEntries.length == 1 ? '' : 's'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: _buildScrollableStatsTable(filteredEntries, zoneTotals, totalScore, primaryColor, isDark),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required Color primaryColor,
    required bool isDark,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isDense: true,
      isExpanded: true,
      style: TextStyle(
        fontSize: 13,
        color: isDark ? Colors.white : Colors.black,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(item, style: const TextStyle(fontSize: 13)),
      )).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildScrollableStatsTable(List<ScoreEntry> entries, Map<String, int> zoneTotals, int totalScore, Color primaryColor, bool isDark) {
    final zones = ['X', '10', '9', '8', '7', '6', '5', '4', '3', '2', '1', '0'];
    final totalHits = zoneTotals.values.fold<int>(0, (sum, hits) => sum + hits);
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed left column - Score Zone
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: 100,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: Center(
                    child: Text(
                      'Score\nZone',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                // Data rows
                ...zones.map((zone) {
                  return Container(
                    width: 100,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: borderColor)),
                    ),
                    child: Center(
                      child: Text(
                        zone,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  );
                }),
                // Total row
                Container(
                  width: 100,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.05),
                  ),
                  child: Center(
                    child: Text(
                      'Total',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Scrollable middle section - Individual targets
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Individual target columns
                  ...entries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final scoreEntry = entry.value;
                    return _buildTargetColumn(scoreEntry, index + 1, zones, primaryColor, isDark, borderColor);
                  }),
                  // Total column
                  _buildTotalColumn(zoneTotals, totalHits, zones, primaryColor, isDark, borderColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetColumn(ScoreEntry entry, int targetNumber, List<String> zones, Color primaryColor, bool isDark, Color borderColor) {
    // Calculate totals for this entry
    final entryZoneTotals = {
      'X': entry.scoreX ?? 0,
      '10': entry.score10 ?? 0,
      '9': entry.score9 ?? 0,
      '8': entry.score8 ?? 0,
      '7': entry.score7 ?? 0,
      '6': entry.score6 ?? 0,
      '5': entry.score5 ?? 0,
      '4': entry.score4 ?? 0,
      '3': entry.score3 ?? 0,
      '2': entry.score2 ?? 0,
      '1': entry.score1 ?? 0,
      '0': entry.score0 ?? 0,
    };
    
    final totalHits = entryZoneTotals.values.fold<int>(0, (sum, hits) => sum + hits);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: borderColor),
          top: BorderSide(color: borderColor),
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: 120,
            height: 48,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Center(
              child: Text(
                'Target $targetNumber',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          // Data rows
          ...zones.map((zone) {
            final hits = entryZoneTotals[zone] ?? 0;
            final percentage = totalHits > 0 
                ? ((hits / totalHits) * 100).toStringAsFixed(1)
                : '0.0';
            final displayText = hits > 0 ? '$hits ($percentage%)' : '-';
            
            return Container(
              width: 120,
              height: 48,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Center(
                child: Text(
                  displayText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            );
          }),
          // Total row
          Container(
            width: 120,
            height: 48,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.05),
            ),
            child: Center(
              child: Text(
                '$totalHits (100%)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalColumn(Map<String, int> zoneTotals, int totalHits, List<String> zones, Color primaryColor, bool isDark, Color borderColor) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: borderColor),
          top: BorderSide(color: borderColor),
          bottom: BorderSide(color: borderColor),
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: 120,
            height: 48,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.15),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Center(
              child: Text(
                'All Targets',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          // Data rows
          ...zones.map((zone) {
            final hits = zoneTotals[zone] ?? 0;
            final percentage = totalHits > 0 
                ? ((hits / totalHits) * 100).toStringAsFixed(1)
                : '0.0';
            final displayText = hits > 0 ? '$hits ($percentage%)' : '-';
            
            return Container(
              width: 120,
              height: 48,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Center(
                child: Text(
                  displayText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            );
          }),
          // Total row
          Container(
            width: 120,
            height: 48,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
            ),
            child: Center(
              child: Text(
                '$totalHits (100%)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


}
