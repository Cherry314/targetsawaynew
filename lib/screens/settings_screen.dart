import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../utils/backup_restore.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final themeOptions = [
      'Default',
      'Purple',
      'Green',
      'Orange',
      'Red',
      'Teal',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: Padding(
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
                  if (val == null) return;
                  themeProvider.setTheme(val);
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  final file = await BackupRestore.backupAppData();
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
            const SizedBox(height: 10),
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
