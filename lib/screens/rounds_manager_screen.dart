// lib/screens/rounds_manager_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
