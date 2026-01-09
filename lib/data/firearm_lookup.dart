import 'firearm_table.dart';
import 'package:targetsaway/models/hive/firearm.dart';

/// Create a Firearm Hive object from just an ID
Firearm createFirearmFromId(int id) {
  final info = firearmMasterTable.firstWhere(
        (f) => f.id == id,
    orElse: () => throw Exception('Unknown firearm ID: $id'),
  );

  // Return a Firearm object for Hive
  return Firearm(id: info.id, code: info.code, gunType: info.gunType);
}
