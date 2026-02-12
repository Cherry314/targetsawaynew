// lib/screens/comps/run_competition/enter_score_dialog.dart
// Dialog for entering scores for manual entry shooters

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';

class EnterScoreDialog extends StatefulWidget {
  final String competitionId;
  final String shooterName;
  final int? currentScore;
  final int? currentXCount;

  const EnterScoreDialog({
    super.key,
    required this.competitionId,
    required this.shooterName,
    this.currentScore,
    this.currentXCount,
  });

  @override
  State<EnterScoreDialog> createState() => _EnterScoreDialogState();
}

class _EnterScoreDialogState extends State<EnterScoreDialog> {
  final _formKey = GlobalKey<FormState>();
  final _scoreController = TextEditingController();
  final _xCountController = TextEditingController();
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentScore != null) {
      _scoreController.text = widget.currentScore.toString();
    }
    if (widget.currentXCount != null) {
      _xCountController.text = widget.currentXCount.toString();
    }
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _xCountController.dispose();
    super.dispose();
  }

  Future<void> _submitScore() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final score = int.parse(_scoreController.text.trim());
      final xCount = int.tryParse(_xCountController.text.trim()) ?? 0;

      // Get current manual entries
      final doc = await FirebaseFirestore.instance
          .collection('competitions')
          .doc(widget.competitionId)
          .get();

      final data = doc.data() as Map<String, dynamic>?;
      final manualEntries = (data?['manualEntries'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];

      // Find and update this entry
      final updatedEntries = manualEntries.map((entry) {
        if (entry['name'] == widget.shooterName) {
          return {
            ...entry,
            'score': score,
            'xCount': xCount,
            'submitted': true,
            'submittedAt': DateTime.now(),
          };
        }
        return entry;
      }).toList();

      await FirebaseFirestore.instance
          .collection('competitions')
          .doc(widget.competitionId)
          .update({
        'manualEntries': updatedEntries,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Score saved successfully'),
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
            content: Text('Error saving score: $e'),
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
          Icon(Icons.edit, color: primaryColor),
          const SizedBox(width: 8),
          const Text('Enter Score'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Shooter name display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.shooterName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
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
          onPressed: isSubmitting ? null : _submitScore,
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
          label: Text(isSubmitting ? 'Saving...' : 'Save Score'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
