// lib/screens/comps/join_competition/join_confirmation_dialog.dart
// Dialog shown after scanning QR code to confirm joining a competition

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';
import '../../../services/auth_service.dart';
import 'shooter_score_screen.dart';

class JoinConfirmationDialog extends StatefulWidget {
  final String competitionId;

  const JoinConfirmationDialog({
    super.key,
    required this.competitionId,
  });

  @override
  State<JoinConfirmationDialog> createState() => _JoinConfirmationDialogState();
}

class _JoinConfirmationDialogState extends State<JoinConfirmationDialog> {
  bool isLoading = true;
  bool isJoining = false;
  String? errorMessage;
  Map<String, dynamic>? competitionData;
  String? eventName;

  @override
  void initState() {
    super.initState();
    _loadCompetitionData();
  }

  Future<void> _loadCompetitionData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('competitions')
          .doc(widget.competitionId)
          .get();

      if (!doc.exists) {
        setState(() {
          isLoading = false;
          errorMessage = 'Competition not found. Please check the QR code or ID.';
        });
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] as String?;

      if (status != 'active') {
        setState(() {
          isLoading = false;
          errorMessage = 'This competition is no longer active.';
        });
        return;
      }

      setState(() {
        competitionData = data;
        eventName = data['eventName'] as String?;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading competition: $e';
      });
    }
  }

  Future<void> _joinCompetition() async {
    setState(() {
      isJoining = true;
    });

    try {
      // Get current user info
      final authService = AuthService();
      final user = authService.currentUser;
      String shooterName = 'Anonymous';

      if (user != null) {
        try {
          final profile = await authService.getUserProfile(user.uid);
          shooterName = '${profile.firstName} ${profile.lastName}'.trim();
          if (shooterName.isEmpty) {
            shooterName = profile.email.split('@').first;
          }
        } catch (e) {
          shooterName = user.email?.split('@').first ?? 'Anonymous';
        }
      }

      // Add participant to competition
      // Note: Cannot use FieldValue.serverTimestamp() inside arrayUnion
      // Using DateTime.now() instead, which Firestore converts to Timestamp
      final participantData = {
        'userId': user?.uid ?? 'anonymous_${DateTime.now().millisecondsSinceEpoch}',
        'name': shooterName,
        'joinedAt': DateTime.now(),
        'submitted': false,
      };

      await FirebaseFirestore.instance
          .collection('competitions')
          .doc(widget.competitionId)
          .update({
        'participants': FieldValue.arrayUnion([participantData]),
      });

      if (mounted) {
        Navigator.pop(context); // Close this dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShooterScoreScreen(
              competitionId: widget.competitionId,
              eventName: eventName ?? 'Unknown Event',
              shooterName: shooterName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isJoining = false;
          errorMessage = 'Error joining competition: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.primaryColor;

    return AlertDialog(
      title: isLoading
          ? const Text('Loading...')
          : errorMessage != null
              ? Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text('Error'),
                  ],
                )
              : Row(
                  children: [
                    Icon(Icons.emoji_events, color: primaryColor),
                    const SizedBox(width: 8),
                    const Text('Join Competition'),
                  ],
                ),
      content: isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : errorMessage != null
              ? Text(errorMessage!)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'You are invited to join:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sports_score,
                            color: primaryColor,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              eventName ?? 'Unknown Event',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Do you wish to join this competition?',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You will be able to calculate and submit your score after joining.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
      actions: isLoading
          ? null
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              if (errorMessage == null)
                ElevatedButton.icon(
                  onPressed: isJoining ? null : _joinCompetition,
                  icon: isJoining
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(isJoining ? 'Joining...' : 'Yes, Join'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
    );
  }
}
