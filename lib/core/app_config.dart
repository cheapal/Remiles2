import 'package:flutter/foundation.dart';

/// App configuration for different environments
class AppConfig {
  static const bool _isDebug = kDebugMode;
  static const bool _isRelease = kReleaseMode;
  static const bool _isProfile = kProfileMode;

  /// Check if running in debug mode
  static bool get isDebug => _isDebug;

  /// Check if running in release mode
  static bool get isRelease => _isRelease;

  /// Check if running in profile mode
  static bool get isProfile => _isProfile;

  /// Check if running in production (release mode)
  static bool get isProduction => _isRelease;

  /// Check if analytics should be enabled
  static bool get enableAnalytics => true; // Always enable analytics

  /// Check if debug logging should be enabled
  static bool get enableDebugLogging => _isDebug;

  /// Check if test events should be logged
  static bool get enableTestEvents => false;//_isDebug; - no need to enable as i restart a lot

  /// Get current build mode as string
  static String get buildMode {
    if (_isDebug) return 'debug';
    if (_isProfile) return 'profile';
    if (_isRelease) return 'release';
    return 'unknown';
  }

  /// Get app version info
  static String get versionInfo => 'Remiles v1.0.0+1 (${buildMode})';

  /// Check if crashlytics should collect data
  static bool get enableCrashlytics => true; // Always enable crashlytics

  /// Check if performance monitoring should be enabled
  static bool get enablePerformanceMonitoring => true; // Always enable performance monitoring
}
