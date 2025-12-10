import 'dart:io';
import 'dart:convert';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupRestore {
  // ----------------------------------------------------------
  // Helper: Return a REAL Download folder path
  // ----------------------------------------------------------
  static Future<Directory> _getRealDownloadsDirectory() async {
    if (Platform.isAndroid) {
      // The REAL visible Downloads folder
      final downloads = Directory('/storage/emulated/0/Download');
      if (!downloads.existsSync()) downloads.createSync(recursive: true);
      return downloads;
    } else {
      // iOS fallback (Apple does not allow public shared directories)
      final dir = await getDownloadsDirectory();
      return dir!;
    }
  }

  // ----------------------------------------------------------
  // BACKUP
  // ----------------------------------------------------------
  static Future<File> backupAppData({String? fileName}) async {
    final downloadDir = await _getRealDownloadsDirectory();

    final backupName = fileName ?? 'backup_${DateTime.now().millisecondsSinceEpoch}.zip';
    final zipFile = File('${downloadDir.path}/$backupName');

    final archive = Archive();

    // Hive directory (internal app folder)
    final appDir = await getApplicationDocumentsDirectory();
    final hiveFiles = Directory(appDir.path)
        .listSync()
        .where((f) => f.path.endsWith('.hive'));

    for (var file in hiveFiles) {
      final bytes = File(file.path).readAsBytesSync();
      archive.addFile(
        ArchiveFile(file.uri.pathSegments.last, bytes.length, bytes),
      );
    }

    // Shared Prefs
    final prefs = await SharedPreferences.getInstance();
    final prefsData = prefs.getKeys().fold<Map<String, dynamic>>({}, (map, k) {
      map[k] = prefs.get(k);
      return map;
    });

    final prefsBytes = utf8.encode(jsonEncode(prefsData));
    archive.addFile(
      ArchiveFile('shared_prefs.json', prefsBytes.length, prefsBytes),
    );

    // Write archive to ZIP
    final encoder = ZipEncoder();
    zipFile.writeAsBytesSync(encoder.encode(archive)!);

    return zipFile;
  }

  // ----------------------------------------------------------
  // RESTORE
  // ----------------------------------------------------------
  static Future<void> restoreAppData(File file) async {
    final bytes = file.readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);
    final appDir = await getApplicationDocumentsDirectory();

    for (final entry in archive) {
      if (entry.isFile) {
        final outFile = File('${appDir.path}/${entry.name}');
        outFile.createSync(recursive: true);
        outFile.writeAsBytesSync(entry.content);

        if (entry.name == 'shared_prefs.json') {
          final prefs = await SharedPreferences.getInstance();
          final jsonData = jsonDecode(utf8.decode(entry.content));

          for (var key in jsonData.keys) {
            final v = jsonData[key];
            if (v is int) {
              prefs.setInt(key, v);
            } else if (v is double) prefs.setDouble(key, v);
            else if (v is bool) prefs.setBool(key, v);
            else if (v is String) prefs.setString(key, v);
            else if (v is List<String>) prefs.setStringList(key, v);
          }
        }
      }
    }
  }
}
