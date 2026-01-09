import 'package:hive/hive.dart';

part 'stage.g.dart';

@HiveType(typeId: 128)
class Stage extends HiveObject {
  @HiveField(0)
  int stageNumber; // Required - stage number within practice (now first)

  @HiveField(1)
  int? distance; // Optional - distance in meters

  @HiveField(2)
  String? distanceText; // Optional - distance description text

  @HiveField(3)
  int? rounds; // Optional - number of rounds

  @HiveField(4)
  String? roundsText; // Optional - rounds description text

  @HiveField(5)
  double? time; // Optional - time limit (can include decimals)

  @HiveField(6)
  String? timeText; // Optional - time description text

  @HiveField(7)
  String? notesHeader; // Optional - stage header

  @HiveField(8)
  String? notes; // Optional - stage notes

  Stage({
    required this.stageNumber,
    this.distance,
    this.distanceText,
    this.rounds,
    this.roundsText,
    this.time,
    this.timeText,
    this.notesHeader,
    this.notes,
  });
}
