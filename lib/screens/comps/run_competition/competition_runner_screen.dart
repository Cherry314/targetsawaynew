// lib/screens/comps/run_competition/competition_runner_screen.dart
// Main screen for running a competition - shows QR code and manages participants

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../main.dart';
import 'manual_entry_dialog.dart';

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
  late String competitionId;
  bool isLoading = true;
  String? qrData;
  Timer? _heartbeatTimer;

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
    try {
      await FirebaseFirestore.instance
          .collection('competitions')
          .doc(competitionId)
          .delete();
    } catch (e) {
      // Silently handle - competition will be cleaned up by timeout anyway
    }
  }

  /// Extend competition expiration (heartbeat)
  Future<void> _extendTimeout() async {
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

    // Create competition in Firebase
    try {
      final now = DateTime.now();
      await FirebaseFirestore.instance
          .collection('competitions')
          .doc(competitionId)
          .set({
        'eventName': widget.eventName,
        'createdAt': now,
        'status': 'active',
        'participants': [],
        'manualEntries': [],
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
    return shouldLeave ?? false;
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
                Clipboard.setData(ClipboardData(text: competitionId));
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
                  .doc(competitionId)
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

                return SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Event Info Card
                        _buildEventInfoCard(primaryColor, isDark),
                        const SizedBox(height: 20),
                        // QR Code Section
                        _buildQRCodeSection(primaryColor, isDark),
                        const SizedBox(height: 20),
                        // Participant Stats
                        _buildStatsCard(
                            participants?.length ?? 0,
                            manualEntries?.length ?? 0,
                            primaryColor,
                            isDark),
                        const SizedBox(height: 20),
                        // Manual Entry Button
                        _buildManualEntryButton(primaryColor),
                        const SizedBox(height: 20),
                        // Participants List
                        if (participants != null && participants.isNotEmpty)
                          _buildParticipantsList(
                              participants, primaryColor, isDark),
                        if (manualEntries != null && manualEntries.isNotEmpty)
                          _buildManualEntriesList(
                              manualEntries, primaryColor, isDark),
                      ],
                    ),
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
          const Icon(
            Icons.emoji_events,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Active',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
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
          const SizedBox(height: 8),
          Text(
            'Shooters can scan this QR code to join the competition',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
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
              data: qrData ?? competitionId,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              foregroundColor: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Competition ID:',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            competitionId.substring(0, 8) + '...',
            style: TextStyle(
              fontSize: 14,
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
      int appParticipants, int manualParticipants, Color primaryColor, bool isDark) {
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
              appParticipants.toString(),
              'App Users',
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
              Icons.edit,
              manualParticipants.toString(),
              'Manual Entries',
              primaryColor,
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
    Color primaryColor,
    bool isDark,
  ) {
    return Column(
      children: [
        Icon(icon, color: primaryColor, size: 28),
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

  Widget _buildManualEntryButton(Color primaryColor) {
    return ElevatedButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => ManualEntryDialog(
            competitionId: competitionId,
          ),
        );
      },
      icon: const Icon(Icons.person_add),
      label: const Text(
        'Add Manual Entry',
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

  Widget _buildParticipantsList(
    List<Map<String, dynamic>> participants,
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
          Text(
            'App Participants',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...participants.map((participant) {
            return _buildParticipantRow(
              participant['name'] ?? 'Unknown',
              participant['score']?.toString() ?? '-',
              participant['xCount']?.toString() ?? '-',
              participant['submitted'] == true,
              primaryColor,
              isDark,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildManualEntriesList(
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
          Text(
            'Manual Entries',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...entries.map((entry) {
            return _buildParticipantRow(
              entry['name'] ?? 'Unknown',
              entry['score']?.toString() ?? '-',
              entry['xCount']?.toString() ?? '-',
              true,
              primaryColor,
              isDark,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildParticipantRow(
    String name,
    String score,
    String xCount,
    bool submitted,
    Color primaryColor,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person,
            color: primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          if (submitted) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Score: $score',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (xCount != '-' && xCount != '0')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.gps_fixed,
                      size: 14,
                      color: Colors.amber[700],
                    ),
                    const SizedBox(width: 2),
                    Text(
                      xCount,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber[700],
                      ),
                    ),
                  ],
                ),
              ),
          ] else ...[
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
}
