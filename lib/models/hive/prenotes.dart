import 'package:hive/hive.dart';

part 'prenotes.g.dart';

@HiveType(typeId: 36)
class PreNotes extends HiveObject {
  @HiveField(0)
  String? title; // Optional - prenotes title

  @HiveField(1)
  String? text; // Optional - detailed prenotes

  PreNotes({
    this.title,
    this.text,
  });
}
