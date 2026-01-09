import 'package:hive/hive.dart';

part 'ready_position.g.dart';

@HiveType(typeId: 109)
class ReadyPosition extends HiveObject {
  @HiveField(0)
  String? text; // Optional - ready position description

  @HiveField(1)
  String? title; // Optional - ready position title

  ReadyPosition({
    this.text,
    this.title,
  });
}
