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

  /// Convert to JSON for backup/restore
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'event': event,
      'score': score,
      'xCount': xCount,
      'position': position,
      'totalShooters': totalShooters,
    };
  }

  /// Create from JSON for backup/restore
  factory CompHistoryEntry.fromJson(Map<String, dynamic> json) {
    return CompHistoryEntry(
      date: DateTime.parse(json['date'] as String),
      event: json['event'] as String,
      score: json['score'] as int,
      xCount: json['xCount'] as int,
      position: json['position'] as int,
      totalShooters: json['totalShooters'] as int,
    );
  }
}
