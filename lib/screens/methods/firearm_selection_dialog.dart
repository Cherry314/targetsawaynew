// lib/screens/methods/firearm_selection_dialog.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/dropdown_values.dart';

Future<void> showFirearmSelectionDialog({
  required BuildContext context,
  required Function() onSelectionChanged,
}) async {
  await showDialog(
    context: context,
    builder: (context) => _FirearmSelectionDialog(
      onSelectionChanged: onSelectionChanged,
    ),
  );
}

class _FirearmSelectionDialog extends StatefulWidget {
  final Function() onSelectionChanged;

  const _FirearmSelectionDialog({
    required this.onSelectionChanged,
  });

  @override
  State<_FirearmSelectionDialog> createState() => _FirearmSelectionDialogState();
}

class _FirearmSelectionDialogState extends State<_FirearmSelectionDialog> {
  Set<int> selectedFirearmIds = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSelectedFirearms();
  }

  Future<void> _loadSelectedFirearms() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('favoriteFirearmIds');

    setState(() {
      if (saved != null && saved.isNotEmpty) {
        // Convert saved string IDs to integers
        selectedFirearmIds = saved
            .map((id) => int.tryParse(id))
            .where((id) => id != null)
            .cast<int>()
            .toSet();
      } else {
        // Start with empty selection
        selectedFirearmIds = {};
      }
      isLoading = false;
    });
  }

  Future<void> _saveSelectedFirearms() async {
    final prefs = await SharedPreferences.getInstance();

    // Sort by ID
    final sortedIds = selectedFirearmIds.toList()..sort();

    // Save as string list
    await prefs.setStringList(
      'favoriteFirearmIds',
      sortedIds.map((id) => id.toString()).toList(),
    );

    // Update the DropdownValues
    DropdownValues.favoriteFirearmIds = sortedIds;

    widget.onSelectionChanged();
  }

  @override
  Widget build(BuildContext context) {
    // Group firearms by gun type
    final groupedFirearms = <String, List<FirearmInfo>>{};
    for (final firearm in DropdownValues.masterFirearmTable) {
      groupedFirearms.putIfAbsent(firearm.gunType, () => []).add(firearm);
    }

    return AlertDialog(
      title: const Text('Select Favorite Firearms'),
      content: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
 // Display firearms grouped by type
                  ...groupedFirearms.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Group header
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 4, left: 8),
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        // Firearms in this group
                        ...entry.value.map((firearm) {
                          final isSelected = selectedFirearmIds.contains(firearm.id);
                          return CheckboxListTile(
                            title: Text('${firearm.code} '),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedFirearmIds.add(firearm.id);
                                } else {
                                  selectedFirearmIds.remove(firearm.id);
                                }
                              });
                            },
                            dense: true,
                          );
                        }),
                      ],
                    );
                  }),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            await _saveSelectedFirearms();
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
