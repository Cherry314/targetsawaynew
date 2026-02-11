import 'package:hive/hive.dart';

part 'club.g.dart';

@HiveType(typeId: 133)
class Club extends HiveObject {
  @HiveField(0)
  String clubname;

  Club({
    required this.clubname,
  });
}
