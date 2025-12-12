// lib/utils/backup_restore.dart

import 'dart:io';
import 'dart:convert';
import 'package:archive/archive_io.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/score_entry.dart';
import '../models/firearm_entry.dart';
import '../models/membership_card_entry.dart';

class BackupRestore {
  /// Backup app data (Hive as JSON + SharedPrefs + optionally images)
  static Future<File> backupAppData({bool includeImages = true}) async {
    final archive = Archive();

    // ---------------------------
    // 1. Export Hive boxes to JSON
    // ---------------------------
    final hiveBoxes = {
      'scores': Hive.box<ScoreEntry>('scores'),
      'firearms': Hive.box<FirearmEntry>('firearms'),
      'membership_cards': Hive.box<MembershipCardEntry>('membership_cards'),
    };

    for (var entry in hiveBoxes.entries) {
      final boxName = entry.key;
      final box = entry.value;
      final list = box.values.map((e) {
        if (e is ScoreEntry) return e.toJson();
        if (e is FirearmEntry) return e.toJson();
        if (e is MembershipCardEntry) return e.toJson();
        return {};
      }).toList();

      final jsonStr = jsonEncode(list);
      final bytes = utf8.encode(jsonStr);
      archive.addFile(ArchiveFile('data/$boxName.json', bytes.length, bytes));
    }

    // ---------------------------
    // 2. SharedPreferences
    // ---------------------------
    final prefs = await SharedPreferences.getInstance();
    final spMap = <String, dynamic>{};
    for (var key in prefs.getKeys()) {
      spMap[key] = prefs.get(key);
    }
    final spJson = utf8.encode(jsonEncode(spMap));
    archive.addFile(ArchiveFile('data/shared_preferences.json', spJson.length, spJson));

    // ---------------------------
    // 3. Images from Hive entries
    // ---------------------------
    if (includeImages) {
      // ScoreEntry images
      final scoreBox = Hive.box<ScoreEntry>('scores');
      for (var entry in scoreBox.values) {
        if (entry.targetFilePath != null) {
          await _addFileToArchive(entry.targetFilePath!, archive, 'images/targets/full');
        }
        if (entry.thumbnailFilePath != null) {
          await _addFileToArchive(entry.thumbnailFilePath!, archive, 'images/targets/thumbs');
        }
      }

      // FirearmEntry images
      final firearmBox = Hive.box<FirearmEntry>('firearms');
      for (var entry in firearmBox.values) {
        if (entry.imagePath != null) {
          await _addFileToArchive(entry.imagePath!, archive, 'images/armory');
        }
      }

      // Membership images
      final membershipBox = Hive.box<MembershipCardEntry>('membership_cards');
      for (var entry in membershipBox.values) {
        if (entry.frontImagePath != null) {
          await _addFileToArchive(entry.frontImagePath!, archive, 'images/membership');
        }
        if (entry.backImagePath != null) {
          await _addFileToArchive(entry.backImagePath!, archive, 'images/membership');
        }
      }
    }

    // ---------------------------
    // 4. Encode ZIP
    // ---------------------------
    final zipEncoder = ZipEncoder();
    final zipData = zipEncoder.encode(archive);

    final dateStr = DateFormat('ddMMMyyyy').format(DateTime.now());

    // ---------------------------
    // 5. Save to Downloads (Android) or App folder (iOS)
    // ---------------------------
    Directory saveDir;
    if (Platform.isAndroid) {
      saveDir = (await getExternalStorageDirectories(type: StorageDirectory.downloads))!.first;
    } else {
      saveDir = await getApplicationDocumentsDirectory();
    }

    final file = File('${saveDir.path}/TargetsAway-$dateStr.zip');
    await file.writeAsBytes(zipData);

    return file;
  }

  /// Helper: add a file to the archive with a relative folder
  static Future<void> _addFileToArchive(String path, Archive archive, String folder) async {
    final f = File(path);
    if (await f.exists()) {
      final bytes = await f.readAsBytes();
      final name = '$folder/${f.uri.pathSegments.last}';
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }
  }

  /// Restore app data from ZIP
  static Future<void> restoreAppData(File zipFile) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final appDir = await getApplicationDocumentsDirectory();

    for (var file in archive) {
      final filePath = file.name;
      if (filePath.startsWith('data/') || filePath.startsWith('images/')) {
        final outFile = File('${appDir.path}/$filePath');
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      }
    }

    // ---------------------------
    // 6. Close boxes before restore
    // ---------------------------
    for (var boxName in ['scores', 'firearms', 'membership_cards']) {
      if (Hive.isBoxOpen(boxName)) await Hive.box(boxName).close();
    }

    // ---------------------------
    // 7. Re-open boxes
    // ---------------------------
    await Hive.openBox<ScoreEntry>('scores');
    await Hive.openBox<FirearmEntry>('firearms');
    await Hive.openBox<MembershipCardEntry>('membership_cards');

    // ---------------------------
    // 8. Restore Hive JSON & SharedPreferences
    // ---------------------------
    await _restoreHiveAndPrefs(appDir);
  }

  /// Restore Hive boxes & SharedPreferences safely
  static Future<void> _restoreHiveAndPrefs(Directory appDir) async {
    const boxNames = ['scores', 'firearms', 'membership_cards'];

    for (var boxName in boxNames) {
      final file = File('${appDir.path}/data/$boxName.json');
      if (!await file.exists()) continue;

      final jsonStr = await file.readAsString();
      final List<dynamic> list = jsonDecode(jsonStr);

      final box = Hive.box(boxName); // already open
      await box.clear();

      for (var item in list) {
        final map = Map<String, dynamic>.from(item);

        if (boxName == 'scores') box.add(ScoreEntry.fromJson(map));
        else if (boxName == 'firearms') box.add(FirearmEntry.fromJson(map));
        else if (boxName == 'membership_cards') box.add(MembershipCardEntry.fromJson(map));
      }
    }

    // SharedPreferences
    final spFile = File('${appDir.path}/data/shared_preferences.json');
    if (!await spFile.exists()) return;

    final spJson = await spFile.readAsString();
    final Map<String, dynamic> spMap = jsonDecode(spJson);

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    for (var key in spMap.keys) {
      final v = spMap[key];
      if (v is int) prefs.setInt(key, v);
      else if (v is double) prefs.setDouble(key, v);
      else if (v is bool) prefs.setBool(key, v);
      else if (v is String) prefs.setString(key, v);
      else if (v is List) prefs.setStringList(key, List<String>.from(v));
    }
  }
}
