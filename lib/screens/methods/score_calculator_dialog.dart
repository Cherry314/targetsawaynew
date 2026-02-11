// lib/screens/methods/score_calculator_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../main.dart';
import '../../models/hive/event.dart';
import '../../models/hive/firearm.dart';
import '../../models/hive/target_info.dart';
import '../../data/dropdown_values.dart';

/// Result class to return score, X count, and score breakdown from the calculator
class ScoreCalculatorResult {
  final int score;
  final int xCount;
  final Map<int, int> scoreCounts; // Map of score value (10-0) to count

  ScoreCalculatorResult({
    required this.score,
    required this.xCount,
    required this.scoreCounts,
  });
}

/// Shows a score calculator dialog that allows users to calculate their score
/// by counting how many rounds hit each score value (10-0)
Future<ScoreCalculatorResult?> showScoreCalculatorDialog({
  required BuildContext context,
  required int? totalRounds,
  String? selectedPractice,
  String? selectedFirearmId,
}) async {
  return await showDialog<ScoreCalculatorResult>(
    context: context,
    builder: (BuildContext context) {
      return _ScoreCalculatorDialog(
        totalRounds: totalRounds,
        selectedPractice: selectedPractice,
        selectedFirearmId: selectedFirearmId,
      );
    },
  );
}

class _ScoreCalculatorDialog extends StatefulWidget {
  final int? totalRounds;
  final String? selectedPractice;
  final String? selectedFirearmId;

  const _ScoreCalculatorDialog({
    required this.totalRounds,
    this.selectedPractice,
    this.selectedFirearmId,
  });

  @override
  State<_ScoreCalculatorDialog> createState() => _ScoreCalculatorDialogState();
}

class _ScoreCalculatorDialogState extends State<_ScoreCalculatorDialog> {
  // List of score zones (with string scores like "X", "10", "V", etc.)
  List<String> _scoreZones = [];
  
  // Map to store count of rounds for each score zone
  Map<String, int> _scoreZoneCounts = {};
  
  // Separate X/tie-breaker count
  String? _xZoneLabel; // The label for X count (could be "X", "V", etc.)
  int _xCount = 0;

  @override
  void initState() {
    super.initState();
    _loadTargetZones();
  }

  /// Load target zones from the TargetInfo based on selected event
  void _loadTargetZones() {
    try {
      // Try to get target info from the selected event
      final targetInfo = _getTargetInfoForEvent();
      
      if (targetInfo != null && targetInfo.zones.isNotEmpty) {
        // Sort zones by score (descending)
        final sortedZones = List.from(targetInfo.zones);
        sortedZones.sort((a, b) {
          // Handle X/V as highest score
          if (a.score.toUpperCase() == 'X' || a.score.toUpperCase() == 'V') return -1;
          if (b.score.toUpperCase() == 'X' || b.score.toUpperCase() == 'V') return 1;
          
          // Try to parse as numbers
          final aNum = int.tryParse(a.score);
          final bNum = int.tryParse(b.score);
          
          if (aNum != null && bNum != null) {
            return bNum.compareTo(aNum); // Descending order
          }
          
          return a.score.compareTo(b.score);
        });
        
        // Check if first zone is X or V (tie-breaker)
        final firstScore = sortedZones.first.score.toUpperCase();
        if (firstScore == 'X' || firstScore == 'V') {
          _xZoneLabel = sortedZones.first.score;
          _scoreZones = sortedZones.skip(1).map((z) => z.score as String).toList();
        } else {
          _xZoneLabel = null;
          _scoreZones = sortedZones.map((z) => z.score as String).toList();
        }
        
        // Add '0' at the bottom if it's not already in the zones (for missed shots)
        if (!_scoreZones.contains('0')) {
          _scoreZones.add('0');
        }
      } else {
        // Use default zones (10 to 0)
        _xZoneLabel = 'X';
        _scoreZones = ['10', '9', '8', '7', '6', '5', '4', '3', '2', '1', '0'];
      }
    } catch (e) {
      // Fall back to default
      _xZoneLabel = 'X';
      _scoreZones = ['10', '9', '8', '7', '6', '5', '4', '3', '2', '1', '0'];
    }
    
    // Initialize score counts
    _scoreZoneCounts = {for (var zone in _scoreZones) zone: 0};
  }

  /// Get TargetInfo for the selected event
  TargetInfo? _getTargetInfoForEvent() {
    if (widget.selectedPractice == null || widget.selectedPractice!.isEmpty ||
        widget.selectedFirearmId == null || widget.selectedFirearmId!.isEmpty) {
      return null;
    }

    try {
      // Check if boxes are open
      if (!Hive.isBoxOpen('events') || !Hive.isBoxOpen('target_info')) {
        return null;
      }
      
      final eventBox = Hive.box<Event>('events');
      final targetInfoBox = Hive.box<TargetInfo>('target_info');

      // Find the event by matching the practice name to event name
      Event? matchedEvent;
      for (final event in eventBox.values) {
        if (event.name == widget.selectedPractice) {
          matchedEvent = event;
          break;
        }
      }

      if (matchedEvent == null) {
        return null;
      }

      // Get the firearm ID from the code
      final firearmId = DropdownValues.getFirearmIdByCode(widget.selectedFirearmId!);

      if (firearmId == null) {
        return null;
      }

      // Create a Firearm object to get the correct content (with overrides)
      final firearm = Firearm(
        id: firearmId,
        code: widget.selectedFirearmId!,
        gunType: '',
      );

      // Get the content for this firearm (applies overrides automatically)
      final content = matchedEvent.getContentForFirearm(firearm);

      // Check if we have targets
      if (content.targets.isEmpty) {
        return null;
      }

      // Get the first target and check both title and text fields
      final firstTarget = content.targets.first;

      // Try to get target name from title first, then text
      String? targetName = firstTarget.title ?? firstTarget.text;

      if (targetName == null || targetName.isEmpty) {
        return null;
      }

      // Find matching TargetInfo
      TargetInfo? foundMatch;
      for (final targetInfo in targetInfoBox.values) {
        if (targetInfo.targetName == targetName) {
          foundMatch = targetInfo;
          break;
        }
      }

      return foundMatch;
    } catch (e) {
      return null;
    }
  }

  int get _totalScore {
    int total = 0;
    _scoreZoneCounts.forEach((scoreStr, count) {
      final scoreValue = int.tryParse(scoreStr) ?? 0;
      total += scoreValue * count;
    });
    return total;
  }

  int get _totalRoundsCounted {
    return _scoreZoneCounts.values.fold(0, (sum, count) => sum + count);
  }

  void _incrementScore(String score) {
    setState(() {
      _scoreZoneCounts[score] = (_scoreZoneCounts[score] ?? 0) + 1;
    });
  }

  void _decrementScore(String score) {
    setState(() {
      if ((_scoreZoneCounts[score] ?? 0) > 0) {
        _scoreZoneCounts[score] = _scoreZoneCounts[score]! - 1;
      }
    });
  }

  void _incrementX() {
    setState(() {
      _xCount++;
    });
  }

  void _decrementX() {
    setState(() {
      if (_xCount > 0) {
        _xCount--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check if all rounds are accounted for
    final bool allRoundsAccountedFor = widget.totalRounds != null &&
        _totalRoundsCounted == widget.totalRounds;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calculate, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Score Calculator',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Total Rounds Display - Fixed at top
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: widget.totalRounds != null 
                      ? MainAxisAlignment.spaceBetween 
                      : MainAxisAlignment.center,
                  children: [
                    // Show "Total Rounds" only if totalRounds is provided
                    if (widget.totalRounds != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Rounds',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.totalRounds.toString(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    // Always show "Counted"
                    Column(
                      crossAxisAlignment: widget.totalRounds != null 
                          ? CrossAxisAlignment.end 
                          : CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Counted',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _totalRoundsCounted.toString(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: widget.totalRounds != null
                                ? (allRoundsAccountedFor
                                    ? Colors.green
                                    : (_totalRoundsCounted > widget.totalRounds!
                                        ? Colors.red
                                        : primaryColor))
                                : primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Scrollable content area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // X Counter (separate from score) - at the top
                    if (_xZoneLabel != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _xCount > 0
                                ? primaryColor.withValues(alpha: 0.5)
                                : primaryColor.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            // X label
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  _xZoneLabel!,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Decrement button
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 22),
                              color: _xCount > 0 ? primaryColor : Colors.grey,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              onPressed: _xCount > 0 ? _decrementX : null,
                            ),

                            // Count display
                            SizedBox(
                              width: 40,
                              child: Text(
                                _xCount.toString(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _xCount > 0
                                      ? primaryColor
                                      : Colors.grey,
                                ),
                              ),
                            ),

                            // Increment button
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 22),
                              color: primaryColor,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              onPressed: _incrementX,
                            ),

                            const SizedBox(width: 4),

                            // Info text - flexible to prevent overflow
                            Flexible(
                              child: Text(
                                'Tie-breaker',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                  fontStyle: FontStyle.italic,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Score List (dynamic zones)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _scoreZones.length,
                      itemBuilder: (context, index) {
                        final scoreStr = _scoreZones[index];
                        final count = _scoreZoneCounts[scoreStr] ?? 0;
                        final scoreValue = int.tryParse(scoreStr) ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[850] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: count > 0
                                  ? primaryColor.withValues(alpha: 0.3)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Score value
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    scoreStr,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Decrement button
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 22),
                                color: count > 0 ? primaryColor : Colors.grey,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                                onPressed: count > 0
                                    ? () => _decrementScore(scoreStr)
                                    : null,
                              ),

                              // Count display
                              SizedBox(
                                width: 40,
                                child: Text(
                                  count.toString(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: count > 0
                                        ? primaryColor
                                        : Colors.grey,
                                  ),
                                ),
                              ),

                              // Increment button
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 22),
                                color: primaryColor,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                                onPressed: () => _incrementScore(scoreStr),
                              ),

                              const Spacer(),

                              // Score contribution
                              if (count > 0)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Text(
                                    '= ${scoreValue * count}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Total Score Display
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, primaryColor.withValues(alpha: 0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Score',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _totalScore.toString(),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Warning if rounds don't match

                  ],
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        // Check if rounds counted is MORE than total rounds
                        if (widget.totalRounds != null && 
                            _totalRoundsCounted > widget.totalRounds!) {
                          // Show error dialog - cannot proceed
                          await showDialog(
                            context: context,
                            builder: (BuildContext dialogContext) {
                              return AlertDialog(
                                title: const Text('Too Many Rounds'),
                                content: Text(
                                  'You have counted $_totalRoundsCounted rounds, but the total rounds should be ${widget.totalRounds}. Please correct the count before proceeding.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              );
                            },
                          );
                          // Don't proceed - user must fix the count
                          return;
                        }

                        // Check if rounds counted is less than total rounds
                        if (widget.totalRounds != null && 
                            _totalRoundsCounted < widget.totalRounds!) {
                          // Show confirmation dialog
                          final shouldReturn = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext dialogContext) {
                              return AlertDialog(
                                title: const Text('Rounds Mismatch'),
                                content: Text(
                                  'The Rounds counted ($_totalRoundsCounted) is less than the Expected Rounds (${widget.totalRounds}). Have you missed any?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(false),
                                    child: const Text('No'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(dialogContext).pop(true),
                                    child: const Text('Yes'),
                                  ),
                                ],
                              );
                            },
                          );

                          // If user selected Yes, stay in the calculator
                          if (shouldReturn == true) {
                            return;
                          }
                        }

                        // Return the calculated score, X count, and score breakdown
                        // Convert string scores to int scores for compatibility
                        final intScoreCounts = <int, int>{};
                        _scoreZoneCounts.forEach((scoreStr, count) {
                          final scoreValue = int.tryParse(scoreStr);
                          if (scoreValue != null) {
                            intScoreCounts[scoreValue] = count;
                          }
                        });
                        
                        if (!mounted) return;
                        Navigator.of(context).pop(
                          ScoreCalculatorResult(
                            score: _totalScore,
                            xCount: _xCount,
                            scoreCounts: intScoreCounts,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Enter',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
