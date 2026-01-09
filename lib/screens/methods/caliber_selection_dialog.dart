// lib/screens/methods/caliber_selection_dialog.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/dropdown_values.dart';

Future<void> showCaliberSelectionDialog({
  required BuildContext context,
  required Function() onSelectionChanged,
}) async {
  await showDialog(
    context: context,
    builder: (context) => _CaliberSelectionDialog(
      onSelectionChanged: onSelectionChanged,
    ),
  );
}

class _CaliberSelectionDialog extends StatefulWidget {
  final Function() onSelectionChanged;

  const _CaliberSelectionDialog({
    required this.onSelectionChanged,
  });

  @override
  State<_CaliberSelectionDialog> createState() => _CaliberSelectionDialogState();
}

class _CaliberSelectionDialogState extends State<_CaliberSelectionDialog> {
  List<String> calibers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCalibers();
  }

  Future<void> _loadCalibers() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('favoriteCalibers');

    setState(() {
      if (saved != null && saved.isNotEmpty) {
        calibers = saved;
      } else {
        // Start with empty list
        calibers = [];
      }
      isLoading = false;
    });
  }

  Future<void> _addCaliber() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Caliber'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Caliber (e.g., .22, 9mm, .357)',
            border: OutlineInputBorder(),
            hintText: 'Enter caliber',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        // Add to calibers if not already in list
        if (!calibers.contains(result)) {
          calibers.add(result);
        }
      });
    }
  }

  Future<void> _removeCaliber(String caliber) async {
    setState(() {
      calibers.remove(caliber);
    });
  }

  Future<void> _saveCalibers() async {
    final prefs = await SharedPreferences.getInstance();

    // Sort calibers alphabetically
    final sortedCalibers = calibers.toList()..sort();

    await prefs.setStringList('favoriteCalibers', sortedCalibers);

    // Update the DropdownValues
    DropdownValues.calibers = sortedCalibers;

    widget.onSelectionChanged();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manage Favorite Calibers'),
      content: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show helpful note if no calibers yet
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: calibers.length,
                        itemBuilder: (context, index) {
                          final caliber = calibers[index];
                          return ListTile(
                            title: Text(caliber),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeCaliber(caliber),
                            ),
                            dense: true,
                          );
                        },
                      ),
                    ),
                  ],
              ),
            ),
      actions: [
        Row(
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),

        TextButton(
          onPressed: _addCaliber,
          child: const Text('Add Caliber'),
        ),
        ElevatedButton(
          onPressed: () async {
            await _saveCalibers();
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    ),
      ],
    );
  }
}
