// lib/screens/score_detail_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../models/score_entry.dart';
import '../models/hive/event.dart';
import '../models/hive/firearm.dart';
import '../data/dropdown_values.dart';
import '../utils/date_utils.dart';
import '../main.dart';

/// Reusable screen that displays detailed information about a score entry
/// including score breakdown, target image, and all metadata
class ScoreDetailScreen extends StatelessWidget {
  final ScoreEntry entry;

  const ScoreDetailScreen({
    super.key,
    required this.entry,
  });

  /// Get max score for an entry based on practice/event and firearm
  int? _getMaxScoreForEntry(ScoreEntry entry) {
    try {
      if (!Hive.isBoxOpen('events')) return null;
      
      final eventBox = Hive.box<Event>('events');
      
      // Find the event by matching the practice name
      Event? matchedEvent;
      for (final event in eventBox.values) {
        if (event.name == entry.practice) {
          matchedEvent = event;
          break;
        }
      }
      
      if (matchedEvent == null) return null;

      // Get the firearm ID from the code
      final firearmId = DropdownValues.getFirearmIdByCode(entry.firearmId);
      if (firearmId == null) return null;

      // Create a Firearm object
      final firearm = Firearm(
        id: firearmId,
        code: entry.firearmId,
        gunType: '',
      );

      // Get the content for this firearm
      final content = matchedEvent.getContentForFirearm(firearm);
      return content.courseOfFire.maxScore;
    } catch (e) {
      return null;
    }
  }

  /// Get total rounds for an entry
  int? _getTotalRoundsForEntry(ScoreEntry entry) {
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
    } catch (e) {
      return null;
    }
  }

  bool _hasScoreBreakdown(ScoreEntry entry) {
    return entry.score10 != null || entry.score9 != null || entry.score8 != null ||
        entry.score7 != null || entry.score6 != null || entry.score5 != null ||
        entry.score4 != null || entry.score3 != null || entry.score2 != null ||
        entry.score1 != null || entry.score0 != null;
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color primaryColor, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: primaryColor.withValues(alpha: 0.7)),
        const SizedBox(width: 12),
        SizedBox(
          width: 100,
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

  Widget _buildScoreBreakdownTable(ScoreEntry entry, Color primaryColor, bool isDark) {
    // Build list of scores that have hits
    final List<Map<String, dynamic>> scoreData = [];
    
    // Add scores in descending order (10 to 0)
    if (entry.score10 != null && entry.score10! > 0) {
      scoreData.add({'score': 10, 'hits': entry.score10!});
    }
    if (entry.score9 != null && entry.score9! > 0) {
      scoreData.add({'score': 9, 'hits': entry.score9!});
    }
    if (entry.score8 != null && entry.score8! > 0) {
      scoreData.add({'score': 8, 'hits': entry.score8!});
    }
    if (entry.score7 != null && entry.score7! > 0) {
      scoreData.add({'score': 7, 'hits': entry.score7!});
    }
    if (entry.score6 != null && entry.score6! > 0) {
      scoreData.add({'score': 6, 'hits': entry.score6!});
    }
    if (entry.score5 != null && entry.score5! > 0) {
      scoreData.add({'score': 5, 'hits': entry.score5!});
    }
    if (entry.score4 != null && entry.score4! > 0) {
      scoreData.add({'score': 4, 'hits': entry.score4!});
    }
    if (entry.score3 != null && entry.score3! > 0) {
      scoreData.add({'score': 3, 'hits': entry.score3!});
    }
    if (entry.score2 != null && entry.score2! > 0) {
      scoreData.add({'score': 2, 'hits': entry.score2!});
    }
    if (entry.score1 != null && entry.score1! > 0) {
      scoreData.add({'score': 1, 'hits': entry.score1!});
    }
    if (entry.score0 != null && entry.score0! > 0) {
      scoreData.add({'score': 0, 'hits': entry.score0!});
    }

    if (scoreData.isEmpty) {
      return const Text('No score breakdown available');
    }

    // Calculate total hits for percentage
    final totalHits = scoreData.fold<int>(0, (sum, item) => sum + (item['hits'] as int));

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
        // Header row
        TableRow(
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
          ),
          children: [
            _buildTableCell('Score', isHeader: true, isDark: isDark),
            _buildTableCell('Hits', isHeader: true, isDark: isDark),
            _buildTableCell('Percentage', isHeader: true, isDark: isDark),
          ],
        ),
        // Data rows
        ...scoreData.map((data) {
          final score = data['score'] as int;
          final hits = data['hits'] as int;
          final percentage = ((hits / totalHits) * 100).toStringAsFixed(1);
          
          return TableRow(
            children: [
              _buildTableCell(score.toString(), isDark: isDark, primaryColor: primaryColor),
              _buildTableCell(hits.toString(), isDark: isDark),
              _buildTableCell('$percentage%', isDark: isDark),
            ],
          );
        }).toList(),
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxScore = _getMaxScoreForEntry(entry);
    final totalRounds = _getTotalRoundsForEntry(entry);

    // Calculate total rounds from score breakdown
    int? roundsUsed;
    if (entry.score10 != null || entry.score9 != null || entry.score8 != null ||
        entry.score7 != null || entry.score6 != null || entry.score5 != null ||
        entry.score4 != null || entry.score3 != null || entry.score2 != null ||
        entry.score1 != null || entry.score0 != null) {
      roundsUsed = (entry.score10 ?? 0) + (entry.score9 ?? 0) + (entry.score8 ?? 0) +
          (entry.score7 ?? 0) + (entry.score6 ?? 0) + (entry.score5 ?? 0) +
          (entry.score4 ?? 0) + (entry.score3 ?? 0) + (entry.score2 ?? 0) +
          (entry.score1 ?? 0) + (entry.score0 ?? 0);
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: Text(formatUKDate(entry.date)),
        elevation: 0,
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
              // Score Card
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
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    entry.score.toString(),
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                  if (maxScore != null) ...[
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
                              border: Border.all(
                                color: primaryColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'X',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                Text(
                                  entry.x.toString(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
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
                    if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.note, color: primaryColor, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Notes',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.notes!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),

              // Score Breakdown Table (if available)
              if (_hasScoreBreakdown(entry))
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
                          const Text(
                            'Score Breakdown',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildScoreBreakdownTable(entry, primaryColor, isDark),
                    ],
                  ),
                ),

              // Target Image (if available)
              if (entry.targetFilePath != null && File(entry.targetFilePath!).existsSync())
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 1.0,
                      maxScale: 5.0,
                      child: Image.file(
                        File(entry.targetFilePath!),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
