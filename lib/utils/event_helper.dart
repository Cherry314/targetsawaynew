import 'package:targetsaway/models/hive/event.dart';
import 'package:targetsaway/models/hive/event_content.dart';
import 'package:targetsaway/models/hive/event_override.dart';
import 'firearm_groups.dart';

/// Returns the effective EventContent for the chosen firearm.
/// Checks direct override first, then gun type group override, else base content.
EventContent getEffectiveContent(Event event, int firearmId) {
  EventOverride? override;

  // 1️⃣ Direct override for firearm
  try {
    override = event.overrides.firstWhere((o) => o.firearmIds.contains(firearmId));
  } catch (e) {
    override = null; // no direct override found
  }

  // 2️⃣ If no direct override, check for group overrides
  if (override == null) {
    for (var o in event.overrides) {
      gunTypeGroups.forEach((groupName, firearmIds) {
        if (firearmIds.contains(firearmId) && o.firearmIds.contains(groupName.hashCode)) {
          override = o;
        }
      });
    }
  }

  // 3️⃣ If still null, use base content
  if (override == null) {
    return event.baseContent;
  }

  // Merge base + override (override is guaranteed non-null here)
  final changes = override!.changes;
  return EventContent(
    targets: changes.targets ?? event.baseContent.targets,
    sights: changes.sights ?? event.baseContent.sights,
    positions: changes.positions ?? event.baseContent.positions,
    readyPositions: changes.readyPositions ?? event.baseContent.readyPositions,
    rangeCommands: changes.rangeCommands ?? event.baseContent.rangeCommands,
    notes: changes.notes ?? event.baseContent.notes,
    ties: changes.ties ?? event.baseContent.ties,
    proceduralPenalties:
    changes.proceduralPenalties ?? event.baseContent.proceduralPenalties,
    classifications: changes.classifications ?? event.baseContent.classifications,
    targetPositions:
    changes.targetPositions ?? event.baseContent.targetPositions,
    courseOfFire: changes.courseOfFire ?? event.baseContent.courseOfFire,
    sighters: changes.sighters ?? event.baseContent.sighters,
    practices: changes.practices ?? event.baseContent.practices,
    targetIds: changes.targetIds ?? event.baseContent.targetIds,
  );
}
