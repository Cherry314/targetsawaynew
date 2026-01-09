import 'package:hive/hive.dart';

part 'changing_position.g.dart';

@HiveType(typeId: 125)
class ChangingPosition extends HiveObject {
  @HiveField(0)
  String? title; // Optional - changing position title

  @HiveField(1)
  String? text; // Optional - detailed changing position information

  ChangingPosition({
    this.title,
    this.text,
  });
}
