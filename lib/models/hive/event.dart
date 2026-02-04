import 'package:hive/hive.dart';
import 'event_content.dart';
import 'event_override.dart';
import 'firearm.dart';
import 'prenotes.dart';

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

  Event({
    required this.eventNumber,
    required this.name,
    required this.applicableFirearmIds,
    this.prenotes,
    required this.baseContent,
    required this.overrides,
  });

  /// Get EventContent for a specific firearm
  EventContent getContentForFirearm(Firearm firearm) {
    EventOverride? override;
    try {
      override = overrides.firstWhere(
        (o) => o.firearmIds.contains(firearm.id),
      );
    } catch (e) {
      // No override found, return base content
      return baseContent;
    }

    // Merge base content with override
    final changes = override.changes;
    return EventContent(
      targets: changes.targets ?? baseContent.targets,
      ammunition: changes.ammunition ?? baseContent.ammunition,
      sights: changes.sights ?? baseContent.sights,
      positions: changes.positions ?? baseContent.positions,
      readyPositions: changes.readyPositions ?? baseContent.readyPositions,
      rangeCommands: changes.rangeCommands ?? baseContent.rangeCommands,
      notes: changes.notes ?? baseContent.notes,
      ties: changes.ties ?? baseContent.ties,
      proceduralPenalties: changes.proceduralPenalties ?? baseContent.proceduralPenalties,
      classifications: changes.classifications ?? baseContent.classifications,
      targetPositions: changes.targetPositions ?? baseContent.targetPositions,
      courseOfFire: changes.courseOfFire ?? baseContent.courseOfFire,
      sighters: changes.sighters ?? baseContent.sighters,
      practices: changes.practices ?? baseContent.practices,
      targetIds: changes.targetIds ?? baseContent.targetIds,
      generalNotes: changes.generalNotes ?? baseContent.generalNotes,
      scoring: changes.scoring ?? baseContent.scoring,
      loading: changes.loading ?? baseContent.loading,
      reloading: changes.reloading ?? baseContent.reloading,
      equipment: changes.equipment ?? baseContent.equipment,
      rangeEquipment: changes.rangeEquipment ?? baseContent.rangeEquipment,
      changingPosition: changes.changingPosition ?? baseContent.changingPosition,
    );
  }
}
