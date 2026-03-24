import 'package:flutter/material.dart';

import 'enter_score_screen.dart';

class EventScoringScreen extends StatelessWidget {
  final DateTime? initialDate;
  final String? initialPractice;
  final String? initialCaliber;
  final String? initialFirearmId;
  final String? initialFirearm;

  const EventScoringScreen({
    super.key,
    this.initialDate,
    this.initialPractice,
    this.initialCaliber,
    this.initialFirearmId,
    this.initialFirearm,
  });

  @override
  Widget build(BuildContext context) {
    return EnterScoreScreen(
      scoringMode: true,
      eventScoringMode: true,
      initialDate: initialDate,
      initialPractice: initialPractice,
      initialCaliber: initialCaliber,
      initialFirearmId: initialFirearmId,
      initialFirearm: initialFirearm,
    );
  }
}
