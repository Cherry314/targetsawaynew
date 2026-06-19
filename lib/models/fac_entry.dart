// lib/models/fac_entry.dart
import 'package:hive/hive.dart';

part 'fac_entry.g.dart';

@HiveType(typeId: 137)
class FacEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String? certificateNumber;

  @HiveField(2)
  DateTime? validFrom;

  @HiveField(3)
  DateTime? validTo;

  @HiveField(4)
  List<FacFirearmAllowance> firearms;

  @HiveField(5)
  List<FacAmmunitionAllowance> ammunition;

  @HiveField(6)
  List<FacFirearmOwned> firearmsOwned;

  FacEntry({
    required this.id,
    this.certificateNumber,
    this.validFrom,
    this.validTo,
    List<FacFirearmAllowance>? firearms,
    List<FacAmmunitionAllowance>? ammunition,
    List<FacFirearmOwned>? firearmsOwned,
  })  : firearms = firearms ?? [],
        ammunition = ammunition ?? [],
        firearmsOwned = firearmsOwned ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'certificateNumber': certificateNumber,
        'validFrom': validFrom?.toIso8601String(),
        'validTo': validTo?.toIso8601String(),
        'firearms': firearms.map((entry) => entry.toJson()).toList(),
        'ammunition': ammunition.map((entry) => entry.toJson()).toList(),
        'firearmsOwned': firearmsOwned.map((entry) => entry.toJson()).toList(),
      };

  factory FacEntry.fromJson(Map<String, dynamic> json) => FacEntry(
        id: json['id'],
        certificateNumber: json['certificateNumber'],
        validFrom: json['validFrom'] == null
            ? null
            : DateTime.tryParse(json['validFrom']),
        validTo:
            json['validTo'] == null ? null : DateTime.tryParse(json['validTo']),
        firearms: (json['firearms'] as List<dynamic>? ?? [])
            .map((entry) => FacFirearmAllowance.fromJson(
                  Map<String, dynamic>.from(entry),
                ))
            .toList(),
        ammunition: (json['ammunition'] as List<dynamic>? ?? [])
            .map((entry) => FacAmmunitionAllowance.fromJson(
                  Map<String, dynamic>.from(entry),
                ))
            .toList(),
        firearmsOwned: (json['firearmsOwned'] as List<dynamic>? ?? [])
            .map((entry) => FacFirearmOwned.fromJson(
                  Map<String, dynamic>.from(entry),
                ))
            .toList(),
      );
}

@HiveType(typeId: 138)
class FacFirearmAllowance extends HiveObject {
  @HiveField(0)
  String? calibre;

  @HiveField(1)
  String? type;

  @HiveField(2)
  String? action;

  @HiveField(3)
  int? qty;

  FacFirearmAllowance({
    this.calibre,
    this.type,
    this.action,
    this.qty,
  });

  Map<String, dynamic> toJson() => {
        'calibre': calibre,
        'type': type,
        'action': action,
        'qty': qty,
      };

  factory FacFirearmAllowance.fromJson(Map<String, dynamic> json) =>
      FacFirearmAllowance(
        calibre: json['calibre'],
        type: json['type'],
        action: json['action'],
        qty: json['qty'],
      );
}

@HiveType(typeId: 139)
class FacAmmunitionAllowance extends HiveObject {
  @HiveField(0)
  String? calibre;

  @HiveField(1)
  int? quantity;

  FacAmmunitionAllowance({
    this.calibre,
    this.quantity,
  });

  Map<String, dynamic> toJson() => {
        'calibre': calibre,
        'quantity': quantity,
      };

  factory FacAmmunitionAllowance.fromJson(Map<String, dynamic> json) =>
      FacAmmunitionAllowance(
        calibre: json['calibre'],
        quantity: json['quantity'],
      );
}

@HiveType(typeId: 140)
class FacFirearmOwned extends HiveObject {
  @HiveField(0)
  String? calibre;

  @HiveField(1)
  String? makersName;

  @HiveField(2)
  String? type;

  @HiveField(3)
  String? action;

  @HiveField(4)
  String? identification;

  FacFirearmOwned({
    this.calibre,
    this.makersName,
    this.type,
    this.action,
    this.identification,
  });

  Map<String, dynamic> toJson() => {
        'calibre': calibre,
        'makersName': makersName,
        'type': type,
        'action': action,
        'identification': identification,
      };

  factory FacFirearmOwned.fromJson(Map<String, dynamic> json) =>
      FacFirearmOwned(
        calibre: json['calibre'],
        makersName: json['makersName'],
        type: json['type'],
        action: json['action'],
        identification: json['identification'],
      );
}
