import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/import_data.dart';

/// Service to handle checking for and downloading data updates from Firebase
/// This service works with the existing DataImporter to provide version-aware updates
class DataSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DataImporter _dataImporter = DataImporter();
  
  static const String metadataCollection = 'metadata';
  static const String localVersionKey = 'local_data_version';

  /// Check if there's a new version available on Firebase
  /// Returns true if an update is available
  Future<bool> isUpdateAvailable() async {
    try {
      // Get the remote version from Firebase
      final remoteVersion = await _getRemoteVersion();
      
      if (remoteVersion == null) {
        print('No remote version found - first time setup may be needed');
        return false;
      }
      
      // Get the local version from Hive
      final localVersion = await _getLocalVersion();
      
      print('Local version: $localVersion, Remote version: $remoteVersion');
      
      // Check if remote is newer
      return remoteVersion > localVersion;
    } catch (e) {
      print('Error checking for updates: $e');
      return false;
    }
  }

  /// Get the current data version from Firebase
  Future<int?> _getRemoteVersion() async {
    try {
      final doc = await _firestore
          .collection(metadataCollection)
          .doc('data_version')
          .get();
      
      if (doc.exists) {
        return doc.data()?['version'] as int?;
      }
      return null;
    } catch (e) {
      print('Error getting remote version: $e');
      return null;
    }
  }

  /// Get the local data version stored in Hive
  Future<int> _getLocalVersion() async {
    try {
      final box = await Hive.openBox('app_metadata');
      return box.get(localVersionKey, defaultValue: 0);
    } catch (e) {
      print('Error getting local version: $e');
      return 0;
    }
  }

  /// Save the local data version to Hive
  Future<void> _saveLocalVersion(int version) async {
    try {
      final box = await Hive.openBox('app_metadata');
      await box.put(localVersionKey, version);
      print('Local version updated to: $version');
    } catch (e) {
      print('Error saving local version: $e');
    }
  }

  /// Download all data from Firebase and replace local Hive data
  /// Uses the existing DataImporter to perform the actual download
  /// Returns a map with the count of downloaded items
  Future<Map<String, int>> downloadAndReplaceData() async {
    try {
      // Use the existing DataImporter to download all data
      final results = await _dataImporter.importAllData();
      
      // Update local version to match remote
      final remoteVersion = await _getRemoteVersion();
      if (remoteVersion != null) {
        await _saveLocalVersion(remoteVersion);
      }
      
      print('Successfully downloaded and updated data');
      return results;
    } catch (e) {
      print('Error downloading data: $e');
      rethrow;
    }
  }

  /// Get the current local version number
  Future<int> getCurrentVersion() async {
    return await _getLocalVersion();
  }

  /// Get the current remote version number
  Future<int?> getRemoteVersionNumber() async {
    return await _getRemoteVersion();
  }

  /// Force a version sync (useful for troubleshooting)
  Future<void> forceVersionSync() async {
    final remoteVersion = await _getRemoteVersion();
    if (remoteVersion != null) {
      await _saveLocalVersion(remoteVersion);
    }
  }
}
