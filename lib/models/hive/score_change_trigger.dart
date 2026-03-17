import 'package:hive/hive.dart';

part 'score_change_trigger.g.dart';

/// Controls when to show "Time to Score and change target" for an event.
///
/// mode:
/// 0 = after whole competition
/// 1 = after each practice
/// 2 = custom checkpoints (practice/stage list)
@HiveType(typeId: 135)
class ScoreChangeTrigger extends HiveObject {
  @HiveField(0)
  int mode;

  /// Used only when mode == 2
  @HiveField(1)
  List<ScoreChangeCheckpoint> checkpoints;

  ScoreChangeTrigger({
    this.mode = 0,
    List<ScoreChangeCheckpoint>? checkpoints,
  }) : checkpoints = checkpoints ?? [];
}

@HiveType(typeId: 136)
class ScoreChangeCheckpoint extends HiveObject {
  @HiveField(0)
  int practiceNumber;

  /// Optional stage number. If null, trigger applies to the practice as a whole.
  @HiveField(1)
  int? stageNumber;

  ScoreChangeCheckpoint({
    required this.practiceNumber,
    this.stageNumber,
  });
}
