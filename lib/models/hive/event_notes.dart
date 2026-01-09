import 'package:hive/hive.dart';

part 'event_notes.g.dart';

@HiveType(typeId: 116)
class EventNotes extends HiveObject {
  @HiveField(0)
  String text; // Notes information text

  EventNotes({
    required this.text,
  });
}