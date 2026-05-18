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
    final override = getOverrideForFirearmId(firearmId);
    if (override == null) {
      return baseContent;
    }

    return mergeContentWithOverride(override);
  }

  /// Get EventContent for a specific firearm.
  EventContent getContentForFirearm(Firearm firearm) {
    final override = getOverrideForFirearm(firearm);
    if (override == null) {
      return baseContent;
    }

    return mergeContentWithOverride(override);
  }

  /// Get the override for a numeric firearm ID.
  EventOverride? getOverrideForFirearmId(int firearmId) {
    for (final override in overrides) {
      if (override.firearmIds.contains(firearmId)) {
        return override;
      }
    }
    return null;
  }

  /// Get the override for a firearm by numeric ID or code.
  EventOverride? getOverrideForFirearm(Firearm firearm) {
    final idOverride = getOverrideForFirearmId(firearm.id);
    if (idOverride != null) {
      return idOverride;
    }

    final firearmCode = firearm.code.trim().toLowerCase();
    for (final override in overrides) {
      final overrideCodes = {
        ...override.firearmCodes.map((code) => code.trim().toLowerCase()),
        ...override.firearmIds
            .map(_firearmCodeForId)
            .whereType<String>()
            .map((code) => code.trim().toLowerCase()),
      };
      final matchesCode =
          firearmCode.isNotEmpty && overrideCodes.contains(firearmCode);
      if (matchesCode) {
        return override;
      }
    }
    return null;
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

  EventContent mergeContentWithOverride(EventOverride override) {
    final changes = override.changes;
    return EventContent(
      targets: _overrideListOrBase(changes.targets, baseContent.targets),
      ammunition: changes.ammunition ?? baseContent.ammunition,
      sights: _overrideListOrBase(changes.sights, baseContent.sights),
      positions: _overrideListOrBase(changes.positions, baseContent.positions),
      readyPositions: _overrideListOrBase(
        changes.readyPositions,
        baseContent.readyPositions,
      ),
      rangeCommands: _overrideListOrBase(
        changes.rangeCommands,
        baseContent.rangeCommands,
      ),
      notes: changes.notes ?? baseContent.notes,
      ties: changes.ties ?? baseContent.ties,
      proceduralPenalties:
          changes.proceduralPenalties ?? baseContent.proceduralPenalties,
      classifications: changes.classifications ?? baseContent.classifications,
      targetPositions: changes.targetPositions ?? baseContent.targetPositions,
      courseOfFire: changes.courseOfFire ?? baseContent.courseOfFire,
      sighters: changes.sighters ?? baseContent.sighters,
      practices: _overrideListOrBase(changes.practices, baseContent.practices),
      targetIds: changes.targetIds ?? baseContent.targetIds,
      generalNotes: changes.generalNotes ?? baseContent.generalNotes,
      scoring: changes.scoring ?? baseContent.scoring,
      loading: changes.loading ?? baseContent.loading,
      magazine: changes.magazine ?? baseContent.magazine,
      reloading: changes.reloading ?? baseContent.reloading,
      equipment: changes.equipment ?? baseContent.equipment,
      rangeEquipment: changes.rangeEquipment ?? baseContent.rangeEquipment,
      changingPosition:
          changes.changingPosition ?? baseContent.changingPosition,
    );
  }
}
