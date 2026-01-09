import 'package:hive/hive.dart';
import 'stage.dart';

part 'practice.g.dart';

@HiveType(typeId: 127)
class Practice extends HiveObject {
  @HiveField(0)
  int practiceNumber; // Required - practice number (1-10)

  @HiveField(1)
  List<Stage> stages; // Required - list of stages in this practice

  @HiveField(2)
  String? notesHeader; // Optional - practice header

  @HiveField(3)
  String? notes; // Optional - practice notes

  @HiveField(4)
  String? practiceName; // Optional - custom practice name

  Practice({
    required this.practiceNumber,
    required this.stages,
    this.notesHeader,
    this.notes,
    this.practiceName,
  });
}
