// lib/models/rounds_counter_entry.dart
import 'package:hive/hive.dart';

part 'rounds_counter_entry.g.dart';

@HiveType(typeId: 5)
class RoundsCounterEntry extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  int rounds;

  @HiveField(2)
  String reason;

  @HiveField(3)
  String? notes;

  RoundsCounterEntry({
    required this.date,
    required this.rounds,
    required this.reason,
    this.notes,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'rounds': rounds,
    'reason': reason,
    'notes': notes,
  };

  /// Create from JSON
  factory RoundsCounterEntry.fromJson(Map<String, dynamic> json) => RoundsCounterEntry(
    date: DateTime.parse(json['date']),
    rounds: json['rounds'],
    reason: json['reason'],
    notes: json['notes'],
  );
}
