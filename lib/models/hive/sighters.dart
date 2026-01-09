import 'package:hive/hive.dart';

part 'sighters.g.dart';

@HiveType(typeId: 117)
class Sighters extends HiveObject {
  @HiveField(0)
  String text; // Sighters information text

  Sighters({
    required this.text,
  });
}