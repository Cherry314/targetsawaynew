// lib/models/score_entry.dart
import 'package:hive/hive.dart';

part 'score_entry.g.dart';

@HiveType(typeId: 1)
class ScoreEntry extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  DateTime date;
  @HiveField(2)
  int score;
  @HiveField(3)
  String practice;
  @HiveField(4)
  String caliber;
  @HiveField(5)
  String firearmId;
  @HiveField(6)
  String? firearm;
  @HiveField(7)
  String? notes;
  @HiveField(8)
  bool comp;
  @HiveField(9)
  String? compId;
  @HiveField(10)
  String? compResult;
  @HiveField(11)
  String? targetFilePath;
  @HiveField(12)
  String? thumbnailFilePath;
  @HiveField(13)
  bool targetCaptured;
  @HiveField(14)
  int? x;

  ScoreEntry({
    required this.id,
    required this.date,
    required this.score,
    required this.practice,
    required this.caliber,
    required this.firearmId,
    this.firearm,
    this.notes,
    required this.comp,
    this.compId,
    this.compResult,
    this.targetFilePath,
    this.thumbnailFilePath,
    required this.targetCaptured,
    this.x,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'score': score,
    'practice': practice,
    'caliber': caliber,
    'firearmId': firearmId,
    'firearm': firearm,
    'notes': notes,
    'comp': comp,
    'compId': compId,
    'compResult': compResult,
    'targetFilePath': targetFilePath,
    'thumbnailFilePath': thumbnailFilePath,
    'targetCaptured': targetCaptured,
    'x': x,
  };

  /// Create from JSON
  factory ScoreEntry.fromJson(Map<String, dynamic> json) => ScoreEntry(
    id: json['id'],
    date: DateTime.parse(json['date']),
    score: json['score'],
    practice: json['practice'],
    caliber: json['caliber'],
    firearmId: json['firearmId'],
    firearm: json['firearm'],
    notes: json['notes'],
    comp: json['comp'],
    compId: json['compId'],
    compResult: json['compResult'],
    targetFilePath: json['targetFilePath'],
    thumbnailFilePath: json['thumbnailFilePath'],
    targetCaptured: json['targetCaptured'],
    x: json['x'],
  );
}
