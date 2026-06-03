import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../main.dart';
import '../../../models/hive/event.dart';
import '../../../models/hive/event_content.dart';
import '../../../models/hive/practice.dart';
import '../../../models/hive/stage.dart';
import 'enter_score_dialog.dart';

class CompetitionEventOverviewScreen extends StatelessWidget {
  final Event event;
  final EventContent content;
  final String firearmCode;
  final String competitionId;
  final String scoringMode;

  const CompetitionEventOverviewScreen({
    super.key,
    required this.event,
    required this.content,
    required this.firearmCode,
    required this.competitionId,
    required this.scoringMode,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Provider.of<ThemeProvider>(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final rows = _buildOverviewRows();
    final steps = _buildCompetitionSteps(
      content.practices,
      event,
      scoringMode == 'full',
    );
    final infoActions = _buildInfoActions(content);

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
      appBar: _buildCompetitionAppBar(event.name, primaryColor),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildOverviewCard(rows, primaryColor, isDark),
              ),
            ),
            _buildBottomControls(
              context: context,
              isDark: isDark,
              primaryColor: primaryColor,
              infoActions: infoActions,
              enabled: steps.isNotEmpty,
              label: 'Continue',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => _CompetitionPracticeStageScreen(
                      competitionId: competitionId,
                      eventName: event.name,
                      firearmCode: firearmCode,
                      steps: steps,
                      infoActions: infoActions,
                      currentIndex: 0,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(
    List<_DetailRow> rows,
    Color primaryColor,
    bool isDark,
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
      child: rows.isEmpty
          ? Text(
              'No event overview details are available.',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 14,
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  _buildDetailRow(rows[i], primaryColor, isDark),
                  if (i != rows.length - 1)
                    Divider(
                      height: 24,
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                    ),
                ],
              ],
            ),
    );
  }

  List<_DetailRow> _buildOverviewRows() {
    final rows = <_DetailRow>[];

    final targetLine = _targetLine();
    if (targetLine != null) {
      rows.add(_DetailRow('Targets / Quantity', targetLine, Icons.gps_fixed));
    }

    final sights = _joinNonEmpty(content.sights.map((sight) => sight.text));
    if (sights != null) {
      rows.add(_DetailRow('Sights', sights, Icons.visibility));
    }

    final ammunition = _joinNonEmpty(
      content.ammunition?.map((ammo) => _titleText(ammo.title, ammo.text)) ??
          [],
    );
    if (ammunition != null) {
      rows.add(_DetailRow('Ammunition', ammunition, Icons.inventory_2));
    }

    final positions = _joinNonEmpty(
      content.positions.map(
        (position) => _titleText(position.title, position.text),
      ),
    );
    if (positions != null) {
      rows.add(_DetailRow('Position', positions, Icons.accessibility_new));
    }

    final readyPositions = _joinNonEmpty(
      content.readyPositions.map(
        (readyPosition) => _titleText(readyPosition.title, readyPosition.text),
      ),
    );
    if (readyPositions != null) {
      rows.add(_DetailRow('Ready Position', readyPositions, Icons.play_circle));
    }

    final courseOfFire = _courseOfFireText();
    if (courseOfFire != null) {
      rows.add(_DetailRow('Course of Fire', courseOfFire, Icons.route));
    }

    final sighters = _joinNonEmpty(content.sighters?.map((s) => s.text) ?? []);
    if (sighters != null) {
      rows.add(_DetailRow('Sighters', sighters, Icons.adjust));
    }

    return rows;
  }

  String? _targetLine() {
    final targetParts = content.targets
        .map((target) {
          final name = _firstNonEmpty([target.title, target.text]);
          final qty = target.qtyNeeded;
          if (name == null && qty == null) return null;
          if (name == null) return 'Qty $qty';
          if (qty == null) return name;
          return '$name - Qty $qty';
        })
        .whereType<String>()
        .toList();

    if (targetParts.isEmpty) return null;
    return targetParts.join('\n');
  }

  String? _courseOfFireText() {
    final course = content.courseOfFire;
    final parts = <String>[];

    if (course.distance != null) parts.add('Distance: ${course.distance}m');
    _addLabelledText(parts, 'Distance notes', course.distanceNotes);
    _addValueWithNotes(parts, 'Time', course.totalTime, course.timeNotes);
    _addValueWithNotes(parts, 'Rounds', course.totalRounds, course.roundsNotes);
    _addValueWithNotes(
      parts,
      'Max score',
      course.maxScore,
      course.maxScoreNotes,
    );
    _addLabelledText(parts, 'Notes', course.generalNotes);

    if (parts.isEmpty) return null;
    return parts.join('\n');
  }
}

class _CompetitionPracticeStageScreen extends StatelessWidget {
  final String competitionId;
  final String eventName;
  final String firearmCode;
  final List<_CompetitionStep> steps;
  final List<_InfoAction> infoActions;
  final int currentIndex;

  const _CompetitionPracticeStageScreen({
    required this.competitionId,
    required this.eventName,
    required this.firearmCode,
    required this.steps,
    required this.infoActions,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Provider.of<ThemeProvider>(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final step = steps[currentIndex];
    final rows = _buildRows(step);
    final hasNext = currentIndex < steps.length - 1;
    final nextStep = hasNext ? steps[currentIndex + 1] : null;
    final nextIsScoreCheckpoint = nextStep?.isScoreCheckpoint == true;

    if (step.isScoreCheckpoint) {
      return _CompetitionScoreWaitingScreen(
        competitionId: competitionId,
        eventName: eventName,
        firearmCode: firearmCode,
        step: step,
        primaryColor: primaryColor,
        isDark: isDark,
        onContinue: () {
          if (!hasNext) {
            Navigator.pop(context);
            return;
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => _CompetitionPracticeStageScreen(
                competitionId: competitionId,
                eventName: eventName,
                firearmCode: firearmCode,
                steps: steps,
                infoActions: infoActions,
                currentIndex: currentIndex + 1,
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
      appBar: _buildCompetitionAppBar(
        'Practice ${step.practice.practiceNumber}',
        primaryColor,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (step.showStageHeading && step.stage != null) ...[
                      _buildStageHeader(step.stage!.stageNumber, primaryColor),
                      const SizedBox(height: 16),
                    ],
                    _buildPracticeStageCard(rows, primaryColor, isDark),
                  ],
                ),
              ),
            ),
            _buildBottomControls(
              context: context,
              isDark: isDark,
              primaryColor: primaryColor,
              infoActions: infoActions,
              enabled: true,
              label: nextIsScoreCheckpoint
                  ? 'Score Section'
                  : hasNext
                  ? 'Continue'
                  : 'Finish',
              onPressed: () {
                if (!hasNext) {
                  Navigator.pop(context);
                  return;
                }

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => _CompetitionPracticeStageScreen(
                      competitionId: competitionId,
                      eventName: eventName,
                      firearmCode: firearmCode,
                      steps: steps,
                      infoActions: infoActions,
                      currentIndex: currentIndex + 1,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageHeader(int stageNumber, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.flag, color: primaryColor),
          const SizedBox(width: 12),
          Text(
            'Stage $stageNumber',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeStageCard(
    List<_DetailRow> rows,
    Color primaryColor,
    bool isDark,
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
      child: rows.isEmpty
          ? Text(
              'No practice or stage details are available.',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 14,
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  _buildDetailRow(rows[i], primaryColor, isDark),
                  if (i != rows.length - 1)
                    Divider(
                      height: 24,
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                    ),
                ],
              ],
            ),
    );
  }

  List<_DetailRow> _buildRows(_CompetitionStep step) {
    final rows = <_DetailRow>[];
    final practice = step.practice;
    final stage = step.stage;

    if (step.isScoreCheckpoint) return rows;

    final practiceName = _clean(practice.practiceName);
    if (practiceName != null) {
      rows.add(_DetailRow('Practice Name', practiceName, Icons.label));
    }

    final notesHeader = _clean(practice.notesHeader);
    if (notesHeader != null) {
      rows.add(_DetailRow('Practice Header', notesHeader, Icons.title));
    }

    final notes = _clean(practice.notes);
    if (notes != null) {
      rows.add(_DetailRow('Practice Notes', notes, Icons.notes));
    }

    if (stage != null) {
      final distance = _valueWithNotes(stage.distance, stage.distanceText);
      if (distance != null) {
        rows.add(_DetailRow('Distance', distance, Icons.straighten));
      }

      final rounds = _valueWithNotes(stage.rounds, stage.roundsText);
      if (rounds != null) {
        rows.add(_DetailRow('Rounds', rounds, Icons.adjust));
      }

      final time = _valueWithNotes(stage.time, stage.timeText);
      if (time != null) {
        rows.add(_DetailRow('Time', time, Icons.timer));
      }

      final stageNotesHeader = _clean(stage.notesHeader);
      if (stageNotesHeader != null) {
        rows.add(_DetailRow('Stage Header', stageNotesHeader, Icons.flag));
      }

      final stageNotes = _clean(stage.notes);
      if (stageNotes != null) {
        rows.add(_DetailRow('Stage Notes', stageNotes, Icons.notes));
      }
    }

    return rows;
  }
}

class _CompetitionScoreWaitingScreen extends StatelessWidget {
  final String competitionId;
  final String eventName;
  final String firearmCode;
  final _CompetitionStep step;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onContinue;

  const _CompetitionScoreWaitingScreen({
    required this.competitionId,
    required this.eventName,
    required this.firearmCode,
    required this.step,
    required this.primaryColor,
    required this.isDark,
    required this.onContinue,
  });

  void _activateCheckpoint() {
    final targetIndex = step.targetIndex;
    if (targetIndex == null) return;

    FirebaseFirestore.instance
        .collection('competitions')
        .doc(competitionId)
        .update({
          'activeTargetIndex': targetIndex,
          'activeCheckpointLabel': step.checkpointLabel,
          'activeCheckpointStartedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> _clearCheckpoint() async {
    await FirebaseFirestore.instance
        .collection('competitions')
        .doc(competitionId)
        .update({
          'activeTargetIndex': FieldValue.delete(),
          'activeCheckpointLabel': FieldValue.delete(),
          'activeCheckpointStartedAt': FieldValue.delete(),
        });
  }

  @override
  Widget build(BuildContext context) {
    _activateCheckpoint();

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
      appBar: _buildCompetitionAppBar('Waiting for Scores', primaryColor),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('competitions')
              .doc(competitionId)
              .snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data() as Map<String, dynamic>?;
            final participants =
                (data?['participants'] as List<dynamic>?)
                    ?.cast<Map<String, dynamic>>() ??
                [];
            final manualEntries =
                (data?['manualEntries'] as List<dynamic>?)
                    ?.cast<Map<String, dynamic>>() ??
                [];
            final allEntries = [...participants, ...manualEntries];
            final submitted = allEntries
                .where((entry) => _hasSubmittedCheckpoint(entry))
                .length;
            final total = allEntries.length;
            final allSubmitted = total > 0 && submitted == total;

            return Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              allSubmitted
                                  ? Icons.check_circle
                                  : Icons.hourglass_top,
                              color: allSubmitted ? Colors.green : primaryColor,
                              size: 56,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              allSubmitted
                                  ? 'Scores Received'
                                  : 'Waiting for Scores',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              step.checkpointLabel,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: total == 0 ? 0 : submitted / total,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                              backgroundColor: isDark
                                  ? Colors.grey[700]
                                  : Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                allSubmitted ? Colors.green : primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$submitted of $total entries submitted this score',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            _buildManualScoreButtons(context, manualEntries),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _buildBottomControls(
                  context: context,
                  isDark: isDark,
                  primaryColor: primaryColor,
                  infoActions: const [],
                  enabled: allSubmitted,
                  label: allSubmitted ? step.continueLabel : 'Waiting...',
                  onPressed: () async {
                    await _clearCheckpoint();
                    onContinue();
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildManualScoreButtons(
    BuildContext context,
    List<Map<String, dynamic>> manualEntries,
  ) {
    final targetIndex = step.targetIndex;
    if (targetIndex == null || manualEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Manual entries',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        for (final entry in manualEntries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton.icon(
              onPressed: _hasSubmittedCheckpoint(entry)
                  ? null
                  : () => showDialog(
                      context: context,
                      builder: (context) => EnterScoreDialog(
                        competitionId: competitionId,
                        shooterName: entry['name'] as String? ?? 'Manual Entry',
                        currentScore: null,
                        currentXCount: null,
                        eventName: eventName,
                        firearmCode: firearmCode,
                        targetIndex: targetIndex,
                      ),
                    ),
              icon: Icon(
                _hasSubmittedCheckpoint(entry)
                    ? Icons.check_circle
                    : Icons.edit,
              ),
              label: Text(
                _hasSubmittedCheckpoint(entry)
                    ? '${entry['name']} submitted'
                    : 'Enter ${entry['name']} score',
              ),
            ),
          ),
      ],
    );
  }

  bool _hasSubmittedCheckpoint(Map<String, dynamic> participant) {
    final targetScores = participant['targetScores'];
    if (targetScores is! List) return false;
    final targetIndex = step.targetIndex;
    if (targetIndex == null ||
        targetIndex < 0 ||
        targetIndex >= targetScores.length) {
      return false;
    }
    return targetScores[targetIndex] != null;
  }
}

PreferredSizeWidget _buildCompetitionAppBar(String title, Color primaryColor) {
  return AppBar(
    elevation: 0,
    title: Text(
      title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
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
  );
}

Widget _buildBottomControls({
  required BuildContext context,
  required bool isDark,
  required Color primaryColor,
  required List<_InfoAction> infoActions,
  required bool enabled,
  required String label,
  required VoidCallback onPressed,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? Colors.grey[850] : Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, -4),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (infoActions.isNotEmpty) ...[
          _buildInfoIconRow(context, infoActions, primaryColor, isDark),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: enabled ? onPressed : null,
            icon: const Icon(Icons.arrow_forward),
            label: Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildInfoIconRow(
  BuildContext context,
  List<_InfoAction> actions,
  Color primaryColor,
  bool isDark,
) {
  return SizedBox(
    height: 48,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: actions.length,
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final action = actions[index];
        return Tooltip(
          message: action.title,
          child: InkWell(
            onTap: () => _showInfoDialog(context, action, primaryColor, isDark),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 48,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
              ),
              child: Icon(action.icon, color: primaryColor, size: 22),
            ),
          ),
        );
      },
    ),
  );
}

void _showInfoDialog(
  BuildContext context,
  _InfoAction action,
  Color primaryColor,
  bool isDark,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(action.icon, color: primaryColor),
          const SizedBox(width: 8),
          Expanded(child: Text(action.title)),
        ],
      ),
      content: SingleChildScrollView(
        child: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 15,
              height: 1.35,
              color: isDark ? Colors.white : Colors.black87,
            ),
            children: _processRichText(action.content, isDark: isDark),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

Widget _buildDetailRow(_DetailRow row, Color primaryColor, bool isDark) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(row.icon, color: primaryColor, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              row.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 16,
                  height: 1.35,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                children: _processRichText(row.value, isDark: isDark),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

List<_InfoAction> _buildInfoActions(EventContent content) {
  final actions = <_InfoAction>[];

  _addInfoAction(
    actions,
    title: 'Loading',
    icon: Icons.download,
    content: _titleText(content.loading?.title, content.loading?.text),
  );
  _addInfoAction(
    actions,
    title: 'Reloading',
    icon: Icons.refresh,
    content: _titleText(content.reloading?.title, content.reloading?.text),
  );
  _addInfoAction(
    actions,
    title: 'Magazine',
    icon: Icons.view_agenda,
    content: _joinNonEmpty(
      content.magazine?.map((item) => _titleText(item.title, item.text)) ?? [],
    ),
  );
  _addInfoAction(
    actions,
    title: 'Equipment',
    icon: Icons.build,
    content: _titleText(content.equipment?.title, content.equipment?.text),
  );
  _addInfoAction(
    actions,
    title: 'Changing Position',
    icon: Icons.swap_horiz,
    content: _titleText(
      content.changingPosition?.title,
      content.changingPosition?.text,
    ),
  );
  _addInfoAction(
    actions,
    title: 'Range Equipment',
    icon: Icons.construction,
    content: _titleText(
      content.rangeEquipment?.title,
      content.rangeEquipment?.text,
    ),
  );
  _addInfoAction(
    actions,
    title: 'Scoring',
    icon: Icons.scoreboard,
    content: _titleText(content.scoring?.title, content.scoring?.text),
  );
  _addInfoAction(
    actions,
    title: 'Ties',
    icon: Icons.balance,
    content: _joinNonEmpty(content.ties?.map(_tieText) ?? []),
  );
  _addInfoAction(
    actions,
    title: 'Procedural Penalties',
    icon: Icons.warning_amber,
    content: _joinNonEmpty(
      content.proceduralPenalties?.map(_proceduralPenaltyText) ?? [],
    ),
  );
  _addInfoAction(
    actions,
    title: 'Classifications',
    icon: Icons.emoji_events,
    content: _joinNonEmpty(
      content.classifications?.map(_classificationText) ?? [],
    ),
  );
  _addInfoAction(
    actions,
    title: 'Notes',
    icon: Icons.notes,
    content: _joinNonEmpty([
      _joinNonEmpty(content.notes?.map((note) => note.text) ?? []),
      _titleText(content.generalNotes?.title, content.generalNotes?.text),
    ]),
  );

  return actions;
}

void _addInfoAction(
  List<_InfoAction> actions, {
  required String title,
  required IconData icon,
  required String? content,
}) {
  final cleaned = _clean(content);
  if (cleaned == null) return;
  actions.add(_InfoAction(title: title, icon: icon, content: cleaned));
}

String? _tieText(dynamic tie) {
  final idx = _titleText(tie.idx, tie.idxText);
  final body = _titleText(tie.title, tie.text);
  return _joinNonEmpty([idx, body]);
}

String? _proceduralPenaltyText(dynamic penalty) {
  final idx = _titleText(penalty.idx, penalty.idxText);
  final body = _titleText(penalty.title, penalty.text);
  return _joinNonEmpty([idx, body]);
}

String? _classificationText(dynamic classification) {
  final className = _clean(classification.className);
  if (className == null) return null;

  final parts = <String>[className];
  if (classification.min != null) parts.add('Min ${classification.min}');
  if (classification.max != null) parts.add('Max ${classification.max}');
  return parts.join(', ');
}

List<_CompetitionStep> _buildCompetitionSteps(
  List<Practice> practices,
  Event event,
  bool fullCompetitionScoring,
) {
  final sortedPractices = [...practices]
    ..sort((a, b) => a.practiceNumber.compareTo(b.practiceNumber));
  final steps = <_CompetitionStep>[];
  var targetIndex = 0;

  for (final practice in sortedPractices) {
    final stages = [...practice.stages]
      ..sort((a, b) => a.stageNumber.compareTo(b.stageNumber));

    if (stages.isEmpty) {
      steps.add(_CompetitionStep(practice: practice));
      if (_shouldScoreAfterPractice(event, practice, fullCompetitionScoring)) {
        steps.add(_CompetitionStep.scoreCheckpoint(practice, targetIndex++));
      }
      continue;
    }

    for (final stage in stages) {
      steps.add(
        _CompetitionStep(
          practice: practice,
          stage: stage,
          showStageHeading: stages.length > 1,
        ),
      );

      if (_shouldScoreAfterStage(
        event,
        practice,
        stage,
        fullCompetitionScoring,
      )) {
        steps.add(
          _CompetitionStep.scoreCheckpoint(
            practice,
            targetIndex++,
            stage: stage,
          ),
        );
      }
    }

    if (_shouldScoreAfterPractice(event, practice, fullCompetitionScoring)) {
      steps.add(_CompetitionStep.scoreCheckpoint(practice, targetIndex++));
    }
  }

  for (var i = 0; i < steps.length; i++) {
    final step = steps[i];
    if (!step.isScoreCheckpoint) continue;
    final hasLaterNonCheckpoint = steps
        .skip(i + 1)
        .any((nextStep) => !nextStep.isScoreCheckpoint);
    steps[i] = step.copyWith(
      continueLabel: hasLaterNonCheckpoint
          ? 'Continue with Event'
          : 'Finish Event',
    );
  }

  return steps;
}

bool _shouldScoreAfterPractice(
  Event event,
  Practice practice,
  bool fullCompetitionScoring,
) {
  if (!fullCompetitionScoring) return false;
  final trigger = event.scoreChangeTrigger;
  if (trigger.mode == 1) return true;
  if (trigger.mode == 2) {
    return trigger.checkpoints.any(
      (checkpoint) =>
          checkpoint.practiceNumber == practice.practiceNumber &&
          checkpoint.stageNumber == null,
    );
  }
  return false;
}

bool _shouldScoreAfterStage(
  Event event,
  Practice practice,
  Stage stage,
  bool fullCompetitionScoring,
) {
  if (!fullCompetitionScoring) return false;
  final trigger = event.scoreChangeTrigger;
  if (trigger.mode == 2) {
    return trigger.checkpoints.any(
      (checkpoint) =>
          checkpoint.practiceNumber == practice.practiceNumber &&
          checkpoint.stageNumber == stage.stageNumber,
    );
  }
  return false;
}

void _addLabelledText(List<String> parts, String label, String? value) {
  final cleaned = _clean(value);
  if (cleaned == null) return;
  parts.add('$label: $cleaned');
}

void _addValueWithNotes(
  List<String> parts,
  String label,
  int? value,
  String? notes,
) {
  final text = _valueWithNotes(value, notes);
  if (text == null) return;
  parts.add('$label $text');
}

String? _valueWithNotes(num? value, String? notes) {
  if (value == null) return null;

  final isWhole = value == value.roundToDouble();
  final valueText = isWhole ? value.toInt().toString() : value.toString();
  final cleanedNotes = _clean(notes);

  if (cleanedNotes == null) return valueText;
  return '$valueText $cleanedNotes';
}

String? _titleText(String? title, String? text) {
  final cleanedTitle = _clean(title);
  final cleanedText = _clean(text);

  if (cleanedTitle == null && cleanedText == null) return null;
  if (cleanedTitle == null) return cleanedText;
  if (cleanedText == null) return cleanedTitle;
  return '$cleanedTitle: $cleanedText';
}

String? _joinNonEmpty(Iterable<String?> values) {
  final cleaned = values
      .map(_clean)
      .whereType<String>()
      .where((value) => value.isNotEmpty)
      .toList();

  if (cleaned.isEmpty) return null;
  return cleaned.join('\n');
}

String? _firstNonEmpty(Iterable<String?> values) {
  for (final value in values) {
    final cleaned = _clean(value);
    if (cleaned != null) return cleaned;
  }
  return null;
}

String? _clean(String? value) {
  final cleaned = value?.trim();
  if (cleaned == null || cleaned.isEmpty) return null;
  return cleaned;
}

List<InlineSpan> _processRichText(
  String? text, {
  required bool isDark,
  bool boldBase = false,
}) {
  if (text == null || text.isEmpty) return [];

  final spans = <InlineSpan>[];
  final lineParts = text.split('<>');

  for (var lineIndex = 0; lineIndex < lineParts.length; lineIndex++) {
    final line = lineParts[lineIndex];

    if (line.isNotEmpty) {
      spans.addAll(
        _processBoldMarkers(line, isDark: isDark, boldBase: boldBase),
      );
    }

    if (lineIndex < lineParts.length - 1) {
      spans.add(const TextSpan(text: '\n'));
    }
  }

  return spans;
}

List<InlineSpan> _processBoldMarkers(
  String text, {
  required bool isDark,
  bool boldBase = false,
}) {
  final spans = <InlineSpan>[];
  final boldPattern = RegExp(r'\{([^}]*)\}');

  int lastEnd = 0;
  for (final match in boldPattern.allMatches(text)) {
    if (match.start > lastEnd) {
      final normalText = text.substring(lastEnd, match.start);
      spans.add(
        TextSpan(
          text: normalText,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: boldBase ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
    }

    final boldText = match.group(1) ?? '';
    if (boldText.isNotEmpty) {
      spans.add(
        TextSpan(
          text: boldText,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      );
    }

    lastEnd = match.end;
  }

  if (lastEnd < text.length) {
    final remainingText = text.substring(lastEnd);
    spans.add(
      TextSpan(
        text: remainingText,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: boldBase ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  if (spans.isEmpty && text.isNotEmpty) {
    spans.add(
      TextSpan(
        text: text,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: boldBase ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  return spans;
}

class _CompetitionStep {
  final Practice practice;
  final Stage? stage;
  final bool showStageHeading;
  final bool isScoreCheckpoint;
  final int? targetIndex;
  final String continueLabel;

  const _CompetitionStep({
    required this.practice,
    this.stage,
    this.showStageHeading = false,
  }) : isScoreCheckpoint = false,
       targetIndex = null,
       continueLabel = 'Continue';

  const _CompetitionStep.scoreCheckpoint(
    this.practice,
    int this.targetIndex, {
    this.stage,
    this.continueLabel = 'Continue with Event',
  }) : showStageHeading = false,
       isScoreCheckpoint = true;

  _CompetitionStep copyWith({String? continueLabel}) {
    if (isScoreCheckpoint) {
      return _CompetitionStep.scoreCheckpoint(
        practice,
        targetIndex ?? 0,
        stage: stage,
        continueLabel: continueLabel ?? this.continueLabel,
      );
    }

    return _CompetitionStep(
      practice: practice,
      stage: stage,
      showStageHeading: showStageHeading,
    );
  }

  String get checkpointLabel {
    final targetNumber = targetIndex == null
        ? ''
        : 'Target ${targetIndex! + 1} - ';
    if (stage != null) {
      return '${targetNumber}Practice ${practice.practiceNumber}, Stage ${stage!.stageNumber}';
    }
    return '${targetNumber}Practice ${practice.practiceNumber}';
  }
}

class _InfoAction {
  final String title;
  final IconData icon;
  final String content;

  const _InfoAction({
    required this.title,
    required this.icon,
    required this.content,
  });
}

class _DetailRow {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow(this.label, this.value, this.icon);
}
