// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../main.dart';
import '../utils/backup_restore.dart';
import '../utils/storage_usage.dart';
import '../widgets/app_drawer.dart';
import '../widgets/help_icon_button.dart';
import '../utils/help_content.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String resultsText = "";
  final TextEditingController folderController = TextEditingController();
  bool includeImages = true;
  bool showStorageResults = false;

  @override
  void dispose() {
    folderController.dispose();
    super.dispose();
  }

  Future<void> _toggleStorageUsage() async {
    if (showStorageResults) {
      // If already showing, just hide it
      setState(() {
        showStorageResults = false;
      });
    } else {
      // If not showing, calculate and show it
      final sizes = await StorageUsage.calculateAllSizesMb();
      setState(() {
        resultsText = sizes.entries
            .map((e) => "${e.key}: ${e.value.toStringAsFixed(4)} MB")
            .join("\n");
        showStorageResults = true;
      });
    }
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
    required BuildContext context,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme
                    .of(context)
                    .primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final imageQualityProvider = Provider.of<ImageQualityProvider>(context);
    final themeOptions = [
      'Default',
      'Purple',
      'Green',
      'Orange',
      'Red',
      'Teal'
    ];
    final qualityOptions = ['Low (50%)', 'Medium (70%)', 'Large (85%)'];

    return Scaffold(
      drawer: const AppDrawer(currentRoute: 'settings'),
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
        actions: const [
          HelpIconButton(
            title: 'Settings Help',
            content: HelpContent.settingsScreen,
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Appearance Section
            _buildSectionCard(
              title: 'Appearance',
              context: context,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Color Scheme'),
                  trailing: DropdownButton<int>(
                    value: themeProvider.themeIndex,
                    alignment: AlignmentDirectional.centerEnd,
                    items: List.generate(
                      themeOptions.length,
                          (i) =>
                          DropdownMenuItem(
                            value: i,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(themeOptions[i]),
                            ),
                          ),
                    ),
                    onChanged: (val) {
                      if (val != null) themeProvider.setTheme(val);
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Theme Mode'),
                  trailing: DropdownButton<ThemeMode>(
                    value: themeProvider.themeMode,
                    alignment: AlignmentDirectional.centerEnd,
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text('Use Device Settings'),
                        ),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text('Light Mode'),
                        ),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text('Dark Mode'),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) themeProvider.setThemeMode(val);
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Home Screen Animations'),
                  trailing: Switch(
                    value: Provider
                        .of<AnimationsProvider>(context)
                        .animationsEnabled,
                    onChanged: (val) {
                      Provider.of<AnimationsProvider>(context, listen: false)
                          .setAnimationsEnabled(val);
                    },
                  ),
                ),
              ],
            ),

            // Media Section
            _buildSectionCard(
              title: 'Media',
              context: context,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Image Quality'),
                  subtitle: const Text('Quality for saved images'),
                  trailing: DropdownButton<int>(
                    value: imageQualityProvider.qualityIndex,
                    alignment: AlignmentDirectional.centerEnd,
                    items: List.generate(
                      qualityOptions.length,
                          (i) =>
                          DropdownMenuItem(
                            value: i,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(qualityOptions[i]),
                            ),
                          ),
                    ),
                    onChanged: (val) {
                      if (val != null) imageQualityProvider.setQuality(val);
                    },
                  ),
                ),
              ],
            ),

            // Storage Section
            _buildSectionCard(
              title: 'Storage',
              context: context,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(
                      showStorageResults ? Icons.close : Icons.storage,
                    ),
                    label: Text(
                      showStorageResults
                          ? 'Close Usage'
                          : 'Calculate Storage Usage',
                    ),
                    onPressed: _toggleStorageUsage,
                  ),
                ),
                if (showStorageResults) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme
                          .of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme
                            .of(context)
                            .dividerColor,
                      ),
                    ),
                    child: Text(
                      resultsText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ],
            ),

            // Backup & Restore Section
            _buildSectionCard(
              title: 'Backup & Restore',
              context: context,
              children: [
                SizedBox(
                  width: double.infinity,
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: includeImages,
                      onChanged: (v) {
                        if (v != null) setState(() => includeImages = v);
                      },
                    ),
                    const Text('Include Images in Backup'),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.restore),
                    label: const Text('Restore from Backup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      // Show confirmation dialog first
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) =>
                            AlertDialog(
                              title: const Text('Restore Backup?'),
                              content: const Text(
                                  'This will replace all current data with the backup data. '
                                      'Are you sure you want to continue?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
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

                        if (result != null &&
                            result.files.single.path != null) {
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
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}
