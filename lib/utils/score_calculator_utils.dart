import 'package:hive_flutter/hive_flutter.dart';

import '../data/dropdown_values.dart';
import '../models/hive/event.dart';
import '../models/hive/event_content.dart';
import '../models/hive/practice.dart';
import '../models/hive/target_info.dart';

class ScoreCalculatorUtils {
  const ScoreCalculatorUtils._();

  static Event? findEventByName(String? eventName) {
    if (eventName == null || eventName.isEmpty) {
      return null;
    }

    try {
      if (!Hive.isBoxOpen('events')) {
        return null;
      }

      final eventBox = Hive.box<Event>('events');
      for (final event in eventBox.values) {
        if (event.name == eventName) {
          return event;
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  static int? firearmIdFromCode(String? firearmCode) {
    if (firearmCode == null || firearmCode.isEmpty) {
      return null;
    }

    return DropdownValues.getFirearmIdByCode(firearmCode);
  }

  static EventContent? getEventContent({
    required String? eventName,
    String? firearmCode,
  }) {
    final event = findEventByName(eventName);
    if (event == null) {
      return null;
    }

    final firearmId = firearmIdFromCode(firearmCode);
    if (firearmId == null) {
      return event.baseContent;
    }

    return event.getContentForFirearmId(firearmId);
  }

  static int? getMaxScore({
    required String? eventName,
    String? firearmCode,
    bool requireFirearm = false,
  }) {
    if (eventName == DropdownValues.freestyle) {
      return null;
    }

    if (requireFirearm && firearmIdFromCode(firearmCode) == null) {
      return null;
    }

    return getEventContent(
      eventName: eventName,
      firearmCode: firearmCode,
    )?.courseOfFire.maxScore;
  }

  static int? getTotalRounds({
    required String? eventName,
    String? firearmCode,
    bool requireFirearm = false,
  }) {
    final perTargetRounds = getPerTargetRounds(
      eventName: eventName,
      firearmCode: firearmCode,
      requireFirearm: requireFirearm,
    );
    if (perTargetRounds == null || perTargetRounds.isEmpty) {
      return null;
    }

    return perTargetRounds.fold<int>(0, (sum, rounds) => sum + rounds);
  }

  static int? getRoundsForTarget({
    required String? eventName,
    String? firearmCode,
    required int targetIndex,
    bool requireFirearm = false,
  }) {
    final perTargetRounds = getPerTargetRounds(
      eventName: eventName,
      firearmCode: firearmCode,
      requireFirearm: requireFirearm,
    );
    if (perTargetRounds == null || perTargetRounds.isEmpty) {
      return null;
    }

    if (targetIndex < perTargetRounds.length) {
      return perTargetRounds[targetIndex];
    }

    return perTargetRounds.last;
  }

  static int? getRequiredTargetCount({
    required String? eventName,
    String? firearmCode,
    bool requireFirearm = false,
  }) {
    final perTargetRounds = getPerTargetRounds(
      eventName: eventName,
      firearmCode: firearmCode,
      requireFirearm: requireFirearm,
    );
    if (perTargetRounds == null || perTargetRounds.isEmpty) {
      return null;
    }

    return perTargetRounds.length;
  }

  static List<int>? getPerTargetRounds({
    required String? eventName,
    String? firearmCode,
    bool requireFirearm = false,
  }) {
    if (eventName == DropdownValues.freestyle) {
      return null;
    }

    if (requireFirearm && firearmIdFromCode(firearmCode) == null) {
      return null;
    }

    final event = findEventByName(eventName);
    if (event == null) {
      return null;
    }

    final content = getEventContent(
      eventName: eventName,
      firearmCode: firearmCode,
    );
    if (content == null) {
      return null;
    }

    final mode = event.scoreChangeTrigger.mode;
    final eventTotalRounds = content.courseOfFire.totalRounds ?? 0;

    if (mode == 0) {
      return [eventTotalRounds];
    }

    final practices = [...content.practices]
      ..sort((a, b) => a.practiceNumber.compareTo(b.practiceNumber));

    if (mode == 1) {
      if (practices.isEmpty) {
        return [eventTotalRounds];
      }
      return practices.map(_practiceRounds).toList();
    }

    if (mode == 2) {
      final flattenedStages = <({int practice, int stage, int rounds})>[];
      for (final practice in practices) {
        final stages = [...practice.stages]
          ..sort((a, b) => a.stageNumber.compareTo(b.stageNumber));
        for (final stage in stages) {
          flattenedStages.add((
            practice: practice.practiceNumber,
            stage: stage.stageNumber,
            rounds: stage.rounds ?? 0,
          ));
        }
      }

      if (flattenedStages.isEmpty) {
        return [eventTotalRounds];
      }

      final checkpointPositions = <int>{};
      for (final checkpoint in event.scoreChangeTrigger.checkpoints) {
        var index = -1;
        if (checkpoint.stageNumber != null) {
          index = flattenedStages.indexWhere(
            (stage) =>
                stage.practice == checkpoint.practiceNumber &&
                stage.stage == checkpoint.stageNumber,
          );
        } else {
          for (var i = flattenedStages.length - 1; i >= 0; i--) {
            if (flattenedStages[i].practice == checkpoint.practiceNumber) {
              index = i;
              break;
            }
          }
        }

        if (index >= 0) {
          checkpointPositions.add(index);
        }
      }

      final sortedPositions = checkpointPositions.toList()..sort();
      if (sortedPositions.isEmpty) {
        final total = flattenedStages.fold<int>(
          0,
          (sum, stage) => sum + stage.rounds,
        );
        return [total];
      }

      final targetRounds = <int>[];
      var start = 0;
      for (final end in sortedPositions) {
        if (end < start) {
          continue;
        }

        var segmentTotal = 0;
        for (var i = start; i <= end && i < flattenedStages.length; i++) {
          segmentTotal += flattenedStages[i].rounds;
        }
        targetRounds.add(segmentTotal);
        start = end + 1;
      }

      if (start < flattenedStages.length) {
        var tailTotal = 0;
        for (var i = start; i < flattenedStages.length; i++) {
          tailTotal += flattenedStages[i].rounds;
        }
        targetRounds.add(tailTotal);
      }

      return targetRounds.isEmpty ? [eventTotalRounds] : targetRounds;
    }

    return [eventTotalRounds];
  }

  static TargetInfo? getTargetInfo({
    required String? eventName,
    String? firearmCode,
  }) {
    try {
      if (!Hive.isBoxOpen('target_info')) {
        return null;
      }

      final content = getEventContent(
        eventName: eventName,
        firearmCode: firearmCode,
      );
      if (content == null || content.targets.isEmpty) {
        return null;
      }

      final firstTarget = content.targets.first;
      final targetName = firstTarget.title ?? firstTarget.text;
      if (targetName == null || targetName.isEmpty) {
        return null;
      }

      final normalizedTargetName = targetName.trim().toLowerCase();
      final targetInfoBox = Hive.box<TargetInfo>('target_info');
      for (final targetInfo in targetInfoBox.values) {
        if (targetInfo.targetName.trim().toLowerCase() ==
            normalizedTargetName) {
          return targetInfo;
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  static int roundsCounted(Map<int, int>? scoreCounts) {
    if (scoreCounts == null || scoreCounts.isEmpty) {
      return 0;
    }

    return scoreCounts.values.fold<int>(0, (sum, count) => sum + count);
  }

  static Map<String, int>? breakdownForFirestore(Map<int, int>? scoreCounts) {
    if (scoreCounts == null) {
      return null;
    }

    return scoreCounts.map((key, value) => MapEntry(key.toString(), value));
  }

  static int _practiceRounds(Practice practice) {
    var total = 0;
    for (final stage in practice.stages) {
      total += stage.rounds ?? 0;
    }
    return total;
  }
}
