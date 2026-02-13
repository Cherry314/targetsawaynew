// lib/screens/comps/run_competition/enter_score_dialog.dart
// Dialog for entering scores for manual entry shooters - with Score Calculator or Basic Score options

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';
import '../../../models/hive/event.dart';
import '../../methods/score_calculator_dialog.dart';

class EnterScoreDialog extends StatefulWidget {
  final String competitionId;
  final String shooterName;
  final int? currentScore;
  final int? currentXCount;
  final String eventName;

  const EnterScoreDialog({
    super.key,
    required this.competitionId,
    required this.shooterName,
    this.currentScore,
    this.currentXCount,
    required this.eventName,
  });

  @override
  State<EnterScoreDialog> createState() => _EnterScoreDialogState();
}

class _EnterScoreDialogState extends State<EnterScoreDialog> {
  final _formKey = GlobalKey<FormState>();
  final _scoreController = TextEditingController();
  final _xCountController = TextEditingController();
  bool isSubmitting = false;
  Map<int, int>? _scoreBreakdown;

  // Mode: 'select', 'calculator', or 'basic'
  String _mode = 'select';

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

  /// Get total rounds for the event from courseOfFire
  int? _getTotalRoundsForEvent() {
    if (widget.eventName.isEmpty) {
      return null;
    }

    try {
      if (!Hive.isBoxOpen('events')) {
        return null;
      }

      final eventBox = Hive.box<Event>('events');

      Event? matchedEvent;
      for (final event in eventBox.values) {
        if (event.name == widget.eventName) {
          matchedEvent = event;
          break;
        }
      }

      if (matchedEvent == null) {
        return null;
      }

      return matchedEvent.baseContent.courseOfFire.totalRounds;
    } catch (e) {
      return null;
    }
  }

  Future<void> _openScoreCalculator() async {
    final totalRounds = _getTotalRoundsForEvent();

    final result = await showScoreCalculatorDialog(
      context: context,
      totalRounds: totalRounds,
      selectedPractice: widget.eventName,
      selectedFirearmId: null,
    );

    if (result != null && mounted) {
      setState(() {
        _scoreController.text = result.score.toString();
        _xCountController.text = result.xCount > 0 ? result.xCount.toString() : '';
        _scoreBreakdown = result.scoreCounts;
        _mode = 'basic'; // Switch to basic view to show the entered values
      });
    }
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

      // Convert score breakdown to string keys for Firestore compatibility
      final breakdownForFirestore = _scoreBreakdown?.map(
        (key, value) => MapEntry(key.toString(), value),
      );

      // Get current manual entries
      final doc = await FirebaseFirestore.instance
          .collection('competitions')
          .doc(widget.competitionId)
          .get();

      final data = doc.data();
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
            'breakdown': breakdownForFirestore,
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
          Icon(
            _mode == 'select' ? Icons.edit : Icons.edit_note,
            color: primaryColor,
          ),
          const SizedBox(width: 8),
          const Text('Enter Score'),
        ],
      ),
      content: _buildContent(primaryColor, isDark),
      actions: _buildActions(primaryColor),
    );
  }

  Widget _buildContent(Color primaryColor, bool isDark) {
    switch (_mode) {
      case 'select':
        return _buildSelectionView(primaryColor, isDark);
      case 'calculator':
      case 'basic':
        return _buildBasicScoreView(primaryColor, isDark);
      default:
        return _buildSelectionView(primaryColor, isDark);
    }
  }

  Widget _buildSelectionView(Color primaryColor, bool isDark) {
    return SingleChildScrollView(
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
          const SizedBox(height: 24),

          // Option 1: Score Calculator
          _buildOptionCard(
            context: context,
            icon: Icons.calculate,
            title: 'Score Calculator',
            subtitle: 'Count rounds by score value with rounds check',
            color: primaryColor,
            isDark: isDark,
            onTap: () => _openScoreCalculator(),
          ),
          const SizedBox(height: 16),

          // Option 2: Basic Score
          _buildOptionCard(
            context: context,
            icon: Icons.edit,
            title: 'Basic Score',
            subtitle: 'Enter total score and X count directly',
            color: Colors.orange,
            isDark: isDark,
            onTap: () => setState(() => _mode = 'basic'),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicScoreView(Color primaryColor, bool isDark) {
    return Form(
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

            // Show breakdown info if available
            if (_scoreBreakdown != null && _scoreBreakdown!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Score calculated from score breakdown',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions(Color primaryColor) {
    if (_mode == 'select') {
      return [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ];
    }

    // Basic score mode
    return [
      TextButton(
        onPressed: isSubmitting ? null : () => setState(() => _mode = 'select'),
        child: const Text('Back'),
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
    ];
  }
}
