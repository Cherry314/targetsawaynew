import 'package:hive/hive.dart';

part 'notes.g.dart';

@HiveType(typeId: 118)
class Notes extends HiveObject {
  @HiveField(0)
  String? title; // Optional - notes title

  @HiveField(1)
  String? text; // Optional - detailed notes

  Notes({
    this.title,
    this.text,
  });
}
