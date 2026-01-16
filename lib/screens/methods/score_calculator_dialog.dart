// lib/screens/methods/score_calculator_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';

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
}) async {
  return await showDialog<ScoreCalculatorResult>(
    context: context,
    builder: (BuildContext context) {
      return _ScoreCalculatorDialog(totalRounds: totalRounds);
    },
  );
}

class _ScoreCalculatorDialog extends StatefulWidget {
  final int? totalRounds;

  const _ScoreCalculatorDialog({
    required this.totalRounds,
  });

  @override
  State<_ScoreCalculatorDialog> createState() => _ScoreCalculatorDialogState();
}

class _ScoreCalculatorDialogState extends State<_ScoreCalculatorDialog> {
  // Map to store count of rounds for each score (10-0)
  final Map<int, int> _scoreCounts = {
    10: 0,
    9: 0,
    8: 0,
    7: 0,
    6: 0,
    5: 0,
    4: 0,
    3: 0,
    2: 0,
    1: 0,
    0: 0,
  };

  // X count (separate from score counts, doesn't affect total rounds)
  int _xCount = 0;

  int get _totalScore {
    int total = 0;
    _scoreCounts.forEach((score, count) {
      total += score * count;
    });
    return total;
  }

  int get _totalRoundsCounted {
    return _scoreCounts.values.fold(0, (sum, count) => sum + count);
  }

  void _incrementScore(int score) {
    setState(() {
      _scoreCounts[score] = _scoreCounts[score]! + 1;
    });
  }

  void _decrementScore(int score) {
    setState(() {
      if (_scoreCounts[score]! > 0) {
        _scoreCounts[score] = _scoreCounts[score]! - 1;
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                          widget.totalRounds?.toString() ?? 'N/A',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
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
                            color: allRoundsAccountedFor
                                ? Colors.green
                                : (_totalRoundsCounted > (widget.totalRounds ?? 0)
                                    ? Colors.red
                                    : primaryColor),
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
                                'X',
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

                    // Score List (10 to 0)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 11,
                      itemBuilder: (context, index) {
                        final score = 10 - index;
                        final count = _scoreCounts[score]!;

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
                                    score.toString(),
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
                                    ? () => _decrementScore(score)
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
                                onPressed: () => _incrementScore(score),
                              ),

                              const Spacer(),

                              // Score contribution
                              if (count > 0)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Text(
                                    '= ${score * count}',
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
                        if (!mounted) return;
                        Navigator.of(context).pop(
                          ScoreCalculatorResult(
                            score: _totalScore,
                            xCount: _xCount,
                            scoreCounts: Map<int, int>.from(_scoreCounts),
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
