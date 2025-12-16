// lib/dialogs/firearm_dialog.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/firearm_entry.dart';
import '../../main.dart';

Future<void> showFirearmDialog({
  required BuildContext context,
  required TextEditingController firearmController,
  required Function(String firearmId) onSelectId,
  required Function(String key, String value) saveSelection,
}) async {
  final firearmBox = Hive.box<FirearmEntry>('firearms');
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text("Enter Firearm",
          style: TextStyle(color: themeProvider.primaryColor)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: firearmController,
            decoration: InputDecoration(
              labelText: "Firearm",
              labelStyle: TextStyle(color: themeProvider.primaryColor),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: Icon(Icons.list, color: themeProvider.primaryColor),
            label: Text("Select from Armory",
                style: TextStyle(color: themeProvider.primaryColor)),
            onPressed: () async {
              final selectedGun = await showDialog<FirearmEntry>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text("My Armory",
                      style: TextStyle(color: themeProvider.primaryColor)),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: firearmBox.isEmpty
                        ? const Text("No firearms found")
                        : SizedBox(
                      height: 300,
                      child: ListView.builder(
                        itemCount: firearmBox.length,
                        itemBuilder: (_, i) {
                          final gun = firearmBox.getAt(i)!;
                          return ListTile(
                            title: Text(gun.nickname ?? "Unnamed"),
                            onTap: () => Navigator.pop(context, gun),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );

              if (selectedGun != null) {
                firearmController.text = selectedGun.nickname ?? '';
                // Note: We don't call onSelectId or saveSelection here
                // because the Firearm ID dropdown is separate from the armory database ID
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: themeProvider.primaryColor))),
      ],
    ),
  );
}
