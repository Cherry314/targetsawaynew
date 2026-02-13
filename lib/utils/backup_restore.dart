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
import '../models/appointment_entry.dart';
import '../models/rounds_counter_entry.dart';
import '../models/comp_history_entry.dart';

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
      'appointments': Hive.box<AppointmentEntry>('appointments'),
      'rounds_counter': Hive.box<RoundsCounterEntry>('rounds_counter'),
      'comp_history': Hive.box<CompHistoryEntry>('comp_history'),
    };

    for (var entry in hiveBoxes.entries) {
      final boxName = entry.key;
      final box = entry.value;
      final list = box.values.map((e) {
        if (e is ScoreEntry) return e.toJson();
        if (e is FirearmEntry) return e.toJson();
        if (e is MembershipCardEntry) return e.toJson();
        if (e is AppointmentEntry) return e.toJson();
        if (e is RoundsCounterEntry) return e.toJson();
        if (e is CompHistoryEntry) return e.toJson();
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

    final dateStr = DateFormat('ddMMMyyyy_HHmm').format(DateTime.now());

    // ---------------------------
    // 5. Save to temporary directory first (for sharing)
    // ---------------------------
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/TargetsAway_Backup_$dateStr.zip');
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
    // 6. Restore Hive JSON & SharedPreferences
    // ---------------------------
    await _restoreHiveAndPrefs(appDir);
  }

  /// Restore Hive boxes & SharedPreferences safely
  static Future<void> _restoreHiveAndPrefs(Directory appDir) async {
    const boxNames = ['scores', 'firearms', 'membership_cards', 'appointments', 'rounds_counter', 'comp_history'];

    for (var boxName in boxNames) {
      final file = File('${appDir.path}/data/$boxName.json');
      if (!await file.exists()) continue;

      final jsonStr = await file.readAsString();
      final List<dynamic> list = jsonDecode(jsonStr);

      // Get the typed box (should already be open from main.dart)
      Box box;
      if (boxName == 'scores') {
        box = Hive.box<ScoreEntry>(boxName);
      } else if (boxName == 'firearms') {
        box = Hive.box<FirearmEntry>(boxName);
      } else if (boxName == 'membership_cards') {
        box = Hive.box<MembershipCardEntry>(boxName);
      } else if (boxName == 'appointments') {
        box = Hive.box<AppointmentEntry>(boxName);
      } else if (boxName == 'rounds_counter') {
        box = Hive.box<RoundsCounterEntry>(boxName);
      } else if (boxName == 'comp_history') {
        box = Hive.box<CompHistoryEntry>(boxName);
      } else {
        continue; // Skip unknown boxes
      }

      await box.clear();

      for (var item in list) {
        final map = Map<String, dynamic>.from(item);

        // Update image paths to point to restored locations
        if (boxName == 'scores') {
          _updateScoreImagePaths(map, appDir);
          box.add(ScoreEntry.fromJson(map));
        } else if (boxName == 'firearms') {
          _updateFirearmImagePath(map, appDir);
          box.add(FirearmEntry.fromJson(map));
        } else if (boxName == 'membership_cards') {
          _updateMembershipImagePaths(map, appDir);
          box.add(MembershipCardEntry.fromJson(map));
        } else if (boxName == 'appointments') {
          box.add(AppointmentEntry.fromJson(map));
        } else if (boxName == 'rounds_counter') {
          box.add(RoundsCounterEntry.fromJson(map));
        } else if (boxName == 'comp_history') {
          box.add(CompHistoryEntry.fromJson(map));
        }
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
      if (v is int) {
        prefs.setInt(key, v);
      } else if (v is double) {
        prefs.setDouble(key, v);
      } else if (v is bool) {
        prefs.setBool(key, v);
      } else if (v is String) {
        prefs.setString(key, v);
      } else if (v is List) {
        prefs.setStringList(key, List<String>.from(v));
      }
    }
  }

  /// Update ScoreEntry image paths to point to restored location
  static void _updateScoreImagePaths(Map<String, dynamic> map,
      Directory appDir) {
    if (map['targetFilePath'] != null) {
      final filename = map['targetFilePath']
          .toString()
          .split('/')
          .last
          .split('\\')
          .last;
      map['targetFilePath'] = '${appDir.path}/images/targets/full/$filename';
    }
    if (map['thumbnailFilePath'] != null) {
      final filename = map['thumbnailFilePath']
          .toString()
          .split('/')
          .last
          .split('\\')
          .last;
      map['thumbnailFilePath'] =
      '${appDir.path}/images/targets/thumbs/$filename';
    }
  }

  /// Update FirearmEntry image path to point to restored location
  static void _updateFirearmImagePath(Map<String, dynamic> map,
      Directory appDir) {
    if (map['imagePath'] != null) {
      final filename = map['imagePath']
          .toString()
          .split('/')
          .last
          .split('\\')
          .last;
      map['imagePath'] = '${appDir.path}/images/armory/$filename';
    }
  }

  /// Update MembershipCardEntry image paths to point to restored location
  static void _updateMembershipImagePaths(Map<String, dynamic> map,
      Directory appDir) {
    if (map['frontImagePath'] != null) {
      final filename = map['frontImagePath']
          .toString()
          .split('/')
          .last
          .split('\\')
          .last;
      map['frontImagePath'] = '${appDir.path}/images/membership/$filename';
    }
    if (map['backImagePath'] != null) {
      final filename = map['backImagePath']
          .toString()
          .split('/')
          .last
          .split('\\')
          .last;
      map['backImagePath'] = '${appDir.path}/images/membership/$filename';
    }
  }
}
