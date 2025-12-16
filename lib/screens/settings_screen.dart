// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../main.dart';
import '../utils/backup_restore.dart';
import '../utils/storage_usage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String resultsText = "";
  final TextEditingController folderController = TextEditingController();
  bool includeImages = true;

  @override
  void dispose() {
    folderController.dispose();
    super.dispose();
  }

  Future<void> _calculateSizes() async {
    final sizes = await StorageUsage.calculateAllSizesMb();
    setState(() {
      resultsText = sizes.entries
          .map((e) => "${e.key}: ${e.value.toStringAsFixed(4)} MB")
          .join("\n");
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeOptions = ['Default', 'Purple', 'Green', 'Orange', 'Red', 'Teal'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: const Text('Color Scheme'),
              trailing: DropdownButton<int>(
                value: themeProvider.themeIndex,
                items: List.generate(
                  themeOptions.length,
                      (i) => DropdownMenuItem(
                    value: i,
                    child: Text(themeOptions[i]),
                  ),
                ),
                onChanged: (val) {
                  if (val != null) themeProvider.setTheme(val);
                },
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _calculateSizes,
              child: const Text('Calculate Storage Usage'),
            ),
            const SizedBox(height: 10),

            Text(resultsText, style: const TextStyle(fontSize: 14)),
            const Divider(height: 40),

            // ---------------- Backup ----------------
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.backup),
                    label: const Text('Create Backup'),
                    onPressed: () async {
                      try {
                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) =>
                          const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );

                        final file = await BackupRestore.backupAppData(
                            includeImages: includeImages);

                        // Close loading indicator
                        if (context.mounted) Navigator.pop(context);

                        // Share the file using native share dialog
                        final result = await Share.shareXFiles(
                          [XFile(file.path)],
                          subject: 'TargetsAway Backup',
                          text: 'My TargetsAway backup file - ${file.uri
                              .pathSegments.last}',
                        );

                        // Show result
                        if (context.mounted) {
                          if (result.status == ShareResultStatus.success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Backup shared successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else
                          if (result.status == ShareResultStatus.dismissed) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Share cancelled'),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        // Close loading if still open
                        if (context.mounted) Navigator.pop(context);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Backup failed: $e')),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    Checkbox(
                      value: includeImages,
                      onChanged: (v) {
                        if (v != null) setState(() => includeImages = v);
                      },
                    ),
                    const Text('Include Images'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ---------------- Restore ----------------
            ElevatedButton.icon(
              icon: const Icon(Icons.restore),
              label: const Text('Restore from Backup'),
              onPressed: () async {
                // Show confirmation dialog first
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) =>
                      AlertDialog(
                        title: const Text('Restore Backup?'),
                        content: const Text(
                            'This will replace all current data with the backup data. '
                                'Are you sure you want to continue?'
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Restore'),
                          ),
                        ],
                      ),
                );

                if (confirmed != true) return;

                try {
                  // Show loading
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) =>
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['zip'],
                    dialogTitle: 'Select TargetsAway Backup File',
                  );

                  if (result != null && result.files.single.path != null) {
                    final file = File(result.files.single.path!);

                    await BackupRestore.restoreAppData(file);

                    // Close loading
                    if (context.mounted) Navigator.pop(context);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Restore complete! Restart the app to see changes.'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 5),
                        ),
                      );
                    }
                  } else {
                    // Close loading if cancelled
                    if (context.mounted) Navigator.pop(context);
                  }
                } catch (e) {
                  // Close loading
                  if (context.mounted) Navigator.pop(context);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Restore failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
