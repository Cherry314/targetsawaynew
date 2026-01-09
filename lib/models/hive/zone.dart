import 'package:hive/hive.dart';

part 'zone.g.dart';

@HiveType(typeId: 130)
class Zone {
  @HiveField(0)
  String text;

  @HiveField(1)
  String size;

  Zone({
    required this.text,
    required this.size,
  });
}
