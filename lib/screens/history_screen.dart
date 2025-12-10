import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/score_entry.dart';
import '../utils/date_utils.dart';
import '../data/dropdown_values.dart';
import 'enter_score_screen.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  HistoryScreenState createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  String selectedPractice = 'All';
  String selectedCaliber = 'All';
  String selectedFirearmId = 'All';

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<ScoreEntry>('scores');

    final themeProvider = Provider.of<ThemeProvider>(context);
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final filterBg = themeProvider.primaryColor.withAlpha((0.02 * 255).round());
    final primaryColor = themeProvider.primaryColor;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Previous Targets'),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Dropdown filters container
          Container(
            color: filterBg,
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedPractice,
                  decoration: const InputDecoration(
                    labelText: 'Practice',
                    border: OutlineInputBorder(),
                  ),
                  items: DropdownValues.practices
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedPractice = v!),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedCaliber,
                  decoration: const InputDecoration(
                    labelText: 'Calibre',
                    border: OutlineInputBorder(),
                  ),
                  items: DropdownValues.calibers
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedCaliber = v!),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedFirearmId,
                  decoration: const InputDecoration(
                    labelText: 'Firearm ID',
                    border: OutlineInputBorder(),
                  ),
                  items: DropdownValues.firearmIds
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedFirearmId = v!),
                ),
              ],
            ),
          ),

          // List of entries
          Expanded(
            child: Container(
              color: bgColor,
              child: ValueListenableBuilder(
                valueListenable: box.listenable(),
                builder: (context, Box<ScoreEntry> box, _) {
                  if (box.values.isEmpty) return const Center(child: Text('No scores found'));

                  List<ScoreEntry> entries = box.values.toList().cast<ScoreEntry>();

                  // Apply filters
                  entries = entries.where((entry) {
                    final matchesPractice = (selectedPractice == 'All' || entry.practice == selectedPractice);
                    final matchesCaliber = (selectedCaliber == 'All' || entry.caliber == selectedCaliber);
                    final matchesFirearm = (selectedFirearmId == 'All' || entry.firearmId == selectedFirearmId);
                    return matchesPractice && matchesCaliber && matchesFirearm;
                  }).toList();

                  entries.sort((a, b) => b.date.compareTo(a.date));

                  if (entries.isEmpty) return const Center(child: Text('No scores found'));

                  return ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final formattedDate = formatUKDate(entry.date);

                      Widget leading;
                      if (entry.thumbnailFilePath != null && File(entry.thumbnailFilePath!).existsSync()) {
                        leading = Image.file(File(entry.thumbnailFilePath!), width: 60, height: 60, fit: BoxFit.cover);
                      } else if (entry.targetFilePath != null && File(entry.targetFilePath!).existsSync()) {
                        leading = Image.file(File(entry.targetFilePath!), width: 60, height: 60, fit: BoxFit.cover);
                      } else {
                        leading = const Icon(Icons.image_not_supported, size: 48);
                      }

                      return Dismissible(
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
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Entry?'),
                                content: const Text('Are you sure you want to delete this score entry?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                          } else if (direction == DismissDirection.endToStart) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => EnterScoreScreen(editEntry: entry)),
                            );
                            return false;
                          }
                          return false;
                        },
                        onDismissed: (direction) {
                          if (direction == DismissDirection.startToEnd) {
                            box.delete(entry.id);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Score entry deleted')));
                          }
                        },
                        child: ListTile(
                          leading: leading,
                          title: Text('${entry.practice} - ${entry.caliber}'),
                          subtitle: Text('Score: ${entry.score} | Date: $formattedDate'),
                          onTap: () {
                            if (entry.targetFilePath != null && File(entry.targetFilePath!).existsSync()) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => Scaffold(
                                    appBar: AppBar(title: Text(formatUKDate(entry.date))),
                                    body: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildDetailRow('Score:', entry.score.toString()),
                                              _buildDetailRow('Practice:', entry.practice),
                                              _buildDetailRow('Calibre:', entry.caliber),
                                              _buildDetailRow('Firearm ID:', entry.firearmId ?? '-'),
                                              if (entry.firearm != null && entry.firearm!.isNotEmpty)
                                                _buildDetailRow('Firearm:', entry.firearm!),
                                              if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                                                const SizedBox(height: 8),
                                                const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                              child: Image.file(File(entry.targetFilePath!), fit: BoxFit.contain),
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
                                const SnackBar(content: Text('No image available for this entry')),
                              );
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
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
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
