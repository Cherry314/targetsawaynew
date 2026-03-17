import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../models/hive/event.dart';
import '../models/hive/event_content.dart';
import '../models/hive/firearm.dart';
import '../models/hive/target.dart';
import '../models/hive/ammunition.dart';
import '../models/hive/sight.dart';
import '../models/hive/position.dart';
import '../models/hive/ready_position.dart';
import '../models/hive/practice.dart';
import '../models/hive/sighters.dart';
import '../data/firearm_table.dart';
import '../main.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  int? selectedFirearmId;

  @override
  void initState() {
    super.initState();
    // Select first firearm by default
    if (widget.event.applicableFirearmIds.isNotEmpty) {
      selectedFirearmId = widget.event.applicableFirearmIds.first;
    }
  }

  FirearmInfo? getSelectedFirearmInfo() {
    if (selectedFirearmId == null) return null;
    try {
      return firearmMasterTable.firstWhere(
        (f) => f.id == selectedFirearmId,
      );
    } catch (e) {
      return null;
    }
  }

  EventContent getCurrentContent() {
    final firearmInfo = getSelectedFirearmInfo();
    if (firearmInfo == null) return widget.event.baseContent;

    return widget.event.getContentForFirearm(Firearm(
      id: firearmInfo.id,
      code: firearmInfo.code,
      gunType: firearmInfo.gunType,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Event ${widget.event.eventNumber}',
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
        child: Column(
          children: [
            // Event Title Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select Firearm Type',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Firearm Selection Buttons
            Container(
              width: double.infinity,
              color: isDark ? Colors.grey[850] : Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: widget.event.applicableFirearmIds.map((firearmId) {
                    final firearmInfo = firearmMasterTable.firstWhere(
                      (f) => f.id == firearmId,
                      orElse: () => FirearmInfo(
                        id: firearmId,
                        code: 'Unknown',
                        gunType: 'Unknown',
                      ),
                    );
                    final isSelected = selectedFirearmId == firearmId;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Material(
                        color: isSelected ? primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              selectedFirearmId = firearmId;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? primaryColor : isDark ? Colors.grey[600]! : Colors.grey[300]!,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              firearmInfo.code,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : isDark
                                        ? Colors.grey[300]
                                        : Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Event Details
            Expanded(
              child: selectedFirearmId == null
                  ? Center(
                      child: Text(
                        'No firearm options available',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    )
                  : _buildEventDetails(getCurrentContent(), isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetails(EventContent content, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        color: isDark ? Colors.grey[850] : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PreNotes (if exists)
              if (widget.event.prenotes != null &&
                  ((widget.event.prenotes!.title != null && widget.event.prenotes!.title!.isNotEmpty) ||
                   (widget.event.prenotes!.text != null && widget.event.prenotes!.text!.isNotEmpty))) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.event.prenotes!.title != null && widget.event.prenotes!.title!.isNotEmpty) ...[
                        Text(
                          widget.event.prenotes!.title!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (widget.event.prenotes!.text != null && widget.event.prenotes!.text!.isNotEmpty)
                        Text(
                          widget.event.prenotes!.text!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Targets
              if (content.targets.isNotEmpty) ...[
                _buildFieldRow('Targets', '', bold: true, isDark: isDark),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                      children: _formatTargetsRich(content.targets, isDark: isDark),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Ammunition
              if (content.ammunition != null && content.ammunition!.isNotEmpty) ...[
                _buildFieldRow('Ammunition', '', bold: true, isDark: isDark),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                      children: _formatAmmunitionRich(content.ammunition!, isDark: isDark),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Sights
              if (content.sights.isNotEmpty) ...[
                _buildFieldRow('Sights', '', bold: true, isDark: isDark),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                      children: _formatSightsRich(content.sights, isDark: isDark),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Position
              if (content.positions.isNotEmpty) ...[
                _buildFieldRow('Position', '', bold: true, isDark: isDark),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                      children: _formatPositionsWithLineBreaks(content.positions, isDark: isDark),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Ready Position
              if (content.readyPositions.isNotEmpty) ...[
                _buildFieldRow('Ready Position', '', bold: true, isDark: isDark),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                      children: _formatReadyPositionsWithTitle(content.readyPositions, isDark: isDark),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Course of Fire Section
              Text(
                'Course of Fire',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 4),

              // Distance
              if (content.courseOfFire.distance != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                      children: [
                        TextSpan(
                          text: 'Distance : ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        TextSpan(text: '${content.courseOfFire.distance}'),
                        if (content.courseOfFire.distanceNotes != null && content.courseOfFire.distanceNotes!.isNotEmpty) ...[
                          const TextSpan(text: ' '),
                          ..._processRichText(
                            content.courseOfFire.distanceNotes,
                            isDark: isDark,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],

              // Time
              if (content.courseOfFire.totalTime != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                      children: [
                        TextSpan(
                          text: 'Time : ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        TextSpan(text: '${content.courseOfFire.totalTime}'),
                        if (content.courseOfFire.timeNotes != null && content.courseOfFire.timeNotes!.isNotEmpty) ...[
                          const TextSpan(text: ' '),
                          ..._processRichText(
                            content.courseOfFire.timeNotes,
                            isDark: isDark,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],

              // Rounds
              if (content.courseOfFire.totalRounds != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                      children: [
                        TextSpan(
                          text: 'Rounds : ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        TextSpan(text: '${content.courseOfFire.totalRounds}'),
                        if (content.courseOfFire.roundsNotes != null && content.courseOfFire.roundsNotes!.isNotEmpty) ...[
                          const TextSpan(text: ' '),
                          ..._processRichText(
                            content.courseOfFire.roundsNotes,
                            isDark: isDark,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],

              // Max Score
              if (content.courseOfFire.maxScore != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                      children: [
                        TextSpan(
                          text: 'Max Score : ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        TextSpan(text: '${content.courseOfFire.maxScore}'),
                        if (content.courseOfFire.maxScoreNotes != null && content.courseOfFire.maxScoreNotes!.isNotEmpty) ...[
                          const TextSpan(text: ' '),
                          ..._processRichText(
                            content.courseOfFire.maxScoreNotes,
                            isDark: isDark,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],

              // Notes (from course of fire)
              if (content.courseOfFire.generalNotes != null && content.courseOfFire.generalNotes!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                      children: [
                        TextSpan(
                          text: 'Notes : ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        ..._processNotesText(
                          content.courseOfFire.generalNotes!,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Sighters
              if (content.sighters != null && content.sighters!.isNotEmpty) ...[
                _buildFieldRow('Sighters', '', bold: true, isDark: isDark),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                      children: _formatSightersRich(content.sighters!, isDark: isDark),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Practices
              ...content.practices.map((practice) => _buildPractice(practice, isDark)),

              // General Notes
              if (content.generalNotes != null && content.generalNotes!.text != null && content.generalNotes!.text!.isNotEmpty) ...[
                _buildFieldRow('Notes', '', bold: true, isDark: isDark),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                      children: _processRichText(
                        content.generalNotes!.text!,
                        isDark: isDark,
                        boldBase: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Range Commands
              if (content.rangeCommands.isNotEmpty) ...[
                _buildFieldRow('Range Commands', '', bold: true, isDark: isDark),
                const SizedBox(height: 4),
                ...content.rangeCommands.map((rc) =>
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 13,
                          ),
                          children: [
                            ..._processRichText(rc.title, isDark: isDark, boldBase: true),
                            if (rc.text != null && rc.text!.isNotEmpty) ..._processRichText(rc.text, isDark: isDark),
                          ],
                        ),
                      ),
                    )
                ),
                const SizedBox(height: 8),
              ],

              // Scoring
              if (content.scoring != null) ...[
                _buildFieldRow('Scoring', '', bold: true, isDark: isDark),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                      children: _processRichText(
                        content.scoring!.text ?? '',
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Loading
              if (content.loading != null) ...[
                _buildFieldRow('Loading', '', bold: true, isDark: isDark),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                      children: [
                        if (content.loading!.title != null && content.loading!.title!.isNotEmpty)
                          ..._processRichText(content.loading!.title, isDark: isDark, boldBase: true),
                        if (content.loading!.text != null && content.loading!.text!.isNotEmpty) const TextSpan(text: ' '),
                        if (content.loading!.text != null && content.loading!.text!.isNotEmpty)
                          ..._processRichText(content.loading!.text, isDark: isDark),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Magazine
              if (content.magazine != null && content.magazine!.isNotEmpty) ...[
                _buildFieldRow('Magazine, Speedloaders and Moon-Clips:', '', bold: true, isDark: isDark),
                const SizedBox(height: 4),
                ...content.magazine!.map((mag) =>
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 13,
                          ),
                          children: [
                            if (mag.title != null && mag.title!.isNotEmpty)
                              ..._processRichText(mag.title, isDark: isDark, boldBase: true),
                            if (mag.title != null && mag.title!.isNotEmpty && mag.text != null && mag.text!.isNotEmpty)
                              const TextSpan(text: ' '),
                            if (mag.text != null && mag.text!.isNotEmpty)
                              ..._processRichText(mag.text, isDark: isDark),
                          ],
                        ),
                      ),
                    )
                ),
                const SizedBox(height: 8),
              ],

              // Reloading
              if (content.reloading != null) ...[
                _buildFieldRow('Reloading', '', bold: true, isDark: isDark),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                      children: [
                        if (content.reloading!.title != null && content.reloading!.title!.isNotEmpty)
                          ..._processRichText(content.reloading!.title, isDark: isDark, boldBase: true),
                        if (content.reloading!.text != null && content.reloading!.text!.isNotEmpty) const TextSpan(text: ' '),
                        if (content.reloading!.text != null && content.reloading!.text!.isNotEmpty)
                          ..._processRichText(content.reloading!.text, isDark: isDark),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Equipment
              if (content.equipment != null) ...[
                _buildFieldRow('Equipment', '', bold: true, isDark: isDark),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                      children: [
                        if (content.equipment!.title != null && content.equipment!.title!.isNotEmpty)
                          ..._processRichText(content.equipment!.title, isDark: isDark, boldBase: true),
                        if (content.equipment!.text != null && content.equipment!.text!.isNotEmpty) const TextSpan(text: ' '),
                        if (content.equipment!.text != null && content.equipment!.text!.isNotEmpty)
                          ..._processRichText(content.equipment!.text, isDark: isDark),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Range Equipment
              if (content.rangeEquipment != null) ...[
                _buildFieldRow('Range Equipment', '', bold: true, isDark: isDark),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                      children: [
                        if (content.rangeEquipment!.title != null && content.rangeEquipment!.title!.isNotEmpty)
                          ..._processRichText(content.rangeEquipment!.title, isDark: isDark, boldBase: true),
                        if (content.rangeEquipment!.text != null && content.rangeEquipment!.text!.isNotEmpty) const TextSpan(text: ' '),
                        if (content.rangeEquipment!.text != null && content.rangeEquipment!.text!.isNotEmpty)
                          ..._processRichText(content.rangeEquipment!.text, isDark: isDark),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Changing Position
              if (content.changingPosition != null) ...[
                _buildFieldRow('Changing position', '', bold: true, isDark: isDark),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                      children: [
                        if (content.changingPosition!.title != null && content.changingPosition!.title!.isNotEmpty)
                          ..._processRichText(content.changingPosition!.title, isDark: isDark, boldBase: true),
                        if (content.changingPosition!.text != null && content.changingPosition!.text!.isNotEmpty) const TextSpan(text: ' '),
                        if (content.changingPosition!.text != null && content.changingPosition!.text!.isNotEmpty)
                          ..._processRichText(content.changingPosition!.text, isDark: isDark),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Ties
              if (content.ties != null && content.ties!.isNotEmpty) ...[
                _buildFieldRow('Ties', '', bold: true, isDark: isDark),
                const SizedBox(height: 4),
                ...content.ties!.map((tie) =>
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 13,
                          ),
                          children: [
                            ..._processRichText(tie.title, isDark: isDark, boldBase: true),
                            if (tie.text != null && tie.text!.isNotEmpty) ..._processRichText(tie.text, isDark: isDark),
                            if (tie.idx != null && tie.idx!.isNotEmpty) ...[
                              const TextSpan(text: '\n'),
                              TextSpan(text: '${tie.idx}. '),
                              if (tie.idxText != null && tie.idxText!.isNotEmpty)
                                ..._processRichText(tie.idxText, isDark: isDark),
                            ],
                          ],
                        ),
                      ),
                    )
                ),
                const SizedBox(height: 8),
              ],

              // Procedural Penalties
              if (content.proceduralPenalties != null && content.proceduralPenalties!.isNotEmpty) ...[
                _buildFieldRow('Procedural Penalties', '', bold: true, isDark: isDark),
                const SizedBox(height: 4),
                ...content.proceduralPenalties!.map((pp) =>
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 13,
                          ),
                          children: [
                            ..._processRichText(pp.title, isDark: isDark, boldBase: true),
                            const TextSpan(text: ': '),
                            if (pp.text != null && pp.text!.isNotEmpty)
                              ..._processRichText(pp.text, isDark: isDark),
                            if (pp.idx != null && pp.idx!.isNotEmpty) ...[
                              const TextSpan(text: '\n'),
                              TextSpan(text: '${pp.idx}. '),
                              if (pp.idxText != null && pp.idxText!.isNotEmpty)
                                ..._processRichText(pp.idxText, isDark: isDark),
                            ],
                          ],
                        ),
                      ),
                    )
                ),
                const SizedBox(height: 8),
              ],

              // Classifications
              if (content.classifications != null && content.classifications!.isNotEmpty) ...[
                _buildFieldRow('Classifications', '', bold: true, isDark: isDark),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Text(
                    'The classification scores bands are as follows',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
                ...content.classifications!.map((classification) =>
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 2),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(
                              text: classification.className,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            TextSpan(text: '  ${classification.min} - ${classification.max}'),
                          ],
                        ),
                      ),
                    )
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldRow(String label, String value, {bool bold = false, required bool isDark}) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 13,
        ),
        children: [
          TextSpan(
            text: '$label : ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _formatTargetsRich(List<Target> targets, {required bool isDark}) {
    if (targets.isEmpty) return [];

    final List<InlineSpan> spans = [];
    for (int i = 0; i < targets.length; i++) {
      final target = targets[i];
      String text = target.text ?? target.title ?? '';

      if (target.qtyNeeded != null) text += ' : Qty: ${target.qtyNeeded}';

      spans.addAll(_processRichText(text, isDark: isDark));

      if (i < targets.length - 1) {
        spans.add(const TextSpan(text: ', '));
      }
    }

    return spans;
  }

  List<InlineSpan> _formatAmmunitionRich(List<Ammunition> ammunition, {required bool isDark}) {
    if (ammunition.isEmpty) return [];

    final List<InlineSpan> spans = [];
    for (int i = 0; i < ammunition.length; i++) {
      final ammo = ammunition[i];
      final text = ammo.text ?? ammo.title ?? '';

      spans.addAll(_processRichText(text, isDark: isDark));

      if (i < ammunition.length - 1) {
        spans.add(const TextSpan(text: ', '));
      }
    }
    return spans;
  }

  List<InlineSpan> _formatSightsRich(List<Sight> sights, {required bool isDark}) {
    if (sights.isEmpty) return [];

    final List<InlineSpan> spans = [];
    for (int i = 0; i < sights.length; i++) {
      final sight = sights[i];
      final text = sight.text ?? '';

      spans.addAll(_processRichText(text, isDark: isDark));

      if (i < sights.length - 1) {
        spans.add(const TextSpan(text: ', '));
      }
    }
    return spans;
  }

  List<InlineSpan> _formatPositionsWithLineBreaks(List<Position> positions, {required bool isDark}) {
    if (positions.isEmpty) return [];

    final List<InlineSpan> spans = [];
    for (int i = 0; i < positions.length; i++) {
      final position = positions[i];
      final text = position.text ?? position.title ?? '';

      spans.addAll(_processRichText(text, isDark: isDark));

      if (i < positions.length - 1) {
        spans.add(const TextSpan(text: ', '));
      }
    }

    return spans;
  }

  List<InlineSpan> _formatReadyPositionsWithTitle(List<ReadyPosition> readyPositions, {required bool isDark}) {
    if (readyPositions.isEmpty) return [];

    final List<InlineSpan> spans = [];
    for (int i = 0; i < readyPositions.length; i++) {
      final readyPosition = readyPositions[i];

      if (readyPosition.title != null && readyPosition.title!.isNotEmpty) {
        spans.addAll(_processRichText(
          readyPosition.title,
          isDark: isDark,
          boldBase: true,
        ));
        if (readyPosition.text != null && readyPosition.text!.isNotEmpty) {
          spans.add(const TextSpan(text: ' '));
        }
      }

      if (readyPosition.text != null && readyPosition.text!.isNotEmpty) {
        spans.addAll(_processRichText(
          readyPosition.text,
          isDark: isDark,
        ));
      }

      if (i < readyPositions.length - 1) {
        spans.add(const TextSpan(text: ', '));
      }
    }

    return spans;
  }

  List<InlineSpan> _formatSightersRich(List<Sighters> sighters, {required bool isDark}) {
    if (sighters.isEmpty) return [];

    final List<InlineSpan> spans = [];
    for (int i = 0; i < sighters.length; i++) {
      final sighter = sighters[i];

      spans.addAll(_processRichText(sighter.text, isDark: isDark, boldBase: true));

      if (i < sighters.length - 1) {
        spans.add(const TextSpan(text: ', '));
      }
    }
    return spans;
  }

  List<InlineSpan> _processRichText(String? text, {required bool isDark, bool boldBase = false}) {
    if (text == null || text.isEmpty) return [];

    final List<InlineSpan> spans = [];

    // First split by <> for line breaks
    final lineParts = text.split('<>');

    for (int lineIndex = 0; lineIndex < lineParts.length; lineIndex++) {
      final line = lineParts[lineIndex];

      if (line.isNotEmpty) {
        spans.addAll(_processBoldMarkers(line, isDark: isDark, boldBase: boldBase));
      }

      if (lineIndex < lineParts.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return spans;
  }

  List<InlineSpan> _processBoldMarkers(String text, {required bool isDark, bool boldBase = false}) {
    final List<InlineSpan> spans = [];
    final RegExp boldPattern = RegExp(r'\{([^}]*)\}');

    int lastEnd = 0;
    for (final match in boldPattern.allMatches(text)) {
      if (match.start > lastEnd) {
        final normalText = text.substring(lastEnd, match.start);
        spans.add(TextSpan(
          text: normalText,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: boldBase ? FontWeight.bold : FontWeight.normal,
          ),
        ));
      }

      final boldText = match.group(1) ?? '';
      if (boldText.isNotEmpty) {
        spans.add(TextSpan(
          text: boldText,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ));
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      final remainingText = text.substring(lastEnd);
      spans.add(TextSpan(
        text: remainingText,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: boldBase ? FontWeight.bold : FontWeight.normal,
        ),
      ));
    }

    if (spans.isEmpty && text.isNotEmpty) {
      spans.add(TextSpan(
        text: text,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: boldBase ? FontWeight.bold : FontWeight.normal,
        ),
      ));
    }

    return spans;
  }

  List<InlineSpan> _processNotesText(String? text, {required bool isDark}) {
    return _processRichText(text, isDark: isDark);
  }

  String _formatNumber(double? value) {
    if (value == null) return '';
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  Widget _buildPractice(Practice practice, bool isDark) {
    final hasMultipleStages = practice.stages.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 13,
            ),
            children: [
              if (practice.practiceName != null && practice.practiceName!.isNotEmpty) ...[
                TextSpan(
                  text: practice.practiceName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                TextSpan(
                  text: ' ${practice.practiceNumber}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ] else ...[
                TextSpan(
                  text: 'Practice ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                TextSpan(
                  text: '${practice.practiceNumber}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
              TextSpan(
                text: ' :',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        ...practice.stages.map<Widget>((stage) {
          return Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasMultipleStages) ...[
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                      children: [
                        TextSpan(
                          text: 'Stage ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: '${stage.stageNumber}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: ' :',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                ],

                if (stage.distance != null) ...[
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                      children: [
                        TextSpan(text: '${stage.distance}'),
                        if (stage.distanceText != null && stage.distanceText!.isNotEmpty) ...[
                          const TextSpan(text: ' '),
                          ..._processRichText(stage.distanceText, isDark: isDark),
                        ],
                      ],
                    ),
                  ),
                ],

                if (stage.rounds != null) ...[
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                      children: [
                        TextSpan(text: '${stage.rounds}'),
                        if (stage.roundsText != null && stage.roundsText!.isNotEmpty) ...[
                          const TextSpan(text: ' '),
                          ..._processRichText(stage.roundsText, isDark: isDark),
                        ],
                      ],
                    ),
                  ),
                ],

                if (stage.time != null) ...[
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                      children: [
                        TextSpan(text: _formatNumber(stage.time)),
                        if (stage.timeText != null && stage.timeText!.isNotEmpty) ...[
                          const TextSpan(text: ' '),
                          ..._processRichText(stage.timeText, isDark: isDark),
                        ],
                      ],
                    ),
                  ),
                ],

                if (stage.notesHeader != null) ...[
                  const SizedBox(height: 2),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                      children: [
                        ..._processRichText(
                          stage.notesHeader,
                          isDark: isDark,
                          boldBase: true,
                        ),
                        if (stage.notes != null) const TextSpan(text: ' '),
                        if (stage.notes != null) ..._processRichText(stage.notes, isDark: isDark),
                      ],
                    ),
                  ),
                ] else if (stage.notes != null) ...[
                  const SizedBox(height: 2),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 13,
                      ),
                      children: _processRichText(stage.notes, isDark: isDark),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }
}
