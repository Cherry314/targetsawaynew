// lib/screens/comps/run_competition/competition_results_screen.dart
// Screen showing final competition results with podium for 1st, 2nd, 3rd

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';

class CompetitionResultsScreen extends StatelessWidget {
  final String eventName;
  final List<Map<String, dynamic>> results;

  const CompetitionResultsScreen({
    super.key,
    required this.eventName,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = themeProvider.primaryColor;

    // Get top 3
    final first = results.isNotEmpty ? results[0] : null;
    final second = results.length > 1 ? results[1] : null;
    final third = results.length > 2 ? results[2] : null;

    return WillPopScope(
      onWillPop: () async {
        // Show confirmation before leaving
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave Results?'),
            content: const Text(
              'Are you sure you want to leave the results screen?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Stay'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Leave'),
              ),
            ],
          ),
        );
        return shouldLeave ?? false;
      },
      child: Scaffold(
        backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
        appBar: AppBar(
          elevation: 0,
          title: const Text(
            'Competition Results',
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldLeave = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Leave Results?'),
                  content: const Text(
                    'Are you sure you want to leave the results screen?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Stay'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Leave'),
                    ),
                  ],
                ),
              );
              if (shouldLeave == true && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Event name
                Container(
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
                        eventName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Final Results',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Podium
                if (results.length >= 2)
                  _buildPodium(second, first, third, isDark)
                else if (first != null)
                  _buildSingleWinner(first, primaryColor, isDark)
                else
                  const Text('No results available'),

                const SizedBox(height: 32),

                // Full results list
                if (results.length > 3) ...[
                  Text(
                    'Full Standings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...results.asMap().entries.skip(3).map((entry) {
                    final index = entry.key;
                    final result = entry.value;
                    return _buildResultRow(
                      index + 1,
                      result['name'] as String,
                      result['score'] as int?,
                      result['xCount'] as int? ?? 0,
                      isDark,
                      primaryColor,
                    );
                  }),
                ],

                const SizedBox(height: 32),

                // Done button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text(
                      'Done',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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
          ),
        ),
      ),
    );
  }

  Widget _buildPodium(
    Map<String, dynamic>? second,
    Map<String, dynamic>? first,
    Map<String, dynamic>? third,
    bool isDark,
  ) {
    return SizedBox(
      height: 280,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 2nd place
          if (second != null)
            _buildPodiumItem(
              position: 2,
              name: second['name'] as String,
              score: second['score'] as int?,
              xCount: second['xCount'] as int? ?? 0,
              color: Colors.grey.shade400,
              height: 200,
              isDark: isDark,
            ),
          const SizedBox(width: 16),
          // 1st place
          if (first != null)
            _buildPodiumItem(
              position: 1,
              name: first['name'] as String,
              score: first['score'] as int?,
              xCount: first['xCount'] as int? ?? 0,
              color: Colors.amber,
              height: 250,
              isDark: isDark,
              isFirst: true,
            ),
          const SizedBox(width: 16),
          // 3rd place
          if (third != null)
            _buildPodiumItem(
              position: 3,
              name: third['name'] as String,
              score: third['score'] as int?,
              xCount: third['xCount'] as int? ?? 0,
              color: Colors.brown.shade300,
              height: 160,
              isDark: isDark,
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
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Crown for 1st place
        if (isFirst)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Icon(
              Icons.emoji_events,
              size: 40,
              color: Colors.amber[700],
            ),
          ),
        // Name card
        Container(
          width: 100,
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
                  fontSize: 14,
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
                    fontSize: 20,
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
                        size: 12,
                        color: Colors.amber[700],
                      ),
                      Text(
                        xCount.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber[700],
                        ),
                      ),
                    ],
                  ),
              ] else
                Text(
                  '-',
                  style: TextStyle(
                    fontSize: 20,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Position number
        Container(
          width: 100,
          height: 40,
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
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        // Podium base
        Container(
          width: 100,
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

  Widget _buildSingleWinner(
    Map<String, dynamic> winner,
    Color primaryColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events,
            size: 64,
            color: Colors.amber[700],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'WINNER',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            winner['name'] as String,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          if (winner['score'] != null) ...[
            Text(
              'Score: ${winner['score']}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            if ((winner['xCount'] as int? ?? 0) > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.gps_fixed,
                    size: 20,
                    color: Colors.amber[700],
                  ),
                  Text(
                    ' ${winner['xCount']} X',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.amber[700],
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow(
    int position,
    String name,
    int? score,
    int xCount,
    bool isDark,
    Color primaryColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                position.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
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
  }
}
