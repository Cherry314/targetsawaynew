import 'package:hive/hive.dart';
import 'target.dart';
import 'ammunition.dart';
import 'sight.dart';
import 'position.dart';
import 'ready_position.dart';
import 'range_command.dart';
import 'tie.dart';
import 'procedural_penalty.dart';
import 'classification.dart';
import 'target_position.dart';
import 'practice.dart';
import 'target_id.dart';
import 'course_of_fire.dart';
import 'event_notes.dart'; // NEW
import 'sighters.dart'; // NEW
import 'notes.dart';
import 'scoring.dart';
import 'loading.dart';
import 'reloading.dart';
import 'magazine.dart';
import 'equipment.dart';
import 'range_equipment.dart';
import 'changing_position.dart';

part 'event_content.g.dart';

@HiveType(typeId: 101)
class EventContent {
  @HiveField(0)
  List<Target> targets;

  @HiveField(21)
  List<Ammunition>? ammunition; // NEW: Ammunition information

  @HiveField(1)
  List<Sight> sights;

  @HiveField(2)
  List<Position> positions;

  @HiveField(3)
  List<ReadyPosition> readyPositions;

  @HiveField(4)
  List<RangeCommand> rangeCommands;

  @HiveField(5)
  List<EventNotes>? notes; // NEW: Before ties

  @HiveField(6)
  List<Tie>? ties;

  @HiveField(7)
  List<ProceduralPenalty>? proceduralPenalties;

  @HiveField(8)
  List<Classification>? classifications;

  @HiveField(9)
  List<TargetPosition>? targetPositions;

  @HiveField(10)
  CourseOfFire courseOfFire;

  @HiveField(11)
  List<Sighters>? sighters; // NEW: After courseOfFire

  @HiveField(12)
  List<Practice> practices;

  @HiveField(13)
  List<TargetID>? targetIds;

  @HiveField(14)
  Notes? generalNotes; // NEW: General notes (not event notes)

  @HiveField(15)
  Scoring? scoring; // NEW: Scoring information

  @HiveField(16)
  Loading? loading; // NEW: Loading information

  @HiveField(22)
  List<Magazine>? magazine; // NEW: Magazine information

  @HiveField(17)
  Reloading? reloading; // NEW: Reloading information

  @HiveField(18)
  Equipment? equipment; // NEW: Equipment information

  @HiveField(19)
  RangeEquipment? rangeEquipment; // NEW: Range equipment information

  @HiveField(20)
  ChangingPosition? changingPosition; // NEW: Changing position information

  EventContent({
    required this.targets,
    this.ammunition,
    required this.sights,
    required this.positions,
    required this.readyPositions,
    required this.rangeCommands,
    this.notes,
    this.ties,
    this.proceduralPenalties,
    this.classifications,
    this.targetPositions,
    required this.courseOfFire,
    this.sighters,
    required this.practices,
    this.targetIds,
    this.generalNotes,
    this.scoring,
    this.loading,
    this.magazine,
    this.reloading,
    this.equipment,
    this.rangeEquipment,
    this.changingPosition,
  });
}
