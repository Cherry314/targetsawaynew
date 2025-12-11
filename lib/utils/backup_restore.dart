// lib/utils/backup_restore.dart

import 'dart:io';
import 'dart:convert';
import 'package:archive/archive_io.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/score_entry.dart';
import '../models/firearm_entry.dart';
import '../models/membership_card_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      if (Hive.isBoxOpen('scores')) {
        final box = Hive.box<ScoreEntry>('scores');
        for (var entry in box.values) {
          if (entry.targetFilePath != null) {
            await _addFileToArchive(entry.targetFilePath!, archive, 'images/targets/full');
          }
          if (entry.thumbnailFilePath != null) {
            await _addFileToArchive(entry.thumbnailFilePath!, archive, 'images/targets/thumbs');
          }
        }
      }

      // FirearmEntry images
      if (Hive.isBoxOpen('firearms')) {
        final box = Hive.box<FirearmEntry>('firearms');
        for (var entry in box.values) {
          if (entry.imagePath != null) {
            await _addFileToArchive(entry.imagePath!, archive, 'images/armory');
          }
        }
      }

      // Membership images
      if (Hive.isBoxOpen('membership')) {
        final box = Hive.box<MembershipCardEntry>('membership');
        for (var entry in box.values) {
          if (entry.frontImagePath != null) {
            await _addFileToArchive(entry.frontImagePath!, archive, 'images/membership');
          }
          if (entry.backImagePath != null) {
            await _addFileToArchive(entry.backImagePath!, archive, 'images/membership');
          }
        }
      }
    }

    // ---------------------------
    // 4. Save ZIP to app-specific folder
    // ---------------------------
    final zipEncoder = ZipEncoder();
    final zipData = zipEncoder.encode(archive);

    final dateStr = DateFormat('ddMMMyyyy').format(DateTime.now());

    // App-specific folder for cross-platform compatibility
    Directory appDir;
    if (Platform.isAndroid) {
      appDir = (await getExternalStorageDirectory())!;
    } else {
      appDir = await getApplicationDocumentsDirectory();
    }

    final file = File('${appDir.path}/TargetsAway-$dateStr.zip');
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

      if (filePath.startsWith('data/')) {
        final jsonFile = File('${appDir.path}/${filePath}');
        await jsonFile.parent.create(recursive: true);
        await jsonFile.writeAsBytes(file.content as List<int>);
      } else if (filePath.startsWith('images/')) {
        final outFile = File('${appDir.path}/${filePath}');
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      }
    }

    // After extracting JSON files, restore Hive and SharedPreferences
    await _restoreHiveAndPrefs(appDir);
  }

  /// Restore Hive boxes and SharedPreferences from JSON
  static Future<void> _restoreHiveAndPrefs(Directory appDir) async {
    final hiveBoxNames = ['scores', 'firearms', 'membership_cards'];

    for (var boxName in hiveBoxNames) {
      final file = File('${appDir.path}/data/$boxName.json');
      if (await file.exists()) {
        final jsonStr = await file.readAsString();
        final List<dynamic> list = jsonDecode(jsonStr);
        final box = await Hive.openBox(boxName);
        await box.clear();
        for (var item in list) {
          if (boxName == 'scores') {
            await box.add(ScoreEntry.fromJson(Map<String, dynamic>.from(item)));
          } else if (boxName == 'firearms') {
            await box.add(FirearmEntry.fromJson(Map<String, dynamic>.from(item)));
          } else if (boxName == 'membership') {
            await box.add(MembershipCardEntry.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }
    }

    // SharedPreferences
    final spFile = File('${appDir.path}/data/shared_preferences.json');
    if (await spFile.exists()) {
      final jsonStr = await spFile.readAsString();
      final Map<String, dynamic> spMap = jsonDecode(jsonStr);
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      for (var key in spMap.keys) {
        final value = spMap[key];
        if (value is int) await prefs.setInt(key, value);
        else if (value is double) await prefs.setDouble(key, value);
        else if (value is bool) await prefs.setBool(key, value);
        else if (value is String) await prefs.setString(key, value);
        else if (value is List<String>) await prefs.setStringList(key, value);
      }
    }
  }
}
