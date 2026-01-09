import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/score_entry.dart';
import '../utils/date_utils.dart';
import '../data/dropdown_values.dart';
import 'enter_score_screen.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../widgets/app_drawer.dart';
import '../services/calendar_score_service.dart';
import '../widgets/help_icon_button.dart';
import '../utils/help_content.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  HistoryScreenState createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  String selectedPractice = 'All';
  String selectedCaliber = 'All';
  String selectedFirearmId = 'All';
  
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

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<ScoreEntry>('scores');

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
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
          drawer: const AppDrawer(currentRoute: 'history'),
          appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Previous Targets',
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
            title: 'History Help',
            content: HelpContent.historyScreen,
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
                      child: DropdownButtonFormField<String>(
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
                            borderSide: BorderSide(
                                color: primaryColor, width: 2),
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey[800] : Colors
                              .grey[50],
                        ),
                        items: practiceFilterList
                            .map((p) =>
                            DropdownMenuItem(
                              value: p,
                              child: Text(
                                  p, style: const TextStyle(fontSize: 13)),
                            ))
                            .toList(),
                        onChanged: (v) => setState(() => selectedPractice = v!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
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
                            borderSide: BorderSide(
                                color: primaryColor, width: 2),
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey[800] : Colors
                              .grey[50],
                        ),
                        items: caliberFilterList
                            .map((c) =>
                            DropdownMenuItem(
                              value: c,
                              child: Text(
                                  c, style: const TextStyle(fontSize: 13)),
                            ))
                            .toList(),
                        onChanged: (v) => setState(() => selectedCaliber = v!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
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
                            borderSide: BorderSide(
                                color: primaryColor, width: 2),
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey[800] : Colors
                              .grey[50],
                        ),
                        items: firearmIdFilterList
                            .map((f) =>
                            DropdownMenuItem(
                              value: f,
                              child: Text(
                                  f, style: const TextStyle(fontSize: 13)),
                            ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => selectedFirearmId = v!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // List of entries
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: box.listenable(),
              builder: (context, Box<ScoreEntry> box, _) {
                if (box.values.isEmpty) {
                  return const Center(child: Text('No scores found'));
                }

                List<ScoreEntry> entries = box.values.toList().cast<
                    ScoreEntry>();

                // Apply filters
                entries = entries.where((entry) {
                  final matchesPractice = (selectedPractice == 'All' ||
                      entry.practice == selectedPractice);
                  final matchesCaliber = (selectedCaliber == 'All' ||
                      entry.caliber == selectedCaliber);
                  final matchesFirearm = (selectedFirearmId == 'All' ||
                      entry.firearmId == selectedFirearmId);
                  return matchesPractice && matchesCaliber && matchesFirearm;
                }).toList();

                entries.sort((a, b) => b.date.compareTo(a.date));

                if (entries.isEmpty) {
                  return const Center(child: Text('No scores found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final formattedDate = formatUKDate(entry.date);

                    Widget leading;
                    if (entry.thumbnailFilePath != null &&
                        File(entry.thumbnailFilePath!).existsSync()) {
                      leading = ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(entry.thumbnailFilePath!),
                            width: 60, height: 60, fit: BoxFit.cover),
                      );
                    } else if (entry.targetFilePath != null &&
                        File(entry.targetFilePath!).existsSync()) {
                      leading = ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(entry.targetFilePath!),
                            width: 60, height: 60, fit: BoxFit.cover),
                      );
                    } else {
                      leading = Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.image_not_supported, size: 30,
                            color: primaryColor.withValues(alpha: 0.5)),
                      );
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Dismissible(
                        key: Key(entry.id),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          color: Colors.green,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.edit, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            return await showDialog(
                              context: context,
                              builder: (context) =>
                                  AlertDialog(
                                    title: const Text('Delete Entry?'),
                                    content: const Text(
                                        'Are you sure you want to delete this score entry?'),
                                    actions: [
                                      TextButton(onPressed: () =>
                                          Navigator.of(context).pop(false),
                                          child: const Text('Cancel')),
                                      TextButton(onPressed: () =>
                                          Navigator.of(context).pop(true),
                                          child: const Text('Delete',
                                              style: TextStyle(
                                                  color: Colors.red))),
                                    ],
                                  ),
                            );
                          } else if (direction == DismissDirection.endToStart) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) =>
                                  EnterScoreScreen(editEntry: entry)),
                            );
                            return false;
                          }
                          return false;
                        },
                        onDismissed: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            // Delete the calendar entry first
                            await CalendarScoreService().deleteScoreAppointment(
                                entry.id);
                            // Then delete the score
                            box.delete(entry.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Score entry deleted')));
                            }
                          }
                        },
                        child: ListTile(
                          leading: leading,
                          title: Text(
                            '${entry.practice} - ${entry.caliber}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                              'Score: ${entry.score} | Date: $formattedDate'),
                          onTap: () {
                            if (entry.targetFilePath != null &&
                                File(entry.targetFilePath!).existsSync()) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      Scaffold(
                                        appBar: AppBar(title: Text(
                                            formatUKDate(entry.date))),
                                        body: Column(
                                          crossAxisAlignment: CrossAxisAlignment
                                              .start,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                  16.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment
                                                    .start,
                                                children: [
                                                  _buildDetailRow('Score:',
                                                      entry.score.toString()),
                                                  _buildDetailRow('Practice:',
                                                      entry.practice),
                                                  _buildDetailRow('Calibre:',
                                                      entry.caliber),
                                                  _buildDetailRow('Firearm ID:',
                                                      entry.firearmId),
                                                  if (entry.firearm != null &&
                                                      entry.firearm!.isNotEmpty)
                                                    _buildDetailRow('Firearm:',
                                                        entry.firearm!),
                                                  if (entry.notes != null &&
                                                      entry.notes!
                                                          .isNotEmpty) ...[
                                                    const SizedBox(height: 8),
                                                    const Text('Notes:',
                                                        style: TextStyle(
                                                            fontWeight: FontWeight
                                                                .bold)),
                                                    Text(entry.notes!),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Expanded(
                                              child: Center(
                                                child: InteractiveViewer(
                                                  panEnabled: true,
                                                  minScale: 1.0,
                                                  maxScale: 5.0,
                                                  child: Image.file(File(
                                                      entry.targetFilePath!),
                                                      fit: BoxFit.contain),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text(
                                    'No image available for this entry')),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
                label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
