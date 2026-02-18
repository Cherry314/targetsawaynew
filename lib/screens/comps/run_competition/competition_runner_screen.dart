// lib/screens/comps/run_competition/competition_runner_screen.dart
// Main screen for running a competition - shows QR code and manages participants

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../../main.dart';
import '../../../services/sound_service.dart';
import 'manual_entry_dialog.dart';
import 'enter_score_dialog.dart';
import 'competition_results_screen.dart';

// Timeout duration for abandoned competitions (3 hours)
const Duration _competitionTimeout = Duration(hours: 3);
// Heartbeat interval to extend timeout (every 5 minutes)
const Duration _heartbeatInterval = Duration(minutes: 5);

class CompetitionRunnerScreen extends StatefulWidget {
  final String eventName;

  const CompetitionRunnerScreen({
    super.key,
    required this.eventName,
  });

  @override
  State<CompetitionRunnerScreen> createState() =>
      _CompetitionRunnerScreenState();
}

class _CompetitionRunnerScreenState extends State<CompetitionRunnerScreen> {
  String? competitionId;
  bool isLoading = true;
  String? qrData;
  Timer? _heartbeatTimer;
  bool entriesClosed = false;
  bool competitionEnded = false;

  @override
  void initState() {
    super.initState();
    _cleanupAbandonedCompetitions();
    _initializeCompetition();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    // Delete competition immediately when app closes
    _deleteCompetition();
    super.dispose();
  }

  /// Delete old abandoned competitions to prevent Firebase clutter
  Future<void> _cleanupAbandonedCompetitions() async {
    try {
      final cutoffTime = DateTime.now().subtract(_competitionTimeout);
      final snapshot = await FirebaseFirestore.instance
          .collection('competitions')
          .where('expiresAt', isLessThan: Timestamp.fromDate(cutoffTime))
          .where('status', whereIn: ['active', 'abandoned'])
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      // Silently handle cleanup errors - don't block user
    }
  }

  /// Delete competition immediately when app closes
  Future<void> _deleteCompetition() async {
    if (competitionId == null) {
      debugPrint('Cannot delete competition: competitionId is null');
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('competitions')
          .doc(competitionId)
          .delete();
      debugPrint('Competition $competitionId deleted successfully');
    } catch (e) {
      debugPrint('Error deleting competition: $e');
      // Competition will be cleaned up by timeout anyway
    }
  }

  /// Extend competition expiration (heartbeat)
  Future<void> _extendTimeout() async {
    if (competitionId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('competitions')
          .doc(competitionId)
          .update({
        'expiresAt': DateTime.now().add(_competitionTimeout),
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // If update fails, competition will expire and be cleaned up
    }
  }

  /// Start heartbeat timer to keep competition alive
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _extendTimeout();
    });
  }

  Future<void> _initializeCompetition() async {
    // Generate unique competition ID
    const uuid = Uuid();
    competitionId = uuid.v4();

    // Get current user
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: User not authenticated. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Create competition in Firebase
    try {
      final now = DateTime.now();
      await FirebaseFirestore.instance
          .collection('competitions')
          .doc(competitionId)
          .set({
        'eventName': widget.eventName,
        'createdBy': currentUser.uid,
        'createdAt': now,
        'status': 'active',
        'participants': [],
        'manualEntries': [],
        'entriesClosed': false,
        'expiresAt': now.add(_competitionTimeout),
        'lastActiveAt': now,
      });

      // QR code data contains competition ID
      qrData = 'targetsaway://competition/$competitionId';

      // Start heartbeat to keep competition alive
      _startHeartbeat();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error creating competition. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _closeEntries() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.orange),
            SizedBox(width: 8),
            Text('Close Entries?'),
          ],
        ),
        content: const Text(
          'This will close the competition to new entries. The QR code will be removed and no new shooters will be able to join.\n\nAre you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              SoundService().playCompStart();
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Close Entries'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (competitionId == null) return;
      try {
        await FirebaseFirestore.instance
            .collection('competitions')
            .doc(competitionId)
            .update({
          'entriesClosed': true,
        });

        setState(() {
          entriesClosed = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Entries closed. No new shooters can join.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error closing entries: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<bool> _onWillPop() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Leave Competition?'),
          ],
        ),
        content: const Text(
          'If you leave, this competition will be DELETED immediately.\n\n'
          'Shooters will no longer be able to join or submit scores.\n\n'
          'Make sure all scores have been submitted before leaving.',
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
            child: const Text('Leave & Delete'),
          ),
        ],
      ),
    );

    if (shouldLeave == true) {
      // Delete competition before leaving
      await _deleteCompetition();
    }

    return shouldLeave ?? false;
  }

  /// Combine and sort all entries by score (highest first), then X count (highest first)
  List<Map<String, dynamic>> _getSortedLeaderboard(
    List<Map<String, dynamic>>? participants,
    List<Map<String, dynamic>>? manualEntries,
  ) {
    final allEntries = <Map<String, dynamic>>[];

    // Add app participants
    if (participants != null) {
      for (final p in participants) {
        allEntries.add({
          'name': p['name'] ?? 'Unknown',
          'score': p['score'] as int?,
          'xCount': p['xCount'] as int? ?? 0,
          'submitted': p['submitted'] == true,
          'isManual': false,
          'breakdown': p['breakdown'] as Map<String, dynamic>?,
        });
      }
    }

    // Add manual entries
    if (manualEntries != null) {
      for (final e in manualEntries) {
        allEntries.add({
          'name': e['name'] ?? 'Unknown',
          'score': e['score'] as int?,
          'xCount': e['xCount'] as int? ?? 0,
          'submitted': e['submitted'] == true || e['score'] != null,
          'isManual': true,
          'breakdown': e['breakdown'] as Map<String, dynamic>?,
        });
      }
    }

    // Sort by score (highest first), then by X count (highest first)
    // Entries without scores go at the bottom
    allEntries.sort((a, b) {
      final aScore = a['score'] as int?;
      final bScore = b['score'] as int?;
      final aXCount = a['xCount'] as int? ?? 0;
      final bXCount = b['xCount'] as int? ?? 0;

      // If both have scores, sort by score descending, then X count descending
      if (aScore != null && bScore != null) {
        final scoreCompare = bScore.compareTo(aScore);
        if (scoreCompare != 0) return scoreCompare;
        return bXCount.compareTo(aXCount);
      }

      // If only one has a score, that one comes first
      if (aScore != null) return -1;
      if (bScore != null) return 1;

      // Neither has a score - maintain original order (by name)
      return (a['name'] as String).compareTo(b['name'] as String);
    });

    return allEntries;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = themeProvider.primaryColor;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
        appBar: AppBar(
          elevation: 0,
          title: const Text(
            'Running Competition',
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
          actions: [
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copy Competition ID',
              onPressed: () {
                if (competitionId == null) return;
                Clipboard.setData(ClipboardData(text: competitionId!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Competition ID copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('competitions')
                    .doc(competitionId!)
                    .snapshots(),
                builder: (context, snapshot) {
                  final competitionData =
                      snapshot.data?.data() as Map<String, dynamic>?;
                  final participants = (competitionData?['participants']
                          as List<dynamic>?)
                      ?.cast<Map<String, dynamic>>();
                  final manualEntries = (competitionData?['manualEntries']
                          as List<dynamic>?)
                      ?.cast<Map<String, dynamic>>();
                  final isEntriesClosed =
                      competitionData?['entriesClosed'] == true;

                  // Get sorted leaderboard
                  final leaderboard = _getSortedLeaderboard(
                    participants,
                    manualEntries,
                  );

                  // Calculate stats
                  final totalParticipants =
                      (participants?.length ?? 0) + (manualEntries?.length ?? 0);
                  final submittedScores = leaderboard
                      .where((e) => e['submitted'] == true)
                      .length;

                  return SafeArea(
                    child: Column(
                      children: [
                        // Scrollable content
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Event Info Card
                                _buildEventInfoCard(primaryColor, isDark),
                                const SizedBox(height: 20),

                                // QR Code Section (only if entries not closed)
                                if (!isEntriesClosed) ...[
                                  _buildQRCodeSection(primaryColor, isDark),
                                  const SizedBox(height: 20),
                                ],

                                // Stats Card
                                _buildStatsCard(
                                  totalParticipants,
                                  submittedScores,
                                  primaryColor,
                                  isDark,
                                ),
                                const SizedBox(height: 20),

                                // Leaderboard (always show, sorted by score)
                                if (leaderboard.isNotEmpty) ...[
                                  _buildLeaderboard(leaderboard, primaryColor, isDark),
                                  const SizedBox(height: 20),
                                ],
                                // Bottom padding for scrollable area
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                        // Buttons fixed at bottom
                        if (!competitionEnded)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[850] : Colors.white,
                              border: Border(
                                top: BorderSide(
                                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: _buildBottomButtons(
                              totalParticipants,
                              submittedScores,
                              primaryColor,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildEventInfoCard(Color primaryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // const Icon(
          //   Icons.emoji_events,
          //   size: 48,
          //   color: Colors.white,
          // ),
          // const SizedBox(height: 12),
          Text(
            widget.eventName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Container(
          //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          //   decoration: BoxDecoration(
          //     color: Colors.white.withValues(alpha: 0.2),
          //     borderRadius: BorderRadius.circular(20),
          //   ),
          //   // child: Row(
          //   //   mainAxisSize: MainAxisSize.min,
          //   //   children: [
          //   //     Container(
          //   //       width: 8,
          //   //       height: 8,
          //   //       decoration: const BoxDecoration(
          //   //         color: Colors.green,
          //   //         shape: BoxShape.circle,
          //   //       ),
          //   //     ),
          //   //     const SizedBox(width: 8),
          //   //     // const Text(
          //   //     //   'Active',
          //   //     //   style: TextStyle(
          //   //     //     color: Colors.white,
          //   //     //     fontWeight: FontWeight.w600,
          //   //     //   ),
          //   //     // ),
          //   //   ],
          //   // ),
          // ),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection(Color primaryColor, bool isDark) {
    return Container(
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
        children: [
          Text(
            'Scan to Join',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          // Text(
          //   'Shooters can scan this QR code to join the competition',
          //   style: TextStyle(
          //     fontSize: 14,
          //     color: isDark ? Colors.white70 : Colors.black54,
          //   ),
          //   textAlign: TextAlign.center,
          // ),
          // const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: QrImageView(
              data: qrData ?? competitionId ?? '',
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              foregroundColor: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Competition ID:',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            competitionId != null
                ? competitionId!.substring(0, 8)
                : '...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: primaryColor,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
    int totalParticipants,
    int submittedScores,
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
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              Icons.people,
              totalParticipants.toString(),
              'Total Shooters',
              primaryColor,
              isDark,
            ),
          ),
          Container(
            height: 50,
            width: 1,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          Expanded(
            child: _buildStatItem(
              Icons.check_circle,
              submittedScores.toString(),
              'Scores Submitted',
              Colors.green,
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
    bool isDark,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboard(
    List<Map<String, dynamic>> entries,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.leaderboard, color: primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Leaderboard',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Sorted by Score',
                  style: TextStyle(
                    fontSize: 12,
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...entries.asMap().entries.map((mapEntry) {
            final index = mapEntry.key;
            final entry = mapEntry.value;
            return _buildLeaderboardRow(
              index + 1,
              entry['name'] as String,
              entry['score'] as int?,
              entry['xCount'] as int? ?? 0,
              entry['submitted'] as bool,
              entry['isManual'] as bool,
              entry['breakdown'] as Map<String, dynamic>?,
              primaryColor,
              isDark,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLeaderboardRow(
    int rank,
    String name,
    int? score,
    int xCount,
    bool submitted,
    bool isManual,
    Map<String, dynamic>? breakdown,
    Color primaryColor,
    bool isDark,
  ) {
    Color rankColor;
    IconData? rankIcon;

    if (rank == 1) {
      rankColor = Colors.amber;
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = Colors.grey.shade400;
      rankIcon = Icons.emoji_events;
    } else if (rank == 3) {
      rankColor = Colors.brown.shade300;
      rankIcon = Icons.emoji_events;
    } else {
      rankColor = isDark ? Colors.white54 : Colors.black54;
      rankIcon = null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: rank <= 3
            ? Border.all(color: rankColor.withValues(alpha: 0.5), width: 1)
            : null,
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: rankIcon != null
                  ? Icon(rankIcon, color: rankColor, size: 18)
                  : Text(
                      rank.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: rankColor,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Name and type indicator
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (isManual)
                  Text(
                    'Manual Entry',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
          // Score display or action button
          if (submitted && score != null) ...[
            if (!isManual && breakdown != null && breakdown.isNotEmpty)
              // App user with breakdown - tappable
              InkWell(
                onTap: () {
                  _showScoreBreakdownDialog(
                    context,
                    name,
                    score,
                    xCount,
                    breakdown,
                    primaryColor,
                    isDark,
                  );
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                            fontWeight: FontWeight.w600,
                            color: Colors.amber[700],
                          ),
                        ),
                      ],
                      const SizedBox(width: 4),
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: primaryColor.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ),
              )
            else
              // Manual entry or no breakdown - not tappable
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                          fontWeight: FontWeight.w600,
                          color: Colors.amber[700],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ] else if (isManual) ...[
            // Enter Score button for manual entries without scores
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => EnterScoreDialog(
                    competitionId: competitionId!,
                    shooterName: name,
                    currentScore: score,
                    currentXCount: xCount > 0 ? xCount : null,
                    eventName: widget.eventName,
                  ),
                );
              },
              icon: const Icon(Icons.edit, size: 16),
              label: const Text(
                'Enter Score',
                style: TextStyle(fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ] else ...[
            // Waiting indicator for app users
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Waiting...',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showScoreBreakdownDialog(
    BuildContext context,
    String shooterName,
    int totalScore,
    int xCount,
    Map<String, dynamic> breakdown,
    Color primaryColor,
    bool isDark,
  ) {
    // Convert string keys back to integers and sort by score value (descending)
    final scoreEntries = breakdown.entries.map((e) {
      final scoreValue = int.tryParse(e.key) ?? 0;
      final count = e.value is int ? e.value : (e.value as num).toInt();
      return MapEntry(scoreValue, count);
    }).toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.analytics, color: primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$shooterName - Score Breakdown',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total score header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Total: $totalScore',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  if (xCount > 0) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.gps_fixed, size: 18, color: Colors.amber[700]),
                    const SizedBox(width: 4),
                    Text(
                      xCount.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber[700],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Score Distribution:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            // Breakdown rows
            ...scoreEntries.map((entry) {
              final scoreValue = entry.key;
              final count = entry.value;
              final points = scoreValue * count;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    // Score zone badge
                    Container(
                      width: 36,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _getScoreZoneColor(scoreValue),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          scoreValue.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Count
                    Text(
                      '$count × $scoreValue = $points',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    // Progress bar
                    Expanded(
                      flex: 2,
                      child: LinearProgressIndicator(
                        value: count / scoreEntries.fold<int>(0, (sum, e) => sum + e.value as int),
                        backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getScoreZoneColor(scoreValue),
                        ),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
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

  Color _getScoreZoneColor(int score) {
    if (score >= 10) return Colors.green.shade700;
    if (score >= 8) return Colors.green.shade500;
    if (score >= 6) return Colors.yellow.shade700;
    if (score >= 4) return Colors.orange.shade600;
    return Colors.red.shade500;
  }

  Widget _buildManualEntryButton(Color primaryColor) {
    return ElevatedButton.icon(
      onPressed: () {
        if (competitionId == null) return;
        showDialog(
          context: context,
          builder: (context) => ManualEntryDialog(
            competitionId: competitionId!,
          ),
        );
      },
      icon: const Icon(Icons.person_add),
      label: const Text(
        'Add Shooter',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildCloseEntriesButton() {
    return ElevatedButton.icon(
      onPressed: _closeEntries,
      icon: const Icon(Icons.lock),
      label: const Text(
        'Close Entries',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade400,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Build bottom buttons based on current state
  Widget _buildBottomButtons(
    int totalParticipants,
    int submittedScores,
    Color primaryColor,
  ) {
    // All scores are in - show End Competition button
    if (totalParticipants > 0 && submittedScores == totalParticipants) {
      return SizedBox(
        width: double.infinity,
        child: _buildEndCompetitionButton(primaryColor),
      );
    }

    // Entries not closed yet - show Add Shooter and Close Entries
    if (!entriesClosed) {
      if (totalParticipants == 0) {
        return SizedBox(
          width: double.infinity,
          child: _buildManualEntryButton(primaryColor),
        );
      }
      return Row(
        children: [
          Expanded(
            child: _buildManualEntryButton(primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCloseEntriesButton(),
          ),
        ],
      );
    }

    // Entries closed, but not all scores in - show Add Shooter only
    return SizedBox(
      width: double.infinity,
      child: _buildManualEntryButton(primaryColor),
    );
  }

  /// Build End Competition button
  Widget _buildEndCompetitionButton(Color primaryColor) {
    return ElevatedButton.icon(
      onPressed: _endCompetition,
      icon: const Icon(Icons.celebration),
      label: const Text(
        'End Competition & Show Results',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// End competition, send results to all participants, and show results
  Future<void> _endCompetition() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.green),
            SizedBox(width: 8),
            Text('End Competition?'),
          ],
        ),
        content: const Text(
          'This will finalize the competition and send results to all participants.\n\n'
          'The competition will be marked as completed and results will be saved to all shooters\' history.\n\n'
          'Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              SoundService().playCompWin();
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('End & Show Results'),
          ),
        ],
      ),
    );

    if (confirmed != true || competitionId == null) return;

    try {
      // Get current competition data
      final doc = await FirebaseFirestore.instance
          .collection('competitions')
          .doc(competitionId)
          .get();

      final data = doc.data();
      if (data == null) return;

      final participants = (data['participants'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      final manualEntries = (data['manualEntries'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];

      // Get sorted leaderboard
      final leaderboard = _getSortedLeaderboard(participants, manualEntries);
      final totalShooters = leaderboard.length;

      // Update competition status and add results to each participant
      final updatedParticipants = participants.map((p) {
        final name = p['name'] as String;
        // Find position in leaderboard
        final position = leaderboard.indexWhere((e) => e['name'] == name) + 1;

        return {
          ...p,
          'position': position,
          'totalShooters': totalShooters,
          'finalScore': p['score'],
          'finalXCount': p['xCount'] ?? 0,
        };
      }).toList();

      final updatedManualEntries = manualEntries.map((e) {
        final name = e['name'] as String;
        final position = leaderboard.indexWhere((entry) => entry['name'] == name) + 1;

        return {
          ...e,
          'position': position,
          'totalShooters': totalShooters,
          'finalScore': e['score'],
          'finalXCount': e['xCount'] ?? 0,
        };
      }).toList();

      // Update competition as ended
      await FirebaseFirestore.instance
          .collection('competitions')
          .doc(competitionId)
          .update({
        'status': 'completed',
        'endedAt': FieldValue.serverTimestamp(),
        'participants': updatedParticipants,
        'manualEntries': updatedManualEntries,
        'finalResults': leaderboard.map((e) => {
          'name': e['name'],
          'score': e['score'],
          'xCount': e['xCount'],
          'position': leaderboard.indexOf(e) + 1,
        }).toList(),
      });

      setState(() {
        competitionEnded = true;
      });

      // Cancel heartbeat timer
      _heartbeatTimer?.cancel();

      if (mounted) {
        // Navigate to results screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CompetitionResultsScreen(
              eventName: widget.eventName,
              results: leaderboard,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ending competition: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
