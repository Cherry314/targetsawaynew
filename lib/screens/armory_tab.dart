// lib/screens/armory_tab.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/firearm_entry.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import 'armory_tab_full_screen.dart';


class ArmoryTab extends StatefulWidget {
  final Color primaryColor;
  const ArmoryTab({super.key, required this.primaryColor});

  @override
  State<ArmoryTab> createState() => _ArmoryTabState();
}

class _ArmoryTabState extends State<ArmoryTab> {
  late Box<FirearmEntry> _firearmBox;

  @override
  void initState() {
    super.initState();
    _firearmBox = Hive.box<FirearmEntry>('firearms');
  }

  Future<void> _addOrEditFirearm({FirearmEntry? entry}) async {
    File? imageFile = entry?.imagePath != null ? File(entry!.imagePath!) : null;

    final TextEditingController nicknameController =
    TextEditingController(text: entry?.nickname ?? '');
    final TextEditingController makeController =
    TextEditingController(text: entry?.make ?? '');
    final TextEditingController modelController =
    TextEditingController(text: entry?.model ?? '');
    final TextEditingController caliberController =
    TextEditingController(text: entry?.caliber ?? '');
    final TextEditingController scopeController =
    TextEditingController(text: entry?.scopeSize ?? '');
    final TextEditingController notesController =
    TextEditingController(text: entry?.notes ?? '');
    bool owned = entry?.owned ?? false;

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final primaryColor = themeProvider.primaryColor;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgColor,
        title: Text(
          entry == null ? 'Add Firearm' : 'Edit Firearm',
          style: TextStyle(color: primaryColor),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField(nicknameController, 'Nickname'),
              const SizedBox(height: 8),
              _buildTextField(makeController, 'Make'),
              const SizedBox(height: 8),
              _buildTextField(modelController, 'Model'),
              const SizedBox(height: 8),
              _buildTextField(caliberController, 'Caliber'),
              const SizedBox(height: 8),
              _buildTextField(scopeController, 'Scope Size (optional)'),
              const SizedBox(height: 8),
              _buildTextField(notesController, 'Notes'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Owned:', style: TextStyle(color: primaryColor)),
                  Checkbox(
                    value: owned,
                    onChanged: (val) => setState(() => owned = val!),
                    fillColor: WidgetStateProperty.all(primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (imageFile != null)
                Image.file(imageFile!, width: 100, height: 100),
              ElevatedButton.icon(
                onPressed: () async {
                  final imageQualityProvider = Provider.of<
                      ImageQualityProvider>(context, listen: false);
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: imageQualityProvider.qualityPercentage);
                  if (picked != null) setState(() => imageFile = File(picked.path));
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Capture Image'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: primaryColor,
                  backgroundColor: primaryColor.withAlpha((0.1 * 255).round()),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: primaryColor),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nicknameController.text.trim().isEmpty) return;

              final newEntry = FirearmEntry(
                id: entry?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                nickname: nicknameController.text.trim(),
                make: makeController.text.trim(),
                model: modelController.text.trim(),
                caliber: caliberController.text.trim(),
                owned: owned,
                scopeSize: scopeController.text.trim().isEmpty
                    ? null
                    : scopeController.text.trim(),
                notes: notesController.text.trim().isEmpty
                    ? null
                    : notesController.text.trim(),
                imagePath: imageFile?.path,
              );

              _firearmBox.put(newEntry.id, newEntry);
              Navigator.pop(context);
              setState(() {});
            },
            style: TextButton.styleFrom(foregroundColor: primaryColor),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final primaryColor = themeProvider.primaryColor;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return TextField(
      controller: controller,
      style: TextStyle(color: primaryColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: primaryColor),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: bgColor.withAlpha((0.05 * 255).round()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.primaryColor;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    final firearms = _firearmBox.values.toList();

    return Container(
      color: bgColor,
      child: Column(
        children: [
          Expanded(
            child: firearms.isEmpty
                ? Center(
              child: ElevatedButton(
                onPressed: () => _addOrEditFirearm(),
                style: ElevatedButton.styleFrom(
                  foregroundColor: primaryColor,
                  backgroundColor:
                  primaryColor.withAlpha((0.1 * 255).round()),
                ),
                child: const Text('Add First Firearm'),
              ),
            )
                : ListView.builder(
              itemCount: firearms.length,
              itemBuilder: (_, index) {
                final firearm = firearms[index];
                return Dismissible(
                  key: Key(firearm.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    color: Colors.blue,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.edit, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Firearm?'),
                          content: const Text(
                              'Are you sure you want to delete this firearm?'),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Delete',
                                    style:
                                    TextStyle(color: Colors.red))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        _firearmBox.delete(firearm.id);
                      }
                      return confirm;
                    } else if (direction == DismissDirection.endToStart) {
                      await _addOrEditFirearm(entry: firearm);
                      return false;
                    }
                    return false;
                  },
                  child: ListTile(
                    leading: firearm.imagePath != null
                        ? Image.file(File(firearm.imagePath!),
                        width: 50, height: 50, fit: BoxFit.cover)
                        : null,
                    title: Text(firearm.nickname ?? 'Unnamed',
                        style: TextStyle(color: primaryColor)),
                    subtitle: Text('${firearm.make} ${firearm.model}',
                        style:
                        TextStyle(color: primaryColor.withValues(alpha: 0.7))),
                    onTap: () {
                      // Navigate to full-screen page with fade animation
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, _, _) =>
                              ArmoryFullScreen(entry: firearm),
                          transitionsBuilder: (_, animation, _, child) {
                            return FadeTransition(
                                opacity: animation, child: child);
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Add Another Firearm button
          if (firearms.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () => _addOrEditFirearm(),
                style: ElevatedButton.styleFrom(
                  foregroundColor: primaryColor,
                  backgroundColor: primaryColor.withAlpha((0.1 * 255).round()),
                ),
                child: const Text('Add Another Firearm'),
              ),
            ),
        ],
      ),
    );
  }
}
