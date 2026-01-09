import 'package:hive/hive.dart';
import 'override_content.dart';

part 'event_override.g.dart';

@HiveType(typeId: 102)
class EventOverride {
  @HiveField(0)
  List<int> firearmIds; // Changed to support multiple firearm IDs

  @HiveField(1)
  OverrideContent changes;

  EventOverride({
    required this.firearmIds,
    required this.changes,
  });
}
