// lib/screens/comps/competition_history_screen.dart
// Screen for viewing competition history

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../models/comp_history_entry.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/help_icon_button.dart';
import '../../utils/help_content.dart';

class CompetitionHistoryScreen extends StatelessWidget {
  const CompetitionHistoryScreen({super.key});

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getPositionSuffix(int position) {
    if (position == 1) return 'st';
    if (position == 2) return 'nd';
    if (position == 3) return 'rd';
    return 'th';
  }

  Color _getPositionColor(int position) {
    if (position == 1) return Colors.amber;
    if (position == 2) return Colors.grey.shade400;
    if (position == 3) return Colors.brown.shade300;
    return Colors.blue;
  }

  IconData _getPositionIcon(int position) {
    if (position <= 3) return Icons.emoji_events;
    return Icons.sports_score;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = themeProvider.primaryColor;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/comps');
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
        drawer: const AppDrawer(currentRoute: 'comp_history'),
        appBar: AppBar(
          elevation: 0,
          title: const Text(
            'Competition History',
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
              title: 'Competition History Help',
              content: HelpContent.competitionHistoryScreen,
            ),
          ],
        ),
        body: ValueListenableBuilder<Box<CompHistoryEntry>>(
          valueListenable: Hive.box<CompHistoryEntry>('comp_history').listenable(),
          builder: (context, box, _) {
            final entries = box.values.toList().reversed.toList(); // Most recent first

            if (entries.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 80,
                      color: isDark ? Colors.white30 : Colors.black26,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Competition History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Competitions you participate in will appear here after they end.',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white54 : Colors.black38,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final positionColor = _getPositionColor(entry.position);

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          isDark ? Colors.grey[850]! : Colors.white,
                          isDark ? Colors.grey[800]! : Colors.grey[50]!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row with date and position
                          Row(
                            children: [
                              // Position badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: positionColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: positionColor.withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getPositionIcon(entry.position),
                                      size: 16,
                                      color: positionColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${entry.position}${_getPositionSuffix(entry.position)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: positionColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              // Date
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(entry.date),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Event name
                          Text(
                            entry.event,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Divider
                          Divider(
                            color: isDark ? Colors.grey[700] : Colors.grey[300],
                            height: 1,
                          ),
                          const SizedBox(height: 12),
                          // Stats row
                          Row(
                            children: [
                              // Score
                              Expanded(
                                child: _buildStat(
                                  Icons.military_tech,
                                  'Score',
                                  entry.score.toString(),
                                  primaryColor,
                                  isDark,
                                ),
                              ),
                              // X Count
                              if (entry.xCount > 0)
                                Expanded(
                                  child: _buildStat(
                                    Icons.gps_fixed,
                                    'X Count',
                                    entry.xCount.toString(),
                                    Colors.amber[700]!,
                                    isDark,
                                  ),
                                ),
                              // Total shooters
                              Expanded(
                                child: _buildStat(
                                  Icons.people,
                                  'Shooters',
                                  '${entry.position}/${entry.totalShooters}',
                                  isDark ? Colors.white70 : Colors.black54,
                                  isDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildStat(
    IconData icon,
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
      ],
    );
  }
}
