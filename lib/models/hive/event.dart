import 'package:hive/hive.dart';
import '../../data/dropdown_values.dart';
import 'event_content.dart';
import 'event_override.dart';
import 'firearm.dart';
import 'prenotes.dart';
import 'score_change_trigger.dart';

part 'event.g.dart';

@HiveType(typeId: 100)
class Event extends HiveObject {
  @HiveField(0)
  int eventNumber; // unique key

  @HiveField(1)
  String name;

  /// List of Firearm IDs that can be used for this event
  @HiveField(2)
  List<int> applicableFirearmIds;

  /// Pre-notes displayed before the target information
  @HiveField(5)
  PreNotes? prenotes;

  /// Base instructions/content for the event
  @HiveField(3)
  EventContent baseContent;

  /// Overrides for specific firearms
  @HiveField(4)
  List<EventOverride> overrides;

  /// When to trigger "Time to Score and change target".
  @HiveField(6)
  ScoreChangeTrigger scoreChangeTrigger;

  Event({
    required this.eventNumber,
    required this.name,
    required this.applicableFirearmIds,
    this.prenotes,
    required this.baseContent,
    required this.overrides,
    ScoreChangeTrigger? scoreChangeTrigger,
  }) : scoreChangeTrigger = scoreChangeTrigger ?? ScoreChangeTrigger();

  /// Get EventContent for a specific firearm ID.
  ///
  /// This is the primary override path for event conditions: the selected
  /// button is a numeric firearm ID (for example, GRCF = 2), and event
  /// overrides are keyed by numeric firearmIds.
  EventContent getContentForFirearmId(int firearmId) {
    final matchingOverrides = getOverridesForFirearmId(firearmId);
    if (matchingOverrides.isEmpty) {
      return baseContent;
    }

    var content = baseContent;
    for (final override in matchingOverrides) {
      content = mergeContentWithOverride(override, base: content);
    }
    return content;
  }

  /// Get EventContent for a specific firearm.
  EventContent getContentForFirearm(Firearm firearm) {
    final matchingOverrides = getOverridesForFirearm(firearm);
    if (matchingOverrides.isEmpty) {
      return baseContent;
    }

    var content = baseContent;
    for (final override in matchingOverrides) {
      content = mergeContentWithOverride(override, base: content);
    }
    return content;
  }

  /// Get all overrides for a numeric firearm ID, in declaration order.
  ///
  /// Some imported data may preserve firearm identifiers as codes rather than
  /// numeric IDs, so this matches both the selected ID and its mapped code.
  List<EventOverride> getOverridesForFirearmId(int firearmId) {
    final firearmCode = _firearmCodeForId(firearmId)?.trim().toLowerCase();
    return overrides.where((override) {
      if (override.firearmIds.contains(firearmId)) {
        return true;
      }

      if (firearmCode == null || firearmCode.isEmpty) {
        return false;
      }

      final overrideCodes = {
        ...override.firearmCodes.map((code) => code.trim().toLowerCase()),
        ...override.firearmIds
            .map(_firearmCodeForId)
            .whereType<String>()
            .map((code) => code.trim().toLowerCase()),
      };
      return overrideCodes.contains(firearmCode);
    }).toList();
  }

  /// Get the first override for a numeric firearm ID.
  EventOverride? getOverrideForFirearmId(int firearmId) {
    final matchingOverrides = getOverridesForFirearmId(firearmId);
    if (matchingOverrides.isEmpty) return null;
    return matchingOverrides.first;
  }

  /// Get all overrides for a firearm by numeric ID or code, in declaration order.
  List<EventOverride> getOverridesForFirearm(Firearm firearm) {
    final idOverrides = getOverridesForFirearmId(firearm.id);
    if (idOverrides.isNotEmpty) {
      return idOverrides;
    }

    final firearmCode = firearm.code.trim().toLowerCase();
    if (firearmCode.isEmpty) return [];

    return overrides.where((override) {
      final overrideCodes = {
        ...override.firearmCodes.map((code) => code.trim().toLowerCase()),
        ...override.firearmIds
            .map(_firearmCodeForId)
            .whereType<String>()
            .map((code) => code.trim().toLowerCase()),
      };
      return overrideCodes.contains(firearmCode);
    }).toList();
  }

  /// Get the first override for a firearm by numeric ID or code.
  EventOverride? getOverrideForFirearm(Firearm firearm) {
    final matchingOverrides = getOverridesForFirearm(firearm);
    if (matchingOverrides.isEmpty) return null;
    return matchingOverrides.first;
  }

  String? _firearmCodeForId(int firearmId) {
    return DropdownValues.getFirearmCodeById(firearmId);
  }

  List<T> _overrideListOrBase<T>(List<T>? overrideList, List<T> baseList) {
    if (overrideList == null || overrideList.isEmpty) {
      return baseList;
    }
    return overrideList;
  }

  List<T>? _overrideNullableListOrBase<T>(
    List<T>? overrideList,
    List<T>? baseList,
  ) {
    if (overrideList == null || overrideList.isEmpty) {
      return baseList;
    }
    return overrideList;
  }

  EventContent mergeContentWithOverride(
    EventOverride override, {
    EventContent? base,
  }) {
    final source = base ?? baseContent;
    final changes = override.changes;
    return EventContent(
      targets: _overrideListOrBase(changes.targets, source.targets),
      ammunition: changes.ammunition ?? source.ammunition,
      sights: _overrideListOrBase(changes.sights, source.sights),
      positions: _overrideListOrBase(changes.positions, source.positions),
      readyPositions: _overrideListOrBase(
        changes.readyPositions,
        source.readyPositions,
      ),
      rangeCommands: _overrideListOrBase(
        changes.rangeCommands,
        source.rangeCommands,
      ),
      notes: changes.notes ?? source.notes,
      ties: changes.ties ?? source.ties,
      proceduralPenalties:
          changes.proceduralPenalties ?? source.proceduralPenalties,
      classifications: _overrideNullableListOrBase(
        changes.classifications,
        source.classifications,
      ),
      targetPositions: _overrideNullableListOrBase(
        changes.targetPositions,
        source.targetPositions,
      ),
      courseOfFire: changes.courseOfFire ?? source.courseOfFire,
      sighters: _overrideNullableListOrBase(changes.sighters, source.sighters),
      practices: _overrideListOrBase(changes.practices, source.practices),
      targetIds: _overrideNullableListOrBase(
        changes.targetIds,
        source.targetIds,
      ),
      generalNotes: changes.generalNotes ?? source.generalNotes,
      scoring: changes.scoring ?? source.scoring,
      loading: changes.loading ?? source.loading,
      magazine: _overrideNullableListOrBase(changes.magazine, source.magazine),
      reloading: changes.reloading ?? source.reloading,
      equipment: changes.equipment ?? source.equipment,
      rangeEquipment: changes.rangeEquipment ?? source.rangeEquipment,
      changingPosition: changes.changingPosition ?? source.changingPosition,
    );
  }
}
