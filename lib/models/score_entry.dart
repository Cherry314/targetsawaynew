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
  
  // Score breakdown fields (number of hits at each score level)
  @HiveField(15)
  int? scoreX;
  @HiveField(16)
  int? score10;
  @HiveField(17)
  int? score9;
  @HiveField(18)
  int? score8;
  @HiveField(19)
  int? score7;
  @HiveField(20)
  int? score6;
  @HiveField(21)
  int? score5;
  @HiveField(22)
  int? score4;
  @HiveField(23)
  int? score3;
  @HiveField(24)
  int? score2;
  @HiveField(25)
  int? score1;
  @HiveField(26)
  int? score0;

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
    this.scoreX,
    this.score10,
    this.score9,
    this.score8,
    this.score7,
    this.score6,
    this.score5,
    this.score4,
    this.score3,
    this.score2,
    this.score1,
    this.score0,
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
    'scoreX': scoreX,
    'score10': score10,
    'score9': score9,
    'score8': score8,
    'score7': score7,
    'score6': score6,
    'score5': score5,
    'score4': score4,
    'score3': score3,
    'score2': score2,
    'score1': score1,
    'score0': score0,
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
    scoreX: json['scoreX'],
    score10: json['score10'],
    score9: json['score9'],
    score8: json['score8'],
    score7: json['score7'],
    score6: json['score6'],
    score5: json['score5'],
    score4: json['score4'],
    score3: json['score3'],
    score2: json['score2'],
    score1: json['score1'],
    score0: json['score0'],
  );
}
