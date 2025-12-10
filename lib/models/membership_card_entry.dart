import 'package:hive/hive.dart';

part 'membership_card_entry.g.dart'; // optional if you want code generation later

@HiveType(typeId: 3)
class MembershipCardEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String memberName;

  @HiveField(2)
  String? cardNumber;

  @HiveField(3)
  String? frontImagePath;

  @HiveField(4)
  String? backImagePath;

  @HiveField(5)
  String? notes;

  MembershipCardEntry({
    required this.id,
    required this.memberName,
    this.cardNumber,
    this.frontImagePath,
    this.backImagePath,
    this.notes,
  });
}
