// lib/data/firearm_table.dart
class FirearmInfo {
  final int id;
  final String code;
  final String gunType;

  const FirearmInfo({
    required this.id,
    required this.code,
    required this.gunType,
  });
}

/// Master table of all firearms
const List<FirearmInfo> firearmMasterTable = [
  FirearmInfo(id: 1, code: 'GRSB', gunType: 'Gallery Rifle & Pistol'),
  FirearmInfo(id: 2, code: 'GRCF', gunType: 'Gallery Rifle & Pistol'),
  FirearmInfo(id: 3, code: 'GRCF Open', gunType: 'Gallery Rifle & Pistol'),
  FirearmInfo(id: 4, code: 'GRCF Classic', gunType: 'Gallery Rifle & Pistol'),
  FirearmInfo(id: 7, code: 'GRCF Issued', gunType: 'Gallery Rifle & Pistol'),
  FirearmInfo(id: 21, code: 'LBP', gunType: 'Gallery Rifle & Pistol'),
  FirearmInfo(id: 22, code: 'LBR', gunType: 'Gallery Rifle & Pistol'),
  FirearmInfo(id: 23, code: 'AP', gunType: 'Gallery Rifle & Pistol'),
  FirearmInfo(id: 24, code: 'LBP - Iron Sight', gunType: 'Gallery Rifle & Pistol'),
  FirearmInfo(id: 25, code: 'LBR - Iron Sight', gunType: 'Gallery Rifle & Pistol'),
  FirearmInfo(id: 30, code: 'SGSV', gunType: 'Shotgun'),
  FirearmInfo(id: 31, code: 'SGMB', gunType: 'Shotgun'),
  FirearmInfo(id: 34, code: 'SG', gunType: 'Shotgun'),
  FirearmInfo(id: 35, code: 'SGM', gunType: 'Shotgun'),
  FirearmInfo(id: 36, code: 'SGSA', gunType: 'Shotgun'),
  FirearmInfo(id: 37, code: 'SGC', gunType: 'Shotgun'),
  FirearmInfo(id: 41, code: 'MLP', gunType: 'Muzzle Loading'),
  FirearmInfo(id: 42, code: 'MLR', gunType: 'Muzzle Loading'),
  FirearmInfo(id: 62, code: 'Hunter Classic', gunType: 'Long Range Pistol'),
  FirearmInfo(id: 63, code: 'Free Pistol A', gunType: 'Long Range Pistol'),
  FirearmInfo(id: 65, code: 'Production Free Pistol A', gunType: 'Long Range Pistol'),
  FirearmInfo(id: 66, code: 'Production Free Pistol B', gunType: 'Long Range Pistol'),
  FirearmInfo(id: 67, code: 'Allcomer Revolver', gunType: 'Long Range Pistol'),
  FirearmInfo(id: 68, code: 'Free Pistol', gunType: 'Long Range Pistol'),
  FirearmInfo(id: 69, code: 'Production Free Revolver', gunType: 'Long Range Pistol'),
  FirearmInfo(id: 80, code: 'Any Fullbore Rifle', gunType: 'Fullbore Rifle'),
  FirearmInfo(id: 81, code: 'SR(a) Pre-1955', gunType: 'Fullbore Rifle'),
  FirearmInfo(id: 82, code: 'SR(b) Pre-1955', gunType: 'Fullbore Rifle'),
  FirearmInfo(id: 83, code: 'SR Open Pre-1955', gunType: 'Fullbore Rifle'),
  FirearmInfo(id: 84, code: 'Bolt Action Centerfire Rifle', gunType: 'Fullbore Rifle'),
  FirearmInfo(id: 85, code: 'Sporting Rifle', gunType: 'Fullbore Rifle'),
  FirearmInfo(id: 86, code: 'F Class', gunType: 'Fullbore Rifle'),
  FirearmInfo(id: 87, code: 'Black Powder Cartridge', gunType: 'Fullbore Rifle'),
  FirearmInfo(id: 88, code: 'FTR', gunType: 'Fullbore Rifle'),
  FirearmInfo(id: 90, code: 'Issued Sniper Rifle', gunType: 'Fullbore Rifle'),
  FirearmInfo(id: 91, code: 'SR Post 1955 Iron Sight', gunType: 'Fullbore Rifle'),
  FirearmInfo(id: 92, code: 'SR Post 1955 Service Optic', gunType: 'Fullbore Rifle'),
  FirearmInfo(id: 93, code: 'SR Post 1955 Practical Optic', gunType: 'Fullbore Rifle'),
];
