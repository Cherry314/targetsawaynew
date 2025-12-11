// lib/utils/storage_usage.dart
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/score_entry.dart';
import '../models/firearm_entry.dart';
import '../models/membership_card_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageUsage {
  /// Convert bytes to MB
  static double bytesToMb(int bytes) => bytes / 1024 / 1024;

  /// Hive database size
  static Future<int> hiveSizeBytes() async {
    final appDir = await getApplicationDocumentsDirectory();
    final hiveDir = Directory('${appDir.path}/hive_flutter'); // default Hive path
    if (!await hiveDir.exists()) return 0;
    int total = 0;
    await for (var file in hiveDir.list(recursive: true)) {
      if (file is File) total += await file.length();
    }
    return total;
  }

  /// SharedPreferences size (approx)
  static Future<int> sharedPrefsSizeBytes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int total = 0;
      prefs.getKeys().forEach((key) {
        final value = prefs.get(key);
        if (value != null) {
          total += value.toString().length;
        }
      });
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// ScoreEntry target images
  static Future<int> targetImagesSizeBytes() async {
    if (!Hive.isBoxOpen('scores')) return 0;
    final box = Hive.box<ScoreEntry>('scores');
    int total = 0;
    for (var entry in box.values) {
      if (entry.targetFilePath != null) {
        final f = File(entry.targetFilePath!);
        if (await f.exists()) total += await f.length();
      }
      if (entry.thumbnailFilePath != null) {
        final f = File(entry.thumbnailFilePath!);
        if (await f.exists()) total += await f.length();
      }
    }
    return total;
  }

  /// Armory images
  static Future<int> armoryImagesSizeBytes() async {
    if (!Hive.isBoxOpen('firearms')) return 0;
    final box = Hive.box<FirearmEntry>('firearms');
    int total = 0;
    for (var entry in box.values) {
      if (entry.imagePath != null) {
        final f = File(entry.imagePath!);
        if (await f.exists()) total += await f.length();
      }
    }
    return total;
  }

  /// Membership card images
  static Future<int> membershipImagesSizeBytes() async {
    if (!Hive.isBoxOpen('membership')) return 0;
    final box = Hive.box<MembershipCardEntry>('membership');
    int total = 0;
    for (var entry in box.values) {
      if (entry.frontImagePath != null) {
        final f = File(entry.frontImagePath!);
        if (await f.exists()) total += await f.length();
      }
      if (entry.backImagePath != null) {
        final f = File(entry.backImagePath!);
        if (await f.exists()) total += await f.length();
      }
    }
    return total;
  }

  /// Total storage usage in MB
  static Future<Map<String, double>> calculateAllSizesMb() async {
    final hive = bytesToMb(await hiveSizeBytes());
    final sp = bytesToMb(await sharedPrefsSizeBytes());
    final targets = bytesToMb(await targetImagesSizeBytes());
    final armory = bytesToMb(await armoryImagesSizeBytes());
    final membership = bytesToMb(await membershipImagesSizeBytes());

    return {
      'Hive DB': hive,
      'SharedPrefs': sp,
      'Targets': targets,
      'Armory': armory,
      'Membership': membership,
      'Total': hive + sp + targets + armory + membership,
    };
  }
}
