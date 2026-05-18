import 'package:hive/hive.dart';
import 'override_content.dart';

part 'event_override.g.dart';

@HiveType(typeId: 102)
class EventOverride {
  @HiveField(0)
  List<int> firearmIds; // Numeric firearm IDs.

  @HiveField(1)
  OverrideContent changes;

  @HiveField(2)
  List<String> firearmCodes; // Firearm codes, e.g. GRSB/GRCF, for code-based imports.

  EventOverride({
    required this.firearmIds,
    required this.changes,
    List<String>? firearmCodes,
  }) : firearmCodes = firearmCodes ?? [];
}
