import 'package:hive/hive.dart';

part 'practice_stage.g.dart';

@HiveType(typeId: 129)
class PracticeStage extends HiveObject {
  @HiveField(0)
  int? distance; // Optional - distance in meters

  @HiveField(1)
  int? rounds; // Optional - number of rounds

  @HiveField(2)
  int? time; // Optional - time limit in seconds

  @HiveField(3)
  String notesHeader; // Always required - stage identifier

  @HiveField(4)
  String? notes; // Optional - detailed notes

  PracticeStage({
    this.distance,
    this.rounds,
    this.time,
    required this.notesHeader,
    this.notes,
  });
}
