// lib/screens/comps/run_competition/event_selection_screen.dart
// Screen for selecting an event when running a competition

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';
import '../../../data/dropdown_values.dart';
import '../../../widgets/help_icon_button.dart';
import '../../../utils/help_content.dart';
import 'competition_runner_screen.dart';

// Same timeout as in competition_runner_screen.dart
const Duration _competitionTimeout = Duration(hours: 3);

class EventSelectionScreen extends StatefulWidget {
  const EventSelectionScreen({super.key});

  @override
  State<EventSelectionScreen> createState() => _EventSelectionScreenState();
}

class _EventSelectionScreenState extends State<EventSelectionScreen> {
  String? selectedEvent;
  List<String> availableEvents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cleanupAbandonedCompetitions();
    _loadEvents();
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
      // Silently handle cleanup errors
    }
  }

  void _loadEvents() {
    setState(() {
      // Get all master practices (events) from the dropdown values
      availableEvents = DropdownValues.masterPractices;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = themeProvider.primaryColor;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Select Event',
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
            title: 'Event Selection Help',
            content: HelpContent.eventSelectionScreen,
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
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
                        Icon(
                          Icons.emoji_events,
                          size: 48,
                          color: primaryColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Choose Competition Event',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select the event you want to run as a competition',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  // Event List
                  Expanded(
                    child: availableEvents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  size: 64,
                                  color: primaryColor.withValues(alpha: 0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No events available',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: availableEvents.length,
                            itemBuilder: (context, index) {
                              final event = availableEvents[index];
                              final isSelected = selectedEvent == event;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: isSelected ? 4 : 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: isSelected
                                      ? BorderSide(
                                          color: primaryColor,
                                          width: 2,
                                        )
                                      : BorderSide.none,
                                ),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      selectedEvent = event;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? primaryColor
                                                    .withValues(alpha: 0.2)
                                                : primaryColor
                                                    .withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isSelected
                                                ? Icons.check_circle
                                                : Icons.sports_score,
                                            color: primaryColor,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                event,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black87,
                                                ),
                                              ),
                                              if (isSelected)
                                                Text(
                                                  'Selected',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: primaryColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(
                                            Icons.check,
                                            color: primaryColor,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  // Start Button
                  if (selectedEvent != null)
                    Container(
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
                      child: SafeArea(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CompetitionRunnerScreen(
                                    eventName: selectedEvent!,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text(
                              'Start Competition',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
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
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
