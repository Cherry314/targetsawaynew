// lib/screens/membership_cards_tab.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/membership_card_entry.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import 'membership_card_full_screen.dart'; // <-- import the full-screen widget

class MembershipCardsTab extends StatefulWidget {
  final Color primaryColor;
  const MembershipCardsTab({super.key, required this.primaryColor});

  @override
  State<MembershipCardsTab> createState() => _MembershipCardsTabState();
}

class _MembershipCardsTabState extends State<MembershipCardsTab> {
  late Box<MembershipCardEntry> _cardBox;

  @override
  void initState() {
    super.initState();
    _cardBox = Hive.box<MembershipCardEntry>('membership_cards');
  }

  Future<void> _addOrEditCard({MembershipCardEntry? entry}) async {
    File? frontImage = entry?.frontImagePath != null ? File(entry!.frontImagePath!) : null;
    File? backImage = entry?.backImagePath != null ? File(entry!.backImagePath!) : null;
    final TextEditingController nameController = TextEditingController(text: entry?.memberName ?? '');

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final primaryColor = themeProvider.primaryColor;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: bgColor,
        title: Text(entry == null ? 'Add Membership Card' : 'Edit Membership Card',
            style: TextStyle(color: primaryColor)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: primaryColor),
                decoration: InputDecoration(
                  labelText: 'Member Name',
                  labelStyle: TextStyle(color: primaryColor),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: bgColor.withAlpha((0.05 * 255).round()),
                ),
              ),
              const SizedBox(height: 8),
              if (frontImage != null)
                Image.file(frontImage!, width: 100, height: 100),
              ElevatedButton.icon(
                onPressed: () async {
                  final imageQualityProvider = Provider.of<
                      ImageQualityProvider>(context, listen: false);
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: imageQualityProvider.qualityPercentage
                  );
                  if (picked != null) setState(() =>
                  frontImage = File(picked.path));
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Capture Front'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: primaryColor,
                  backgroundColor: primaryColor.withAlpha((0.1 * 255).round()),
                ),
              ),
              const SizedBox(height: 8),
              if (backImage != null)
                Image.file(backImage!, width: 100, height: 100),
              ElevatedButton.icon(
                onPressed: () async {
                  final imageQualityProvider = Provider.of<
                      ImageQualityProvider>(context, listen: false);
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: imageQualityProvider.qualityPercentage
                  );
                  if (picked != null) setState(() => backImage = File(picked.path));
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Capture Back'),
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
              if (frontImage == null || backImage == null || nameController.text.trim().isEmpty) return;

              final newEntry = MembershipCardEntry(
                id: entry?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                memberName: nameController.text.trim(),
                frontImagePath: frontImage?.path,
                backImagePath: backImage?.path,
              );

              _cardBox.put(newEntry.id, newEntry);
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.primaryColor;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    final cards = _cardBox.values.toList();

    return Container(
      color: bgColor,
      child: Column(
        children: [
          Expanded(
            child: cards.isEmpty
                ? Center(
              child: ElevatedButton(
                onPressed: () => _addOrEditCard(),
                style: ElevatedButton.styleFrom(
                  foregroundColor: primaryColor,
                  backgroundColor: primaryColor.withAlpha((0.1 * 255).round()),
                ),
                child: const Text('Add First Card'),
              ),
            )
                : ListView.builder(
              itemCount: cards.length,
              itemBuilder: (_, index) {
                final entry = cards[index];
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
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete Card?'),
                          content: const Text('Are you sure you want to delete this card?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );
                      if (confirm == true) _cardBox.delete(entry.id);
                      return confirm;
                    } else if (direction == DismissDirection.endToStart) {
                      await _addOrEditCard(entry: entry);
                      return false;
                    }
                    return false;
                  },
                  child: ListTile(
                    leading: entry.frontImagePath != null
                        ? Image.file(File(entry.frontImagePath!), width: 50, height: 50, fit: BoxFit.cover)
                        : null,
                    title: Text(entry.memberName, style: TextStyle(color: primaryColor)),
                    onTap: () {
                      // Open full-screen view
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MembershipCardFullScreen(entry: entry),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          if (cards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () => _addOrEditCard(),
                style: ElevatedButton.styleFrom(
                  foregroundColor: primaryColor,
                  backgroundColor: primaryColor.withAlpha((0.1 * 255).round()),
                ),
                child: const Text('Add Another Card'),
              ),
            ),
        ],
      ),
    );
  }
}
