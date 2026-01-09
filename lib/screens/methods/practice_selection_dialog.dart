// lib/screens/methods/practice_selection_dialog.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/dropdown_values.dart';

Future<void> showPracticeSelectionDialog({
  required BuildContext context,
  required Function() onSelectionChanged,
}) async {
  await showDialog(
    context: context,
    builder: (context) =>
        _PracticeSelectionDialog(
          onSelectionChanged: onSelectionChanged,
        ),
  );
}

class _PracticeSelectionDialog extends StatefulWidget {
  final Function() onSelectionChanged;

  const _PracticeSelectionDialog({
    required this.onSelectionChanged,
  });

  @override
  State<_PracticeSelectionDialog> createState() =>
      _PracticeSelectionDialogState();
}

class _PracticeSelectionDialogState extends State<_PracticeSelectionDialog> {
  Set<String> selectedPractices = {};
  List<String> customPractices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSelectedPractices();
  }

  Future<void> _loadSelectedPractices() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('favoritePractices');
    final savedCustom = prefs.getStringList('customPractices') ?? [];

    setState(() {
      customPractices = savedCustom;

      if (saved != null && saved.isNotEmpty) {
        // Always filter out 'All' when loading
        selectedPractices = saved.where((p) => p != 'All').toSet();
      } else {
        // Start with empty selection - user must choose favorites
        selectedPractices = {};
      }
      isLoading = false;
    });
  }

  Future<void> _addCustomPractice() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Add Custom Practice'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Practice Name',
                border: OutlineInputBorder(),
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
                  if (controller.text
                      .trim()
                      .isNotEmpty) {
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
        // Add to custom practices if not already in master or custom lists
        if (!DropdownValues.masterPractices.contains(result) &&
            !customPractices.contains(result)) {
          customPractices.add(result);
          selectedPractices.add(result);
        }
      });
    }
  }

  Future<void> _saveSelectedPractices() async {
    final prefs = await SharedPreferences.getInstance();

    // Sort practices alphabetically (setter will filter out 'All' automatically)
    final sortedPractices = selectedPractices.toList()
      ..sort();

    await prefs.setStringList('favoritePractices', sortedPractices);
    await prefs.setStringList('customPractices', customPractices);

    // Update the DropdownValues.practices list (setter automatically adds 'All' at top)
    DropdownValues.practices = sortedPractices;

    widget.onSelectionChanged();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Favorite Practices'),
      content: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            // Show helpful note if no favorites selected yet
            if (selectedPractices.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please select your favorite events from the full events list below',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Custom practices section
            if (customPractices.isNotEmpty) ...[
              ...customPractices.map((practice) {
                final isSelected = selectedPractices.contains(practice);
                return CheckboxListTile(
                  title: Row(
                    children: [
                      Expanded(child: Text(practice)),
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        selectedPractices.add(practice);
                      } else {
                        selectedPractices.remove(practice);
                      }
                    });
                  },
                  dense: true,
                );
              }),
              const Divider(thickness: 2),
            ],

            // Master practices section
            ...DropdownValues.masterPractices.map((practice) {
              final isSelected = selectedPractices.contains(practice);
              return CheckboxListTile(
                title: Text(practice),
                value: isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      selectedPractices.add(practice);
                    } else {
                      selectedPractices.remove(practice);
                    }
                  });
                },
                dense: true,
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
        TextButton(
          onPressed: _addCustomPractice,
          child: const Text('Custom'),
        ),
        ElevatedButton(
          onPressed: () async {
            await _saveSelectedPractices();
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
