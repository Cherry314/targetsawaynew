import 'package:hive/hive.dart';

part 'firearm.g.dart';

@HiveType(typeId: 104)
class Firearm {
  @HiveField(0)
  int id;

  @HiveField(1)
  String code;

  @HiveField(2)
  String gunType;

  Firearm({
    required this.id,
    required this.code,
    required this.gunType,
  });
}
