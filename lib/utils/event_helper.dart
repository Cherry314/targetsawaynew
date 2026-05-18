import 'package:targetsaway/models/hive/event.dart';
import 'package:targetsaway/models/hive/event_content.dart';

/// Returns the effective EventContent for the chosen numeric firearm ID.
EventContent getEffectiveContent(Event event, int firearmId) {
  return event.getContentForFirearmId(firearmId);
}
