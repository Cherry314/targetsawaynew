// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
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
  bool includeImages = true; // Default for backup checkbox

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
            // ---------------- Color Scheme ----------------
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

            // ---------------- Optional Folder Filter ----------------
            TextField(
              controller: folderController,
              decoration: const InputDecoration(
                labelText: "Optional folder filter (not required)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            // ---------------- Calculate Storage Usage ----------------
            ElevatedButton(
              onPressed: _calculateSizes,
              child: const Text('Calculate Storage Usage'),
            ),
            const SizedBox(height: 10),
            Text(
              resultsText,
              style: const TextStyle(fontSize: 14),
            ),
            const Divider(height: 40),

            // ---------------- Backup Section ----------------
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final file = await BackupRestore.backupAppData(includeImages: includeImages);
                        await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Backup Created'),
                            content: Text('Backup saved to:\n${file.path}'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Backup failed: $e')),
                        );
                      }
                    },
                    child: const Text('Backup'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Checkbox(
                        value: includeImages,
                        onChanged: (val) {
                          if (val != null) setState(() => includeImages = val);
                        },
                      ),
                      const Flexible(child: Text('Include Images')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ---------------- Restore Section ----------------
            ElevatedButton(
              onPressed: () async {
                try {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['zip'],
                  );
                  if (result != null && result.files.single.path != null) {
                    final file = File(result.files.single.path!);
                    await BackupRestore.restoreAppData(file);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Restore complete!')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Restore failed: $e')),
                  );
                }
              },
              child: const Text('Restore Backup'),
            ),
          ],
        ),
      ),
    );
  }
}

// Small helper because package_info_plus wasn't imported
class PackageInfoShim {
  final String packageName;
  PackageInfoShim({required this.packageName});
}
