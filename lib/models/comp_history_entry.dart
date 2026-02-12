// lib/models/comp_history_entry.dart
// Hive model for storing competition history

import 'package:hive/hive.dart';

part 'comp_history_entry.g.dart';

@HiveType(typeId: 134)
class CompHistoryEntry extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final String event;

  @HiveField(2)
  final int score;

  @HiveField(3)
  final int xCount;

  @HiveField(4)
  final int position;

  @HiveField(5)
  final int totalShooters;

  CompHistoryEntry({
    required this.date,
    required this.event,
    required this.score,
    required this.xCount,
    required this.position,
    required this.totalShooters,
  });
}
