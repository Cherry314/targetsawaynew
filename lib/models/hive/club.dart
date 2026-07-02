import 'package:hive/hive.dart';

part 'club.g.dart';

@HiveType(typeId: 133)
class Club extends HiveObject {
  @HiveField(0)
  String clubname;

  @HiveField(1)
  DateTime? renewalDate;

  Club({required this.clubname, this.renewalDate});
}
