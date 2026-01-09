import 'package:hive/hive.dart';

part 'course_of_fire.g.dart';

@HiveType(typeId: 115)
class CourseOfFire extends HiveObject {
  // Distance field (now first)
  @HiveField(0)
  int? distance; // Optional - distance in meters

  @HiveField(1)
  String? distanceNotes; // Optional - distance notes

  @HiveField(2)
  int? totalTime; // Optional - time limit in seconds

  @HiveField(3)
  String? timeNotes; // Optional - time notes

  @HiveField(4)
  int? totalRounds; // Optional - total number of rounds

  @HiveField(5)
  String? roundsNotes; // Optional - rounds notes

  @HiveField(6)
  int? maxScore; // Optional - maximum possible score

  @HiveField(7)
  String? maxScoreNotes; // Optional - max score notes

  @HiveField(8)
  String? generalNotes; // Optional - general notes

  CourseOfFire({
    this.distance,
    this.distanceNotes,
    this.totalTime,
    this.timeNotes,
    this.totalRounds,
    this.roundsNotes,
    this.maxScore,
    this.maxScoreNotes,
    this.generalNotes,
  });
}
