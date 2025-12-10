// lib/models/score_entry.dart
import 'package:hive/hive.dart';

part 'score_entry.g.dart';

@HiveType(typeId: 1) // changed to 1 for new clean model
class ScoreEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String practice;

  @HiveField(3)
  String caliber;

  @HiveField(4)
  int score;

  @HiveField(5)
  bool targetCaptured;

  @HiveField(6)
  String? targetFilePath; // full resolution

  @HiveField(7)
  String? thumbnailFilePath; // small thumbnail for fast list

  @HiveField(8)
  String? firearmId; // dropdown (nullable)

  @HiveField(9)
  String? firearm; // free text (nullable)

  @HiveField(10)
  String? notes; // multiline text (nullable)

  ScoreEntry({
    required this.id,
    required this.date,
    required this.practice,
    required this.caliber,
    required this.score,
    required this.targetCaptured,
    this.targetFilePath,
    this.thumbnailFilePath,
    this.firearmId,
    this.firearm,
    this.notes,
  });
}
