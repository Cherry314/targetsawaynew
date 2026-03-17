// lib/screens/rounds_manager_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../main.dart';
import '../models/rounds_counter_entry.dart';
import '../widgets/app_drawer.dart';

class RoundsManagerScreen extends StatelessWidget {
  const RoundsManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = themeProvider.primaryColor;

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
        drawer: const AppDrawer(currentRoute: 'rounds_manager'),
        appBar: AppBar(
          elevation: 0,
          title: const Text(
            'Rounds Manager',
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
          actions: [
            IconButton(
              icon: const Icon(Icons.file_upload_outlined),
              onPressed: () => _showExportDialog(context),
              tooltip: 'Export to CSV',
            ),
          ],
        ),
        body: SafeArea(
          bottom: true,
          child: ValueListenableBuilder(
            valueListenable: Hive.box<RoundsCounterEntry>('rounds_counter').listenable(),
            builder: (context, Box<RoundsCounterEntry> box, _) {
              final entries = box.values.toList();

              // Sort by date descending
              entries.sort((a, b) => b.date.compareTo(a.date));

              // Group entries by month/year
              final groupedEntries = _groupEntriesByMonth(entries);

              if (entries.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.track_changes,
                        size: 64,
                        color: primaryColor.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No rounds recorded yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: groupedEntries.length,
                      itemBuilder: (context, index) {
                        final group = groupedEntries[index];
                        final monthYear = group['monthYear'] as String;
                        final monthEntries = group['entries'] as List<RoundsCounterEntry>;
                        final monthlyTotal = group['total'] as int;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Month header with total
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_month,
                                          color: primaryColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          monthYear,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '$monthlyTotal rounds',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // List of entries for this month
                              ...monthEntries.map((entry) {
                                return _buildEntryRow(
                                  entry: entry,
                                  primaryColor: primaryColor,
                                  isDark: isDark,
                                  context: context,
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // Manual Entry Button
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showManualEntryDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text(
                          'Manual Entry',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _groupEntriesByMonth(
      List<RoundsCounterEntry> entries) {
    final groups = <String, List<RoundsCounterEntry>>{};

    for (final entry in entries) {
      final monthYear = DateFormat('MMMM yyyy').format(entry.date);
      groups.putIfAbsent(monthYear, () => []).add(entry);
    }

    return groups.entries.map((e) {
      final total = e.value.fold<int>(0, (sum, entry) => sum + entry.rounds);
      return {
        'monthYear': e.key,
        'entries': e.value,
        'total': total,
      };
    }).toList();
  }

  Widget _buildEntryRow({
    required RoundsCounterEntry entry,
    required Color primaryColor,
    required bool isDark,
    required BuildContext context,
  }) {
    final hasNotes = entry.notes != null && entry.notes!.isNotEmpty;
    final hasEvent = entry.event != null && entry.event!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Date
            SizedBox(
              width: 80,
              child: Text(
                DateFormat('dd/MM/yy').format(entry.date),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            // Rounds
            Container(
              width: 60,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${entry.rounds}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Reason
            Expanded(
              child: Text(
                entry.reason,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            // Event icon (only if event exists)
            if (hasEvent)
              IconButton(
                icon: Icon(
                  Icons.track_changes,
                  color: primaryColor,
                  size: 20,
                ),
                onPressed: () {
                  _showEventDialog(context, entry);
                },
                tooltip: 'View Event',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
              ),
            // Notes icon (only if notes exist)
            if (hasNotes)
              IconButton(
                icon: Icon(
                  Icons.note,
                  color: primaryColor,
                  size: 20,
                ),
                onPressed: () {
                  _showNotesDialog(context, entry);
                },
                tooltip: 'View Notes',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showManualEntryDialog(BuildContext parentContext) {
    Navigator.push(
      parentContext,
      MaterialPageRoute(
        builder: (context) => const _ManualEntryScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  void _showNotesDialog(BuildContext context, RoundsCounterEntry entry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Provider.of<ThemeProvider>(context, listen: false).primaryColor;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.note, color: primaryColor),
            const SizedBox(width: 8),
            const Text('Notes'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date: ${DateFormat('dd MMMM yyyy').format(entry.date)}',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rounds: ${entry.rounds}',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            Text(
              'Reason: ${entry.reason}',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              entry.notes ?? '',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEventDialog(BuildContext context, RoundsCounterEntry entry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Provider.of<ThemeProvider>(context, listen: false).primaryColor;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.track_changes, color: primaryColor),
            const SizedBox(width: 8),
            const Text('Event / Practice'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date: ${DateFormat('dd MMMM yyyy').format(entry.date)}',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rounds: ${entry.rounds}',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            Text(
              'Reason: ${entry.reason}',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Event/Practice:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              entry.event ?? '',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Export dialog - Step 1: Choose Format
  void _showExportDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Provider.of<ThemeProvider>(context, listen: false).primaryColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.file_upload, color: primaryColor, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Export Rounds Data',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose export format',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                // CSV Option
                _buildExportOption(
                  context,
                  'CSV File',
                  'Spreadsheet format for Excel or other apps',
                  Icons.table_chart,
                  primaryColor,
                  isDark,
                  () => _showDateRangeDialog(context, ExportFormat.csv),
                ),
                const SizedBox(height: 12),
                // PDF Option
                _buildExportOption(
                  context,
                  'PDF Document',
                  'Formatted document for printing or sharing',
                  Icons.picture_as_pdf,
                  primaryColor,
                  isDark,
                  () => _showDateRangeDialog(context, ExportFormat.pdf),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // Export dialog - Step 2: Choose Date Range
  void _showDateRangeDialog(BuildContext context, ExportFormat format) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Provider.of<ThemeProvider>(context, listen: false).primaryColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.date_range, color: primaryColor, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Select Date Range',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  format == ExportFormat.csv ? 'Export as CSV' : 'Export as PDF',
                  style: TextStyle(
                    fontSize: 14,
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                _buildExportOption(
                  context,
                  'All',
                  'Export all recorded rounds',
                  Icons.calendar_view_month,
                  primaryColor,
                  isDark,
                  () => _exportRounds(context, ExportRange.all, format),
                ),
                const SizedBox(height: 12),
                _buildExportOption(
                  context,
                  'Last Month',
                  DateFormat('MMMM yyyy').format(DateTime.now().subtract(const Duration(days: 30))),
                  Icons.calendar_month,
                  primaryColor,
                  isDark,
                  () => _exportRounds(context, ExportRange.lastMonth, format),
                ),
                const SizedBox(height: 12),
                _buildExportOption(
                  context,
                  'Last Quarter',
                  'Last 3 months',
                  Icons.view_quilt,
                  primaryColor,
                  isDark,
                  () => _exportRounds(context, ExportRange.lastQuarter, format),
                ),
                const SizedBox(height: 12),
                _buildExportOption(
                  context,
                  'Last 6 Months',
                  'Last 6 months',
                  Icons.date_range,
                  primaryColor,
                  isDark,
                  () => _exportRounds(context, ExportRange.last6Months, format),
                ),
                const SizedBox(height: 12),
                _buildExportOption(
                  context,
                  'Custom Range',
                  'Select start and end dates',
                  Icons.edit_calendar,
                  primaryColor,
                  isDark,
                  () {
                    Navigator.pop(context);
                    _showCustomDateRangeDialog(context, format);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExportOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color primaryColor,
    bool isDark,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: primaryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: isDark ? Colors.grey[500] : Colors.grey[400],
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Custom date range dialog
  void _showCustomDateRangeDialog(BuildContext context, ExportFormat format) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Provider.of<ThemeProvider>(context, listen: false).primaryColor;

    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.date_range, color: primaryColor),
                  const SizedBox(width: 8),
                  const Text('Custom Date Range'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Start Date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          startDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: primaryColor, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  startDate != null
                                      ? DateFormat('dd/MM/yyyy').format(startDate!)
                                      : 'Select date',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: startDate != null
                                        ? (isDark ? Colors.white : Colors.black)
                                        : (isDark ? Colors.grey[500] : Colors.grey[500]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // End Date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          endDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: primaryColor, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'End Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  endDate != null
                                      ? DateFormat('dd/MM/yyyy').format(endDate!)
                                      : 'Select date',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: endDate != null
                                        ? (isDark ? Colors.white : Colors.black)
                                        : (isDark ? Colors.grey[500] : Colors.grey[500]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (startDate != null && endDate != null)
                      ? () {
                          Navigator.pop(context);
                          _exportRounds(
                            context,
                            ExportRange.custom,
                            format,
                            customStart: startDate,
                            customEnd: endDate,
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Export'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Export rounds to CSV or PDF
  Future<void> _exportRounds(
    BuildContext context,
    ExportRange range,
    ExportFormat format, {
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    final box = Hive.box<RoundsCounterEntry>('rounds_counter');
    final allEntries = box.values.toList();
    final now = DateTime.now();
    late List<RoundsCounterEntry> filteredEntries;
    late String periodLabel;

    switch (range) {
      case ExportRange.all:
        filteredEntries = allEntries;
        periodLabel = 'All Time';
        break;
      case ExportRange.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, now.day);
        filteredEntries = allEntries.where((e) => e.date.isAfter(lastMonth)).toList();
        periodLabel = 'Last Month';
        break;
      case ExportRange.lastQuarter:
        final lastQuarter = now.subtract(const Duration(days: 90));
        filteredEntries = allEntries.where((e) => e.date.isAfter(lastQuarter)).toList();
        periodLabel = 'Last Quarter';
        break;
      case ExportRange.last6Months:
        final last6Months = now.subtract(const Duration(days: 180));
        filteredEntries = allEntries.where((e) => e.date.isAfter(last6Months)).toList();
        periodLabel = 'Last 6 Months';
        break;
      case ExportRange.custom:
        if (customStart != null && customEnd != null) {
          final start = DateTime(customStart.year, customStart.month, customStart.day);
          final end = DateTime(customEnd.year, customEnd.month, customEnd.day, 23, 59, 59);
          filteredEntries = allEntries.where((e) {
            return e.date.isAtSameMomentAs(start) ||
                   e.date.isAtSameMomentAs(end) ||
                   (e.date.isAfter(start) && e.date.isBefore(end));
          }).toList();
          periodLabel = '${DateFormat('dd/MM/yyyy').format(customStart)} - ${DateFormat('dd/MM/yyyy').format(customEnd)}';
        } else {
          filteredEntries = [];
          periodLabel = 'Custom Range';
        }
        break;
    }

    if (filteredEntries.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No data to export for the selected period'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Sort by date descending
    filteredEntries.sort((a, b) => b.date.compareTo(a.date));

    try {
      if (format == ExportFormat.csv) {
        await _exportToCSV(filteredEntries, periodLabel, context);
      } else {
        await _exportToPDF(filteredEntries, periodLabel, context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Export to CSV
  Future<void> _exportToCSV(
    List<RoundsCounterEntry> entries,
    String periodLabel,
    BuildContext context,
  ) async {
    final grouped = _groupEntriesByMonth(entries);
    final grandTotal = entries.fold<int>(0, (sum, e) => sum + e.rounds);

    final csv = StringBuffer();
    csv.writeln('Date,Rounds,Reason,Event,Notes');
    
    for (final entry in entries) {
      final dateStr = DateFormat('dd/MM/yyyy').format(entry.date);
      final roundsStr = entry.rounds.toString();
      final reasonStr = '"${entry.reason.replaceAll('"', '""')}"';
      final eventStr = '"${(entry.event ?? '').replaceAll('"', '""')}"';
      final notesStr = '"${(entry.notes ?? '').replaceAll('"', '""')}"';
      csv.writeln('$dateStr,$roundsStr,$reasonStr,$eventStr,$notesStr');
    }
    
    csv.writeln();
    csv.writeln('MONTHLY TOTALS');
    csv.writeln('Month,Total Rounds');
    for (final group in grouped) {
      final monthYear = group['monthYear'] as String;
      final total = group['total'] as int;
      csv.writeln('"$monthYear",$total');
    }
    
    csv.writeln();
    csv.writeln('GRAND TOTAL,$grandTotal');
    csv.writeln();
    csv.writeln('Export Period,$periodLabel');
    csv.writeln('Export Date,${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}');

    final tempDir = await getTemporaryDirectory();
    final fileName = 'rounds_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(csv.toString());

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Rounds Export - $periodLabel',
      text: 'Rounds export for $periodLabel',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV exported successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Export to PDF
  Future<void> _exportToPDF(
    List<RoundsCounterEntry> entries,
    String periodLabel,
    BuildContext context,
  ) async {
    final grouped = _groupEntriesByMonth(entries);
    final grandTotal = entries.fold<int>(0, (sum, e) => sum + e.rounds);

    final pdf = pw.Document();
    final exportDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Rounds Export Report',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Period: $periodLabel',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue100,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'Total: $grandTotal rounds',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Detailed Entries by Month',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              // Monthly sections with entries
              ...grouped.expand((group) {
                final monthYear = group['monthYear'] as String;
                final monthEntries = group['entries'] as List<RoundsCounterEntry>;
                final monthlyTotal = group['total'] as int;

                return [
                  // Month header with total
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          monthYear,
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800,
                          ),
                        ),
                        pw.Text(
                          'Subtotal: $monthlyTotal rounds',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  // Entries table for this month
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(2), // Date
                      1: const pw.FlexColumnWidth(1.5), // Rounds
                      2: const pw.FlexColumnWidth(3), // Reason
                      3: const pw.FlexColumnWidth(3), // Event
                      4: const pw.FlexColumnWidth(3), // Notes
                    },
                    children: [
                      // Table Header
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          _buildPdfHeaderCell('Date'),
                          _buildPdfHeaderCell('Rounds'),
                          _buildPdfHeaderCell('Reason'),
                          _buildPdfHeaderCell('Event / Practice'),
                          _buildPdfHeaderCell('Notes'),
                        ],
                      ),
                      // Data Rows
                      ...monthEntries.map((entry) => pw.TableRow(
                        children: [
                          _buildPdfCell(DateFormat('dd/MM/yyyy').format(entry.date)),
                          _buildPdfCell(entry.rounds.toString(), isNumber: true),
                          _buildPdfCell(entry.reason),
                          _buildPdfCell(entry.event ?? ''),
                          _buildPdfCell(entry.notes ?? ''),
                        ],
                      )),
                    ],
                  ),
                  pw.SizedBox(height: 16),
                ];
              }),

              pw.SizedBox(height: 20),

              // Grand Total
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue700,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'GRAND TOTAL',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      '$grandTotal rounds',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Footer
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Exported: $exportDate',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    final tempDir = await getTemporaryDirectory();
    final fileName = 'rounds_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Rounds Export - $periodLabel',
      text: 'Rounds export PDF for $periodLabel',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF exported successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  pw.Widget _buildPdfHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  pw.Widget _buildPdfCell(String text, {bool isNumber = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
        ),
        textAlign: isNumber ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    );
  }
}

enum ExportFormat {
  csv,
  pdf,
}

enum ExportRange {
  all,
  lastMonth,
  lastQuarter,
  last6Months,
  custom,
}

// Separate screen for manual entry
class _ManualEntryScreen extends StatefulWidget {
  const _ManualEntryScreen();
  
  @override
  State<_ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<_ManualEntryScreen> {
  DateTime selectedDate = DateTime.now();
  final dateController = TextEditingController();
  final roundsController = TextEditingController();
  final notesController = TextEditingController();
  String? errorMessage;
  bool isLoading = false;
  
  @override
  void initState() {
    super.initState();
    dateController.text = DateFormat('dd/MM/yyyy').format(selectedDate);
  }
  
  @override
  void dispose() {
    dateController.dispose();
    roundsController.dispose();
    notesController.dispose();
    super.dispose();
  }
  
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        selectedDate = picked;
        dateController.text = DateFormat('dd/MM/yyyy').format(picked);
        errorMessage = null;
      });
    }
  }
  
  Future<void> _saveEntry() async {
    setState(() {
      errorMessage = null;
      isLoading = true;
    });
    
    try {
      // Validate rounds field
      final roundsText = roundsController.text.trim();
      
      if (roundsText.isEmpty) {
        setState(() {
          errorMessage = 'Please enter the number of rounds';
          isLoading = false;
        });
        return;
      }

      final rounds = int.tryParse(roundsText);
      
      if (rounds == null || rounds == 0) {
        setState(() {
          errorMessage = 'Please enter a valid number of rounds (positive or negative)';
          isLoading = false;
        });
        return;
      }

      // Add entry to rounds counter
      final roundsBox = Hive.box<RoundsCounterEntry>('rounds_counter');
      
      final newEntry = RoundsCounterEntry(
        date: selectedDate,
        rounds: rounds,
        reason: 'Manual Entry',
        notes: notesController.text.trim().isNotEmpty
            ? notesController.text.trim()
            : null,
      );
      
      await roundsBox.add(newEntry);
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Manual entry added successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Close the screen
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error saving: $e';
          isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Provider.of<ThemeProvider>(context, listen: false).primaryColor;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Manual Entry',
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Error message display
                if (errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Date Field
                TextField(
                  controller: dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.date_range),
                      onPressed: _pickDate,
                    ),
                  ),
                  onTap: _pickDate,
                ),
                const SizedBox(height: 16),
                
                // Rounds Field
                TextField(
                  controller: roundsController,
                  keyboardType: const TextInputType.numberWithOptions(signed: true),
                  decoration: InputDecoration(
                    labelText: 'Rounds',
                    prefixIcon: Icon(Icons.track_changes, color: primaryColor),
                    border: const OutlineInputBorder(),
                    hintText: 'Enter number of rounds (use - for deduction)',
                  ),
                  onChanged: (value) {
                    if (errorMessage != null) {
                      setState(() {
                        errorMessage = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Notes Field
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    prefixIcon: Icon(Icons.note, color: primaryColor),
                    border: const OutlineInputBorder(),
                    hintText: 'Enter any notes (optional)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: primaryColor),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _saveEntry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
