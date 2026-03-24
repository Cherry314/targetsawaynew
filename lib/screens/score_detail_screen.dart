import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../data/dropdown_values.dart';
import '../main.dart';
import '../models/hive/event.dart';
import '../models/hive/firearm.dart';
import '../models/score_entry.dart';
import '../utils/date_utils.dart';

class _TargetViewData {
  final Map<int, int> breakdown;
  final String? imagePath;

  const _TargetViewData({
    required this.breakdown,
    this.imagePath,
  });
}

class ScoreDetailScreen extends StatefulWidget {
  final ScoreEntry entry;

  const ScoreDetailScreen({
    super.key,
    required this.entry,
  });

  @override
  State<ScoreDetailScreen> createState() => _ScoreDetailScreenState();
}

class _ScoreDetailScreenState extends State<ScoreDetailScreen> {
  int _currentTargetIndex = 0;

  ScoreEntry get entry => widget.entry;

  int? _getMaxScoreForEntry() {
    try {
      if (!Hive.isBoxOpen('events')) return null;

      final eventBox = Hive.box<Event>('events');
      Event? matchedEvent;
      for (final event in eventBox.values) {
        if (event.name == entry.practice) {
          matchedEvent = event;
          break;
        }
      }

      if (matchedEvent == null) return null;

      final firearmId = DropdownValues.getFirearmIdByCode(entry.firearmId);
      if (firearmId == null) return null;

      final firearm = Firearm(
        id: firearmId,
        code: entry.firearmId,
        gunType: '',
      );

      final content = matchedEvent.getContentForFirearm(firearm);
      return content.courseOfFire.maxScore;
    } catch (_) {
      return null;
    }
  }

  int? _getTotalRoundsForEntry() {
    try {
      if (!Hive.isBoxOpen('events')) return null;

      final eventBox = Hive.box<Event>('events');
      Event? matchedEvent;
      for (final event in eventBox.values) {
        if (event.name == entry.practice) {
          matchedEvent = event;
          break;
        }
      }

      if (matchedEvent == null) return null;

      final firearmId = DropdownValues.getFirearmIdByCode(entry.firearmId);
      if (firearmId == null) return null;

      final firearm = Firearm(
        id: firearmId,
        code: entry.firearmId,
        gunType: '',
      );

      final content = matchedEvent.getContentForFirearm(firearm);
      return content.courseOfFire.totalRounds;
    } catch (_) {
      return null;
    }
  }

  int _targetsScoredCount() {
    final listCounts = [
      entry.scoreBasics?.length ?? 0,
      entry.targetFilePaths?.length ?? 0,
      entry.score10s?.length ?? 0,
      entry.score9s?.length ?? 0,
      entry.score8s?.length ?? 0,
      entry.score7s?.length ?? 0,
      entry.score6s?.length ?? 0,
      entry.score5s?.length ?? 0,
      entry.score4s?.length ?? 0,
      entry.score3s?.length ?? 0,
      entry.score2s?.length ?? 0,
      entry.score1s?.length ?? 0,
      entry.score0s?.length ?? 0,
    ];

    int maxCount = listCounts.fold<int>(0, (max, count) => count > max ? count : max);

    if (maxCount == 0) {
      final hasLegacy = (entry.score10 ?? 0) > 0 ||
          (entry.score9 ?? 0) > 0 ||
          (entry.score8 ?? 0) > 0 ||
          (entry.score7 ?? 0) > 0 ||
          (entry.score6 ?? 0) > 0 ||
          (entry.score5 ?? 0) > 0 ||
          (entry.score4 ?? 0) > 0 ||
          (entry.score3 ?? 0) > 0 ||
          (entry.score2 ?? 0) > 0 ||
          (entry.score1 ?? 0) > 0 ||
          (entry.score0 ?? 0) > 0 ||
          entry.targetFilePath != null;
      if (hasLegacy) maxCount = 1;
    }

    return maxCount;
  }

  List<_TargetViewData> _buildTargetViews() {
    final count = _targetsScoredCount();
    if (count == 0) return const [];

    final result = <_TargetViewData>[];

    for (int i = 0; i < count; i++) {
      final breakdown = <int, int>{
        10: entry.score10s != null && i < entry.score10s!.length ? (entry.score10s![i]) : (i == 0 ? (entry.score10 ?? 0) : 0),
        9: entry.score9s != null && i < entry.score9s!.length ? (entry.score9s![i]) : (i == 0 ? (entry.score9 ?? 0) : 0),
        8: entry.score8s != null && i < entry.score8s!.length ? (entry.score8s![i]) : (i == 0 ? (entry.score8 ?? 0) : 0),
        7: entry.score7s != null && i < entry.score7s!.length ? (entry.score7s![i]) : (i == 0 ? (entry.score7 ?? 0) : 0),
        6: entry.score6s != null && i < entry.score6s!.length ? (entry.score6s![i]) : (i == 0 ? (entry.score6 ?? 0) : 0),
        5: entry.score5s != null && i < entry.score5s!.length ? (entry.score5s![i]) : (i == 0 ? (entry.score5 ?? 0) : 0),
        4: entry.score4s != null && i < entry.score4s!.length ? (entry.score4s![i]) : (i == 0 ? (entry.score4 ?? 0) : 0),
        3: entry.score3s != null && i < entry.score3s!.length ? (entry.score3s![i]) : (i == 0 ? (entry.score3 ?? 0) : 0),
        2: entry.score2s != null && i < entry.score2s!.length ? (entry.score2s![i]) : (i == 0 ? (entry.score2 ?? 0) : 0),
        1: entry.score1s != null && i < entry.score1s!.length ? (entry.score1s![i]) : (i == 0 ? (entry.score1 ?? 0) : 0),
        0: entry.score0s != null && i < entry.score0s!.length ? (entry.score0s![i]) : (i == 0 ? (entry.score0 ?? 0) : 0),
      };

      String? imagePath;
      if (entry.targetFilePaths != null && i < entry.targetFilePaths!.length) {
        final path = entry.targetFilePaths![i];
        imagePath = path.isEmpty ? null : path;
      } else if (i == 0) {
        imagePath = entry.targetFilePath;
      }

      result.add(_TargetViewData(
        breakdown: breakdown,
        imagePath: imagePath,
      ));
    }

    return result;
  }

  int? _getRoundsUsed() {
    final targetViews = _buildTargetViews();
    if (targetViews.isNotEmpty) {
      int total = 0;
      for (final view in targetViews) {
        total += view.breakdown.values.fold<int>(0, (sum, v) => sum + v);
      }
      return total > 0 ? total : null;
    }
    return null;
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color primaryColor, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: primaryColor.withValues(alpha: 0.7)),
        const SizedBox(width: 12),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false, bool isDark = false, Color? primaryColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: isHeader ? 14 : 13,
          fontWeight: isHeader ? FontWeight.bold : (primaryColor != null ? FontWeight.w600 : FontWeight.normal),
          color: primaryColor ?? (isDark ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget _buildScoreBreakdownTable(
    Map<int, int> breakdown,
    Color primaryColor,
    bool isDark, {
    String scoreHeader = 'Score',
    String percentageHeader = 'Percentage',
  }) {
    final scoreData = <Map<String, int>>[];
    for (int score = 10; score >= 0; score--) {
      final hits = breakdown[score] ?? 0;
      if (hits > 0) {
        scoreData.add({'score': score, 'hits': hits});
      }
    }

    if (scoreData.isEmpty) {
      return const Text('No score breakdown available');
    }

    final totalHits = scoreData.fold<int>(0, (sum, item) => sum + (item['hits'] ?? 0));

    return Table(
      border: TableBorder.all(
        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        borderRadius: BorderRadius.circular(8),
      ),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1.5),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
          ),
          children: [
            _buildTableCell(scoreHeader, isHeader: true, isDark: isDark),
            _buildTableCell('Hits', isHeader: true, isDark: isDark),
            _buildTableCell(percentageHeader, isHeader: true, isDark: isDark),
          ],
        ),
        ...scoreData.map((data) {
          final score = data['score'] ?? 0;
          final hits = data['hits'] ?? 0;
          final percentage = ((hits / totalHits) * 100).toStringAsFixed(1);
          return TableRow(
            children: [
              _buildTableCell(score.toString(), isDark: isDark, primaryColor: primaryColor),
              _buildTableCell(hits.toString(), isDark: isDark),
              _buildTableCell('$percentage%', isDark: isDark),
            ],
          );
        }),
      ],
    );
  }

  void _showCombinedDialog(BuildContext context, List<_TargetViewData> targets, Color primaryColor, bool isDark) {
    final combined = <int, int>{for (int s = 0; s <= 10; s++) s: 0};
    for (final target in targets) {
      for (int s = 0; s <= 10; s++) {
        combined[s] = (combined[s] ?? 0) + (target.breakdown[s] ?? 0);
      }
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Combined Breakdown'),
        content: SingleChildScrollView(
          child: _buildScoreBreakdownTable(
            combined,
            primaryColor,
            isDark,
            scoreHeader: 'Text',
            percentageHeader: '%',
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final maxScore = _getMaxScoreForEntry();
    final totalRounds = _getTotalRoundsForEntry();
    final roundsUsed = _getRoundsUsed();
    final targetViews = _buildTargetViews();

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: Text(
          formatUKDate(entry.date),
          style: const TextStyle(
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
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.all(16),
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.emoji_events, color: primaryColor, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Score',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    entry.score.toString(),
                                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: primaryColor),
                                  ),
                                  if (maxScore != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8, bottom: 6),
                                      child: Text(
                                        '/ $maxScore',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white60 : Colors.black54,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (entry.x != null && entry.x! > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              children: [
                                Text('X', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor)),
                                Text(
                                  entry.x.toString(),
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.track_changes, 'Practice', entry.practice, primaryColor, isDark),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.straighten, 'Calibre', entry.caliber, primaryColor, isDark),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.tag, 'Firearm ID', entry.firearmId, primaryColor, isDark),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.layers, 'Targets', targetViews.length.toString(), primaryColor, isDark),
                    if (entry.firearm != null && entry.firearm!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(FontAwesomeIcons.gun, 'Firearm', entry.firearm!, primaryColor, isDark),
                    ],
                    if (roundsUsed != null || totalRounds != null) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.adjust,
                        'Rounds Used',
                        roundsUsed != null
                            ? (totalRounds != null ? '$roundsUsed / $totalRounds' : roundsUsed.toString())
                            : (totalRounds?.toString() ?? 'N/A'),
                        primaryColor,
                        isDark,
                      ),
                    ],
                  ],
                ),
              ),

              if (targetViews.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                      Row(
                        children: [
                          Icon(Icons.table_chart, color: primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Target ${_currentTargetIndex + 1}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _showCombinedDialog(context, targetViews, primaryColor, isDark),
                            child: const Text(
                              'Show\ncombined',
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 460,
                        child: PageView.builder(
                          itemCount: targetViews.length,
                          onPageChanged: (index) => setState(() => _currentTargetIndex = index),
                          itemBuilder: (context, index) {
                            final target = targetViews[index];
                            final hasImage = target.imagePath != null && File(target.imagePath!).existsSync();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildScoreBreakdownTable(target.breakdown, primaryColor, isDark),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: hasImage
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: InteractiveViewer(
                                            panEnabled: true,
                                            minScale: 1.0,
                                            maxScale: 5.0,
                                            child: Image.file(
                                              File(target.imagePath!),
                                              width: double.infinity,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            color: isDark ? Colors.grey[800] : Colors.grey[100],
                                          ),
                                          child: const Center(
                                            child: Text('No target image available'),
                                          ),
                                        ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      if (targetViews.length > 1) ...[
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            'Target ${_currentTargetIndex + 1} of ${targetViews.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
