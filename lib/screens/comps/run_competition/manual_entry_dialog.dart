// lib/screens/comps/run_competition/manual_entry_dialog.dart
// Dialog for manually entering shooter scores for non-app users

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';

class ManualEntryDialog extends StatefulWidget {
  final String competitionId;

  const ManualEntryDialog({
    super.key,
    required this.competitionId,
  });

  @override
  State<ManualEntryDialog> createState() => _ManualEntryDialogState();
}

class _ManualEntryDialogState extends State<ManualEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _scoreController = TextEditingController();
  final _xCountController = TextEditingController();
  bool isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _scoreController.dispose();
    _xCountController.dispose();
    super.dispose();
  }

  Future<void> _submitEntry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final entry = {
        'name': _nameController.text.trim(),
        'score': int.parse(_scoreController.text.trim()),
        'xCount': int.tryParse(_xCountController.text.trim()) ?? 0,
        'submittedAt': DateTime.now(),
      };

      // Add to manualEntries array in the competition document
      await FirebaseFirestore.instance
          .collection('competitions')
          .doc(widget.competitionId)
          .update({
        'manualEntries': FieldValue.arrayUnion([entry]),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Manual entry added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = themeProvider.primaryColor;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.person_add, color: primaryColor),
          const SizedBox(width: 8),
          const Text('Manual Entry'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Info text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Use this form to enter scores for shooters who are not using the app.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Shooter Name',
                  prefixIcon: Icon(Icons.person, color: primaryColor),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Score field
              TextFormField(
                controller: _scoreController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Score',
                  prefixIcon: Icon(Icons.military_tech, color: primaryColor),
                  border: const OutlineInputBorder(),
                  hintText: 'Enter total score',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a score';
                  }
                  final score = int.tryParse(value);
                  if (score == null || score < 0) {
                    return 'Please enter a valid score';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // X count field
              TextFormField(
                controller: _xCountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'X Count (Optional)',
                  prefixIcon: Icon(Icons.gps_fixed, color: primaryColor),
                  border: const OutlineInputBorder(),
                  hintText: 'Number of X shots',
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final xCount = int.tryParse(value);
                    if (xCount == null || xCount < 0) {
                      return 'Please enter a valid number';
                    }
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: isSubmitting ? null : _submitEntry,
          icon: isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save),
          label: Text(isSubmitting ? 'Saving...' : 'Add Entry'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
