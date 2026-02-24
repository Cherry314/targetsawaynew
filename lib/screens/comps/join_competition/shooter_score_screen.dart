// lib/screens/comps/join_competition/shooter_score_screen.dart
// Screen for shooters to calculate and submit their scores

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../main.dart';
import '../../../models/comp_history_entry.dart';
import '../../../models/hive/event.dart';
import '../../../widgets/help_icon_button.dart';
import '../../../utils/help_content.dart';
import '../../methods/score_calculator_dialog.dart';

class ShooterScoreScreen extends StatefulWidget {
  final String competitionId;
  final String eventName;
  final String shooterName;

  const ShooterScoreScreen({
    super.key,
    required this.competitionId,
    required this.eventName,
    required this.shooterName,
  });

  @override
  State<ShooterScoreScreen> createState() => _ShooterScoreScreenState();
}

class _ShooterScoreScreenState extends State<ShooterScoreScreen> {
  final scoreController = TextEditingController();
  final xController = TextEditingController();
  Map<int, int>? scoreBreakdown;
  bool isSubmitting = false;
  bool hasSubmitted = false;
  bool resultsReceived = false;
  int finalPosition = 0;
  int finalTotalShooters = 0;
  int finalScore = 0;
  int finalXCount = 0;
  List<Map<String, dynamic>>? finalResults;
  StreamSubscription<DocumentSnapshot>? _competitionSubscription;

  @override
  void initState() {
    super.initState();
    _startCompetitionListener();
  }

  @override
  void dispose() {
    _competitionSubscription?.cancel();
    scoreController.dispose();
    xController.dispose();
    super.dispose();
  }

  /// Listen for competition completion and save results to Hive
  void _startCompetitionListener() {
    _competitionSubscription = FirebaseFirestore.instance
        .collection('competitions')
        .doc(widget.competitionId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data();
      if (data == null) return;

      // Check if competition has ended
      final status = data['status'] as String?;
      if (status == 'completed' && !resultsReceived) {
        _processCompetitionResults(data);
      }
    });
  }

  /// Process competition results and save to Hive
  Future<void> _processCompetitionResults(Map<String, dynamic> data) async {
    final participants = (data['participants'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    // Get full results from Firestore
    final finalResults = (data['finalResults'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    // Find this shooter in the participants
    final shooterData = participants.firstWhere(
      (p) => p['name'] == widget.shooterName,
      orElse: () => {},
    );

    if (shooterData.isEmpty) return;

    final score = shooterData['score'] as int? ?? 0;
    final xCount = shooterData['xCount'] as int? ?? 0;
    final position = shooterData['position'] as int? ?? 0;
    final totalShooters = shooterData['totalShooters'] as int? ?? 0;

    // Only save if we have valid data
    if (position > 0 && totalShooters > 0) {
      // Check if already saved to avoid duplicates
      final box = Hive.box<CompHistoryEntry>('comp_history');
      final alreadyExists = box.values.any((entry) =>
          entry.event == widget.eventName &&
          entry.date.isAfter(DateTime.now().subtract(const Duration(hours: 24))));

      if (!alreadyExists) {
        final entry = CompHistoryEntry(
          date: DateTime.now(),
          event: widget.eventName,
          score: score,
          xCount: xCount,
          position: position,
          totalShooters: totalShooters,
          finalResults: finalResults.isNotEmpty ? finalResults : null,
        );

        await box.add(entry);
      }

      if (mounted) {
        setState(() {
          resultsReceived = true;
          finalPosition = position;
          finalTotalShooters = totalShooters;
          finalScore = score;
          finalXCount = xCount;
          this.finalResults = finalResults;
        });
      }
    }
  }

  String _getPositionSuffix(int position) {
    if (position == 1) return 'st';
    if (position == 2) return 'nd';
    if (position == 3) return 'rd';
    return 'th';
  }

  Future<void> _openScoreCalculator() async {
    // Get total rounds for this event
    final totalRounds = _getTotalRoundsForEvent();
    
    final result = await showScoreCalculatorDialog(
      context: context,
      totalRounds: totalRounds,
      selectedPractice: widget.eventName,
      selectedFirearmId: null,
    );

    if (result != null && mounted) {
      setState(() {
        scoreController.text = result.score.toString();
        xController.text = result.xCount > 0 ? result.xCount.toString() : '';
        scoreBreakdown = result.scoreCounts;
      });
    }
  }

  /// Get total rounds for the event from courseOfFire
  int? _getTotalRoundsForEvent() {
    // Return null if event name is empty
    if (widget.eventName.isEmpty) {
      return null;
    }

    try {
      // Check if events box is open
      if (!Hive.isBoxOpen('events')) {
        return null;
      }

      final eventBox = Hive.box<Event>('events');

      // Find the event by matching the event name
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

      // Get total rounds from base content's courseOfFire
      return matchedEvent.baseContent.courseOfFire.totalRounds;
    } catch (e) {
      return null;
    }
  }

  Future<void> _submitScore() async {
    // Validate
    if (scoreController.text.isEmpty) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final score = int.parse(scoreController.text);
      final xCount = int.tryParse(xController.text) ?? 0;

      // Get current participant list and update this user's entry
      final doc = await FirebaseFirestore.instance
          .collection('competitions')
          .doc(widget.competitionId)
          .get();

      final data = doc.data();
      final participants = (data?['participants'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];

      // Find and update this participant's entry
      // Note: Using DateTime.now() instead of FieldValue.serverTimestamp()
      // because server timestamps can't be used inside array elements
      final now = DateTime.now();
      
      // Convert score breakdown to string keys for Firestore compatibility
      // Firestore doesn't support integer keys in maps
      final breakdownForFirestore = scoreBreakdown?.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      
      final updatedParticipants = participants.map((p) {
        if (p['name'] == widget.shooterName) {
          return {
            ...p,
            'score': score,
            'xCount': xCount,
            'submitted': true,
            'submittedAt': now,
            'breakdown': breakdownForFirestore,
          };
        }
        return p;
      }).toList();

      await FirebaseFirestore.instance
          .collection('competitions')
          .doc(widget.competitionId)
          .update({
        'participants': updatedParticipants,
      });

      if (mounted) {
        setState(() {
          isSubmitting = false;
          hasSubmitted = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = themeProvider.primaryColor;

    return WillPopScope(
      onWillPop: () async {
        // Show confirmation if score not submitted
        if (!hasSubmitted && scoreController.text.isNotEmpty) {
          final shouldLeave = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Leave Without Submitting?'),
              content: const Text(
                  'You have entered a score but not submitted it. Are you sure you want to leave?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Stay'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Leave'),
                ),
              ],
            ),
          );
          return shouldLeave ?? false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
        appBar: AppBar(
          elevation: 0,
          title: const Text(
            'Enter Score',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          actions: const [
            HelpIconButton(
              title: 'Shooter Score Help',
              content: HelpContent.shooterScoreScreen,
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Competition Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor,
                        primaryColor.withValues(alpha: 0.8)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        size: 40,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.eventName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Shooter: ${widget.shooterName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Competition Results Card (shown when results received) - moved to top
                if (resultsReceived)
                  _buildResultsCard(isDark, primaryColor)
                else ...[
                  // Score Entry Card (only shown when no results yet)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Score',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your score manually or use the score calculator',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Score Calculator Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _openScoreCalculator,
                            icon: const Icon(Icons.calculate),
                            label: const Text('Open Score Calculator'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor.withValues(alpha: 0.1),
                              foregroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Score and X Input Row
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: scoreController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Score',
                                  prefixIcon:
                                      Icon(Icons.military_tech, color: primaryColor),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor:
                                      isDark ? Colors.grey[800] : Colors.grey[50],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: xController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  prefixIcon:
                                      Icon(Icons.gps_fixed, color: primaryColor),
                                  labelText: 'X',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor:
                                      isDark ? Colors.grey[800] : Colors.grey[50],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button or Score Submitted Box
                  if (!hasSubmitted)
                    ElevatedButton.icon(
                      onPressed: isSubmitting ? null : _submitScore,
                      icon: isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(
                        isSubmitting ? 'Submitting...' : 'Submit Score',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 48,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Score Submitted!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Your score has been sent to the competition runner.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                ],

                const SizedBox(height: 20),

                // Done Button (only shown when submitted or results received)
                if (hasSubmitted || resultsReceived)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Done'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsCard(bool isDark, Color primaryColor) {
    Color positionColor;
    if (finalPosition == 1) {
      positionColor = Colors.amber;
    } else if (finalPosition == 2) {
      positionColor = Colors.grey.shade400;
    } else if (finalPosition == 3) {
      positionColor = Colors.brown.shade300;
    } else {
      positionColor = Colors.green;
    }

    IconData positionIcon;
    if (finalPosition <= 3) {
      positionIcon = Icons.emoji_events;
    } else {
      positionIcon = Icons.check_circle;
    }

    // Get top 3 from finalResults for podium
    final top3 = finalResults?.take(3).toList() ?? [];
    final first = top3.isNotEmpty ? top3[0] : null;
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    return Column(
      children: [
        // User's placement card - Competition Complete (now at top)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                positionColor.withValues(alpha: 0.2),
                positionColor.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: positionColor.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                positionIcon,
                size: 48,
                color: positionColor,
              ),
              const SizedBox(height: 12),
              Text(
                'Competition Complete!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: positionColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$finalPosition${_getPositionSuffix(finalPosition)} Place',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: positionColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'of $finalTotalShooters shooters',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(
                        finalScore.toString(),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      Text(
                        'Score',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  if (finalXCount > 0) ...[
                    const SizedBox(width: 32),
                    Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.gps_fixed,
                              size: 24,
                              color: Colors.amber[700],
                            ),
                            Text(
                              finalXCount.toString(),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[700],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'X Count',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Saved to Competition History',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black38,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Podium display (if we have results with at least 2 shooters)
        if (top3.length >= 2)
          _buildPodium(second, first, third, isDark, primaryColor),

        if (top3.length >= 2) const SizedBox(height: 20),

        // Full Standings list
        if (finalResults != null && finalResults!.isNotEmpty)
          _buildFullStandings(isDark, primaryColor),
      ],
    );
  }

  Widget _buildPodium(
    Map<String, dynamic>? second,
    Map<String, dynamic>? first,
    Map<String, dynamic>? third,
    bool isDark,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Podium',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 2nd place
                if (second != null)
                  Flexible(
                    child: _buildPodiumItem(
                      position: 2,
                      name: second['name'] as String,
                      score: second['score'] as int?,
                      xCount: second['xCount'] as int? ?? 0,
                      color: Colors.grey.shade400,
                      height: 180,
                      isDark: isDark,
                    ),
                  ),
                if (second != null) const SizedBox(width: 12),
                // 1st place
                if (first != null)
                  Flexible(
                    child: _buildPodiumItem(
                      position: 1,
                      name: first['name'] as String,
                      score: first['score'] as int?,
                      xCount: first['xCount'] as int? ?? 0,
                      color: Colors.amber,
                      height: 220,
                      isDark: isDark,
                      isFirst: true,
                    ),
                  ),
                if (first != null) const SizedBox(width: 12),
                // 3rd place
                if (third != null)
                  Flexible(
                    child: _buildPodiumItem(
                      position: 3,
                      name: third['name'] as String,
                      score: third['score'] as int?,
                      xCount: third['xCount'] as int? ?? 0,
                      color: Colors.brown.shade300,
                      height: 140,
                      isDark: isDark,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem({
    required int position,
    required String name,
    required int? score,
    required int xCount,
    required Color color,
    required double height,
    required bool isDark,
    bool isFirst = false,
  }) {
    return Column(
      children: [
        // Variable-height content at top
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Crown for 1st place
              if (isFirst)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Icon(
                    Icons.emoji_events,
                    size: 32,
                    color: Colors.amber[700],
                  ),
                ),
              // Name card
              Container(
                width: 90,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (score != null) ...[
                      Text(
                        score.toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      if (xCount > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.gps_fixed,
                              size: 10,
                              color: Colors.amber[700],
                            ),
                            Text(
                              xCount.toString(),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.amber[700],
                              ),
                            ),
                          ],
                        ),
                    ] else
                      Text(
                        '-',
                        style: TextStyle(
                          fontSize: 18,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Position number
        Container(
          width: 90,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
            ),
          ),
          child: Center(
            child: Text(
              '#$position',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        // Podium base
        Container(
          width: 90,
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(8),
            ),
            border: Border.all(
              color: color.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullStandings(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.leaderboard, color: primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Full Standings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...finalResults!.asMap().entries.map((entry) {
            final index = entry.key;
            final result = entry.value;
            final position = index + 1;
            final name = result['name'] as String;
            final score = result['score'] as int?;
            final xCount = result['xCount'] as int? ?? 0;

            // Determine rank color
            Color rankColor;
            if (position == 1) {
              rankColor = Colors.amber;
            } else if (position == 2) {
              rankColor = Colors.grey.shade400;
            } else if (position == 3) {
              rankColor = Colors.brown.shade300;
            } else {
              rankColor = primaryColor;
            }

            // Check if this is the current user
            final isCurrentUser = name == widget.shooterName;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? primaryColor.withValues(alpha: 0.1)
                    : isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: isCurrentUser
                    ? Border.all(color: primaryColor.withValues(alpha: 0.5), width: 1)
                    : null,
              ),
              child: Row(
                children: [
                  // Position
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: rankColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        position.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: rankColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  // Score
                  if (score != null) ...[
                    Text(
                      score.toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    if (xCount > 0) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.gps_fixed,
                        size: 14,
                        color: Colors.amber[700],
                      ),
                      Text(
                        xCount.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.amber[700],
                        ),
                      ),
                    ],
                  ] else
                    Text(
                      '-',
                      style: TextStyle(
                        fontSize: 18,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
