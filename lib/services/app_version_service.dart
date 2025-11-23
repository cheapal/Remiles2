import 'package:package_info_plus/package_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/firebase_service.dart';
import '../core/app_config.dart';

/// Service to check app version and maintenance mode from Firestore
class AppVersionService {
  static const String _settingsCollection = 'app_settings';
  static const String _settingsDocument = 'settings';
  
  /// Check if app update is required
  /// Returns true if current version is less than minimum required version
  static Future<bool> isUpdateRequired() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
      
      if (AppConfig.enableDebugLogging) {
        print('AppVersionService: Current version: $currentVersion+$currentBuildNumber');
      }
      
      // Get settings from Firestore
      final settingsDoc = await FirebaseService.firestore
          .collection(_settingsCollection)
          .doc(_settingsDocument)
          .get();
      
      if (!settingsDoc.exists) {
        if (AppConfig.enableDebugLogging) {
          print('AppVersionService: Settings document not found, allowing app to continue');
        }
        return false; // If settings don't exist, allow app to continue
      }
      
      final data = settingsDoc.data();
      if (data == null) {
        return false;
      }
      
      // Get minimum required version
      final minVersion = data['minAppVersion'] as String?;
      // Handle different number types from Firestore (int, num, int64, etc.)
      int? minBuildNumber;
      final buildNumberValue = data['minBuildNumber'];
      if (buildNumberValue != null) {
        if (buildNumberValue is int) {
          minBuildNumber = buildNumberValue;
        } else if (buildNumberValue is num) {
          minBuildNumber = buildNumberValue.toInt();
        } else if (buildNumberValue is String) {
          minBuildNumber = int.tryParse(buildNumberValue);
        }
      }
      
      if (AppConfig.enableDebugLogging) {
        print('AppVersionService: Current version: $currentVersion+$currentBuildNumber');
        print('AppVersionService: Min version: $minVersion, Min build: $minBuildNumber');
      }
      
      if (minVersion == null && minBuildNumber == null) {
        if (AppConfig.enableDebugLogging) {
          print('AppVersionService: No minimum version specified, allowing app to continue');
        }
        return false; // If no minimum version is set, allow app to continue
      }
      
      // Compare versions
      if (minVersion != null && minVersion.trim().isNotEmpty) {
        final isVersionOutdated = _compareVersions(currentVersion, minVersion) < 0;
        if (AppConfig.enableDebugLogging) {
          print('AppVersionService: Version comparison - Current: $currentVersion, Required: $minVersion, Outdated: $isVersionOutdated');
        }
        if (isVersionOutdated) {
          if (AppConfig.enableDebugLogging) {
            print('AppVersionService: Version outdated. Current: $currentVersion, Required: $minVersion');
          }
          return true;
        }
      }
      
      // Compare build numbers (more precise)
      if (minBuildNumber != null) {
        if (AppConfig.enableDebugLogging) {
          print('AppVersionService: Build number comparison - Current: $currentBuildNumber, Required: $minBuildNumber, Outdated: ${currentBuildNumber < minBuildNumber}');
        }
        if (currentBuildNumber < minBuildNumber) {
          if (AppConfig.enableDebugLogging) {
            print('AppVersionService: Build number outdated. Current: $currentBuildNumber, Required: $minBuildNumber');
          }
          return true;
        }
      }
      
      if (AppConfig.enableDebugLogging) {
        print('AppVersionService: App version is up to date');
      }
      return false;
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('AppVersionService: Error checking update requirement: $e');
      }
      // On error, allow app to continue (fail gracefully)
      return false;
    }
  }
  
  /// Check if app is in maintenance mode
  static Future<bool> isMaintenanceMode() async {
    try {
      final settingsDoc = await FirebaseService.firestore
          .collection(_settingsCollection)
          .doc(_settingsDocument)
          .get();
      
      if (!settingsDoc.exists) {
        if (AppConfig.enableDebugLogging) {
          print('AppVersionService: Settings document not found, maintenance mode: false');
        }
        return false;
      }
      
      final data = settingsDoc.data();
      if (data == null) {
        return false;
      }
      
      final isMaintenance = data['maintenanceMode'] as bool? ?? false;
      
      if (AppConfig.enableDebugLogging) {
        print('AppVersionService: Maintenance mode: $isMaintenance');
      }
      
      return isMaintenance;
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('AppVersionService: Error checking maintenance mode: $e');
      }
      // On error, allow app to continue (fail gracefully)
      return false;
    }
  }
  
  /// Get maintenance message from Firestore
  static Future<String> getMaintenanceMessage() async {
    try {
      final settingsDoc = await FirebaseService.firestore
          .collection(_settingsCollection)
          .doc(_settingsDocument)
          .get();
      
      if (!settingsDoc.exists) {
        return 'The app is currently under maintenance. Please check back later.';
      }
      
      final data = settingsDoc.data();
      if (data == null) {
        return 'The app is currently under maintenance. Please check back later.';
      }
      
      final message = data['maintenanceMessage'] as String?;
      return message ?? 'The app is currently under maintenance. Please check back later.';
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('AppVersionService: Error getting maintenance message: $e');
      }
      return 'The app is currently under maintenance. Please check back later.';
    }
  }
  
  /// Get app store URLs for update
  static Future<Map<String, String?>> getAppStoreUrls() async {
    try {
      final settingsDoc = await FirebaseService.firestore
          .collection(_settingsCollection)
          .doc(_settingsDocument)
          .get();
      
      if (!settingsDoc.exists) {
        return {};
      }
      
      final data = settingsDoc.data();
      if (data == null) {
        return {};
      }
      
      return {
        'iosUrl': data['iosAppStoreUrl'] as String?,
        'androidUrl': data['androidPlayStoreUrl'] as String?,
      };
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('AppVersionService: Error getting app store URLs: $e');
      }
      return {};
    }
  }
  
  /// Compare two version strings (e.g., "1.0.0" vs "1.0.1")
  /// Returns: -1 if version1 < version2, 0 if equal, 1 if version1 > version2
  static int _compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final v2Parts = version2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    
    // Pad shorter version with zeros
    while (v1Parts.length < v2Parts.length) {
      v1Parts.add(0);
    }
    while (v2Parts.length < v1Parts.length) {
      v2Parts.add(0);
    }
    
    for (int i = 0; i < v1Parts.length; i++) {
      if (v1Parts[i] < v2Parts[i]) {
        return -1;
      } else if (v1Parts[i] > v2Parts[i]) {
        return 1;
      }
    }
    
    return 0;
  }
  
  /// Get current app version info
  static Future<Map<String, String>> getCurrentVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return {
        'version': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
        'packageName': packageInfo.packageName,
      };
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('AppVersionService: Error getting version info: $e');
      }
      return {};
    }
  }
  
  /// Store current app version in Firestore settings
  /// This allows you to track the current published version
  static Future<void> storeCurrentVersionInFirestore() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
      
      if (AppConfig.enableDebugLogging) {
        print('AppVersionService: Storing current version in Firestore: $currentVersion+$currentBuildNumber');
      }
      
      // Update the settings document with current version
      await FirebaseService.firestore
          .collection(_settingsCollection)
          .doc(_settingsDocument)
          .set({
        'currentAppVersion': currentVersion,
        'currentBuildNumber': currentBuildNumber,
        'lastVersionUpdate': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      
      if (AppConfig.enableDebugLogging) {
        print('AppVersionService: Successfully stored version in Firestore');
      }
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('AppVersionService: Error storing version in Firestore: $e');
      }
      // Don't throw - this is not critical
    }
  }
  
  /// Get current app version from Firestore (the stored/published version)
  static Future<Map<String, dynamic>?> getStoredVersionFromFirestore() async {
    try {
      final settingsDoc = await FirebaseService.firestore
          .collection(_settingsCollection)
          .doc(_settingsDocument)
          .get();
      
      if (!settingsDoc.exists) {
        return null;
      }
      
      final data = settingsDoc.data();
      if (data == null) {
        return null;
      }
      
      return {
        'currentAppVersion': data['currentAppVersion'] as String?,
        'currentBuildNumber': data['currentBuildNumber'] as int?,
        'lastVersionUpdate': data['lastVersionUpdate'] as String?,
      };
    } catch (e) {
      if (AppConfig.enableDebugLogging) {
        print('AppVersionService: Error getting stored version from Firestore: $e');
      }
      return null;
    }
  }
}
