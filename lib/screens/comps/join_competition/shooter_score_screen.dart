// lib/screens/comps/join_competition/shooter_score_screen.dart
// Screen for shooters to calculate and submit their scores

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../main.dart';
import '../../../models/comp_history_entry.dart';
import '../../../models/score_entry.dart';
import '../../../widgets/help_icon_button.dart';
import '../../../utils/help_content.dart';
import '../../../utils/score_calculator_utils.dart';
import '../../methods/score_calculator_dialog.dart';

class ShooterScoreScreen extends StatefulWidget {
  final String competitionId;
  final String eventName;
  final String? firearmCode;
  final String shooterName;

  const ShooterScoreScreen({
    super.key,
    required this.competitionId,
    required this.eventName,
    this.firearmCode,
    required this.shooterName,
  });

  @override
  State<ShooterScoreScreen> createState() => _ShooterScoreScreenState();
}

class _ShooterScoreScreenState extends State<ShooterScoreScreen> {
  final scoreController = TextEditingController();
  final xController = TextEditingController();
  Map<int, int>? scoreBreakdown;
  String scoringMode = 'basic';
  int targetCount = 1;
  int? activeTargetIndex;
  String? activeCheckpointLabel;
  final List<int?> targetScores = [];
  final List<int?> targetXCounts = [];
  final List<Map<int, int>?> targetBreakdowns = [];
  final List<int?> targetBasicScores = [];
  final Set<int> submittedTargets = {};
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

          _syncScoringConfig(data);

          // Check if competition has ended
          final status = data['status'] as String?;
          if (status == 'completed' && !resultsReceived) {
            _processCompetitionResults(data);
          }
        });
  }

  void _syncScoringConfig(Map<String, dynamic> data) {
    final nextMode = data['scoringMode'] as String? ?? 'basic';
    final nextTargetCount = nextMode == 'full'
        ? (ScoreCalculatorUtils.getRequiredTargetCount(
                eventName: widget.eventName,
                firearmCode: widget.firearmCode,
              ) ??
              1)
        : 1;

    final nextActiveTargetIndex = (data['activeTargetIndex'] as num?)?.toInt();
    final nextActiveCheckpointLabel = data['activeCheckpointLabel'] as String?;

    if (nextMode == scoringMode &&
        nextTargetCount == targetCount &&
        nextActiveTargetIndex == activeTargetIndex &&
        nextActiveCheckpointLabel == activeCheckpointLabel) {
      return;
    }

    if (!mounted) return;
    setState(() {
      scoringMode = nextMode;
      targetCount = nextTargetCount;
      activeTargetIndex = nextActiveTargetIndex;
      activeCheckpointLabel = nextActiveCheckpointLabel;
      _ensureTargetSlots(nextTargetCount);
    });
  }

  void _ensureTargetSlots(int count) {
    while (targetScores.length < count) {
      targetScores.add(null);
      targetXCounts.add(null);
      targetBreakdowns.add(null);
      targetBasicScores.add(null);
    }

    if (targetScores.length > count) {
      targetScores.removeRange(count, targetScores.length);
      targetXCounts.removeRange(count, targetXCounts.length);
      targetBreakdowns.removeRange(count, targetBreakdowns.length);
      targetBasicScores.removeRange(count, targetBasicScores.length);
      submittedTargets.removeWhere((targetIndex) => targetIndex >= count);
    }
  }

  /// Process competition results and save to Hive
  Future<void> _processCompetitionResults(Map<String, dynamic> data) async {
    final participants =
        (data['participants'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    // Get full results from Firestore
    final finalResults =
        (data['finalResults'] as List<dynamic>?)
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
      final alreadyExists = box.values.any(
        (entry) =>
            entry.event == widget.eventName &&
            entry.date.isAfter(
              DateTime.now().subtract(const Duration(hours: 24)),
            ),
      );

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
      selectedFirearmId: widget.firearmCode,
    );

    if (result != null && mounted) {
      setState(() {
        scoreController.text = result.score.toString();
        xController.text = result.xCount > 0 ? result.xCount.toString() : '';
        scoreBreakdown = result.scoreCounts;
      });
    }
  }

  Future<void> _openScoreCalculatorForTarget(int index) async {
    final result = await showScoreCalculatorDialog(
      context: context,
      totalRounds: ScoreCalculatorUtils.getRoundsForTarget(
        eventName: widget.eventName,
        firearmCode: widget.firearmCode,
        targetIndex: index,
      ),
      selectedPractice: widget.eventName,
      selectedFirearmId: widget.firearmCode,
    );

    if (result != null && mounted) {
      setState(() {
        targetScores[index] = result.score;
        targetXCounts[index] = result.xCount > 0 ? result.xCount : 0;
        targetBreakdowns[index] = result.scoreCounts;
        targetBasicScores[index] = null;
      });
    }
  }

  Future<void> _openBasicScoreForTarget(int index) async {
    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => _TargetBasicScoreDialog(
        targetNumber: index + 1,
        initialScore: targetScores[index]?.toString() ?? '',
        initialXCount: targetXCounts[index]?.toString() ?? '',
      ),
    );

    if (result != null && mounted) {
      setState(() {
        targetScores[index] = result['score'];
        targetXCounts[index] = result['xCount'];
        targetBreakdowns[index] = null;
        targetBasicScores[index] = result['score'];
      });
    }
  }

  /// Get total rounds for the event from the shared score calculator context.
  int? _getTotalRoundsForEvent() {
    return ScoreCalculatorUtils.getTotalRounds(
      eventName: widget.eventName,
      firearmCode: widget.firearmCode,
    );
  }

  Future<void> _submitTargetScore(int targetIndex) async {
    final score = targetScores[targetIndex];
    if (score == null) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('competitions')
          .doc(widget.competitionId)
          .get();

      final data = doc.data();
      final participants =
          (data?['participants'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      final now = DateTime.now();
      final xCount = targetXCounts[targetIndex] ?? 0;
      final breakdownForFirestore = ScoreCalculatorUtils.breakdownForFirestore(
        targetBreakdowns[targetIndex],
      );

      final updatedParticipants = participants.map((p) {
        if (p['name'] != widget.shooterName) return p;

        final scores = List<int?>.filled(targetCount, null);
        final xs = List<int>.filled(targetCount, 0);
        final basics = List<int>.filled(targetCount, 0);
        final breakdowns = List<Map<String, int>?>.filled(targetCount, null);

        final existingScores = p['targetScores'];
        if (existingScores is List) {
          for (var i = 0; i < existingScores.length && i < targetCount; i++) {
            scores[i] = (existingScores[i] as num?)?.toInt();
          }
        }
        final existingXs = p['targetXCounts'];
        if (existingXs is List) {
          for (var i = 0; i < existingXs.length && i < targetCount; i++) {
            xs[i] = (existingXs[i] as num?)?.toInt() ?? 0;
          }
        }
        final existingBasics = p['targetBasicScores'];
        if (existingBasics is List) {
          for (var i = 0; i < existingBasics.length && i < targetCount; i++) {
            basics[i] = (existingBasics[i] as num?)?.toInt() ?? 0;
          }
        }
        final existingBreakdowns = p['targetBreakdowns'];
        if (existingBreakdowns is List) {
          for (
            var i = 0;
            i < existingBreakdowns.length && i < targetCount;
            i++
          ) {
            final item = existingBreakdowns[i];
            if (item is Map) {
              breakdowns[i] = item.map(
                (key, value) =>
                    MapEntry(key.toString(), (value as num).toInt()),
              );
            }
          }
        }

        scores[targetIndex] = score;
        xs[targetIndex] = xCount;
        basics[targetIndex] = targetBasicScores[targetIndex] ?? 0;
        breakdowns[targetIndex] = breakdownForFirestore;

        final totalScore = scores.whereType<int>().fold<int>(
          0,
          (total, s) => total + s,
        );
        final totalX = xs.fold<int>(0, (total, x) => total + x);
        final submitted = scores.every((targetScore) => targetScore != null);

        return {
          ...p,
          'score': totalScore,
          'xCount': totalX,
          'submitted': submitted,
          'submittedAt': submitted ? now : p['submittedAt'],
          'lastTargetSubmittedAt': now,
          'targetScores': scores,
          'targetXCounts': xs,
          'targetBasicScores': basics,
          'targetBreakdowns': breakdowns,
        };
      }).toList();

      await FirebaseFirestore.instance
          .collection('competitions')
          .doc(widget.competitionId)
          .update({'participants': updatedParticipants});

      if (mounted) {
        setState(() {
          isSubmitting = false;
          submittedTargets.add(targetIndex);
          hasSubmitted = submittedTargets.length == targetCount;
        });
        if (hasSubmitted) {
          await _saveLocalScoreEntry();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  Future<void> _submitScore() async {
    if (scoringMode == 'full') {
      final missingTarget = targetScores.indexWhere((score) => score == null);
      if (missingTarget >= 0) return;
      for (var i = 0; i < targetCount; i++) {
        if (!submittedTargets.contains(i)) {
          await _submitTargetScore(i);
        }
      }
      return;
    }

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
      final participants =
          (data?['participants'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];

      // Find and update this participant's entry
      // Note: Using DateTime.now() instead of FieldValue.serverTimestamp()
      // because server timestamps can't be used inside array elements
      final now = DateTime.now();

      // Convert score breakdown to string keys for Firestore compatibility.
      final breakdownForFirestore = ScoreCalculatorUtils.breakdownForFirestore(
        scoreBreakdown,
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
          .update({'participants': updatedParticipants});

      await _saveLocalScoreEntry();

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

  Future<void> _saveLocalScoreEntry() async {
    if (!Hive.isBoxOpen('scores')) return;

    final box = Hive.box<ScoreEntry>('scores');
    final id = '${widget.competitionId}_${widget.shooterName}';
    final alreadySaved = box.containsKey(id);
    if (alreadySaved) return;

    final isFullScoring = scoringMode == 'full';
    final totalScore = isFullScoring
        ? targetScores.whereType<int>().fold<int>(
            0,
            (total, score) => total + score,
          )
        : int.parse(scoreController.text);
    final totalX = isFullScoring
        ? targetXCounts.whereType<int>().fold<int>(0, (total, x) => total + x)
        : (int.tryParse(xController.text) ?? 0);

    final entry = ScoreEntry(
      id: id,
      date: DateTime.now(),
      score: totalScore,
      practice: widget.eventName,
      caliber: widget.firearmCode ?? '',
      firearmId: widget.firearmCode ?? '',
      firearm: widget.firearmCode,
      notes:
          'Competition score submitted from competition ${widget.competitionId}',
      comp: true,
      compId: widget.competitionId,
      compResult: null,
      targetCaptured: false,
      x: totalX,
      scoreX: isFullScoring ? null : (scoreBreakdown != null ? totalX : null),
      score10: isFullScoring ? null : scoreBreakdown?[10],
      score9: isFullScoring ? null : scoreBreakdown?[9],
      score8: isFullScoring ? null : scoreBreakdown?[8],
      score7: isFullScoring ? null : scoreBreakdown?[7],
      score6: isFullScoring ? null : scoreBreakdown?[6],
      score5: isFullScoring ? null : scoreBreakdown?[5],
      score4: isFullScoring ? null : scoreBreakdown?[4],
      score3: isFullScoring ? null : scoreBreakdown?[3],
      score2: isFullScoring ? null : scoreBreakdown?[2],
      score1: isFullScoring ? null : scoreBreakdown?[1],
      score0: isFullScoring ? null : scoreBreakdown?[0],
      scoreBasic: isFullScoring
          ? null
          : (scoreBreakdown == null ? totalScore : null),
      targetFilePaths: isFullScoring
          ? List<String>.filled(targetCount, '')
          : null,
      thumbnailFilePaths: isFullScoring
          ? List<String>.filled(targetCount, '')
          : null,
      targetsCaptured: isFullScoring
          ? List<bool>.filled(targetCount, false)
          : [false],
      xs: isFullScoring
          ? List<int>.generate(targetCount, (i) => targetXCounts[i] ?? 0)
          : [totalX],
      scoreXs: isFullScoring
          ? List<int>.generate(targetCount, (i) => targetXCounts[i] ?? 0)
          : (scoreBreakdown != null ? [totalX] : null),
      score10s: isFullScoring
          ? List<int>.generate(
              targetCount,
              (i) => targetBreakdowns[i]?[10] ?? 0,
            )
          : (scoreBreakdown != null ? [scoreBreakdown![10] ?? 0] : null),
      score9s: isFullScoring
          ? List<int>.generate(targetCount, (i) => targetBreakdowns[i]?[9] ?? 0)
          : (scoreBreakdown != null ? [scoreBreakdown![9] ?? 0] : null),
      score8s: isFullScoring
          ? List<int>.generate(targetCount, (i) => targetBreakdowns[i]?[8] ?? 0)
          : (scoreBreakdown != null ? [scoreBreakdown![8] ?? 0] : null),
      score7s: isFullScoring
          ? List<int>.generate(targetCount, (i) => targetBreakdowns[i]?[7] ?? 0)
          : (scoreBreakdown != null ? [scoreBreakdown![7] ?? 0] : null),
      score6s: isFullScoring
          ? List<int>.generate(targetCount, (i) => targetBreakdowns[i]?[6] ?? 0)
          : (scoreBreakdown != null ? [scoreBreakdown![6] ?? 0] : null),
      score5s: isFullScoring
          ? List<int>.generate(targetCount, (i) => targetBreakdowns[i]?[5] ?? 0)
          : (scoreBreakdown != null ? [scoreBreakdown![5] ?? 0] : null),
      score4s: isFullScoring
          ? List<int>.generate(targetCount, (i) => targetBreakdowns[i]?[4] ?? 0)
          : (scoreBreakdown != null ? [scoreBreakdown![4] ?? 0] : null),
      score3s: isFullScoring
          ? List<int>.generate(targetCount, (i) => targetBreakdowns[i]?[3] ?? 0)
          : (scoreBreakdown != null ? [scoreBreakdown![3] ?? 0] : null),
      score2s: isFullScoring
          ? List<int>.generate(targetCount, (i) => targetBreakdowns[i]?[2] ?? 0)
          : (scoreBreakdown != null ? [scoreBreakdown![2] ?? 0] : null),
      score1s: isFullScoring
          ? List<int>.generate(targetCount, (i) => targetBreakdowns[i]?[1] ?? 0)
          : (scoreBreakdown != null ? [scoreBreakdown![1] ?? 0] : null),
      score0s: isFullScoring
          ? List<int>.generate(targetCount, (i) => targetBreakdowns[i]?[0] ?? 0)
          : (scoreBreakdown != null ? [scoreBreakdown![0] ?? 0] : null),
      scoreBasics: isFullScoring
          ? List<int>.generate(targetCount, (i) => targetBasicScores[i] ?? 0)
          : [scoreBreakdown == null ? totalScore : 0],
    );

    await box.put(id, entry);
  }

  Widget _buildFullCompetitionScoringCard(bool isDark, Color primaryColor) {
    _ensureTargetSlots(targetCount);
    final totalScore = targetScores.whereType<int>().fold<int>(
      0,
      (total, score) => total + score,
    );
    final totalX = targetXCounts.whereType<int>().fold<int>(
      0,
      (total, x) => total + x,
    );

    final activeIndex = activeTargetIndex;
    final showActiveTarget =
        activeIndex != null &&
        activeIndex >= 0 &&
        activeIndex < targetCount &&
        !submittedTargets.contains(activeIndex);

    return Column(
      children: [
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
                'Full Competition Scoring',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                showActiveTarget
                    ? 'The competition runner is ready for this target score.'
                    : submittedTargets.isEmpty
                    ? 'You will be prompted when the first target is ready to score.'
                    : 'Waiting for next target to score.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
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
                    const Icon(Icons.summarize, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Total so far: $totalScore${totalX > 0 ? '  X: $totalX' : ''}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (showActiveTarget)
                _buildTargetScoreCard(activeIndex, isDark, primaryColor)
              else
                _buildWaitingForTargetCard(isDark, primaryColor),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (hasSubmitted)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green),
            ),
            child: const Column(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                SizedBox(height: 12),
                Text(
                  'All Scores Submitted!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildWaitingForTargetCard(bool isDark, Color primaryColor) {
    final message = submittedTargets.isEmpty
        ? 'Full competition scoring is enabled. You will be prompted when the first target is ready to score.'
        : 'Your score has been submitted. Waiting for next target to score.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(Icons.hourglass_top, color: primaryColor, size: 36),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTargetScoreCard(int index, bool isDark, Color primaryColor) {
    final submitted = submittedTargets.contains(index);
    final score = targetScores[index];
    final xCount = targetXCounts[index] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: submitted ? Colors.green : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Target ${index + 1}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              if (submitted)
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: submitted
                      ? null
                      : () => _openScoreCalculatorForTarget(index),
                  icon: const Icon(Icons.calculate),
                  label: const Text('Calculator'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: submitted
                      ? null
                      : () => _openBasicScoreForTarget(index),
                  icon: const Icon(Icons.edit),
                  label: const Text('Basic'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (score != null) ...[
            const SizedBox(height: 10),
            Text(
              'Score: $score${xCount > 0 ? '  X: $xCount' : ''}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: submitted || isSubmitting
                    ? null
                    : () => _submitTargetScore(index),
                icon: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  submitted ? 'Submitted' : 'Submit Target ${index + 1}',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: submitted ? Colors.green : primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
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
                'You have entered a score but not submitted it. Are you sure you want to leave?',
              ),
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
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
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
                        primaryColor.withValues(alpha: 0.8),
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
                      if (widget.firearmCode?.isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.firearmCode!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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
                  if (scoringMode == 'full')
                    _buildFullCompetitionScoringCard(isDark, primaryColor)
                  else
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
                                backgroundColor: primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                foregroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
                                    prefixIcon: Icon(
                                      Icons.military_tech,
                                      color: primaryColor,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[50],
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
                                    prefixIcon: Icon(
                                      Icons.gps_fixed,
                                      color: primaryColor,
                                    ),
                                    labelText: 'X',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[50],
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
                            style: TextStyle(fontSize: 14, color: Colors.green),
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
              Icon(positionIcon, size: 48, color: positionColor),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
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
            border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
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
                    : isDark
                    ? Colors.grey[800]
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: isCurrentUser
                    ? Border.all(
                        color: primaryColor.withValues(alpha: 0.5),
                        width: 1,
                      )
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
                        fontWeight: isCurrentUser
                            ? FontWeight.bold
                            : FontWeight.w500,
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
                      Icon(Icons.gps_fixed, size: 14, color: Colors.amber[700]),
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

class _TargetBasicScoreDialog extends StatefulWidget {
  final int targetNumber;
  final String initialScore;
  final String initialXCount;

  const _TargetBasicScoreDialog({
    required this.targetNumber,
    required this.initialScore,
    required this.initialXCount,
  });

  @override
  State<_TargetBasicScoreDialog> createState() =>
      _TargetBasicScoreDialogState();
}

class _TargetBasicScoreDialogState extends State<_TargetBasicScoreDialog> {
  late final TextEditingController _scoreController;
  late final TextEditingController _xController;

  @override
  void initState() {
    super.initState();
    _scoreController = TextEditingController(text: widget.initialScore);
    _xController = TextEditingController(text: widget.initialXCount);
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _xController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Target ${widget.targetNumber} Basic Score'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _scoreController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Score'),
          ),
          TextField(
            controller: _xController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'X Count'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final score = int.tryParse(_scoreController.text.trim());
            if (score == null) return;
            Navigator.pop(context, {
              'score': score,
              'xCount': int.tryParse(_xController.text.trim()) ?? 0,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
