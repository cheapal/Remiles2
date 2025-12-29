/// App-wide constants
/// 
/// This file contains all application-wide constants including API keys,
/// configuration values, and other static data that should be centralized.
class AppConstants {
  AppConstants._(); // Private constructor to prevent instantiation

  /// Google Maps API Key
  /// 
  /// This key is used for:
  /// - Google Maps SDK (configured in native Android/iOS files)
  /// - Google Places API (autocomplete, place details)
  /// - Google Directions API (route calculations)
  /// - Google Distance Matrix API (distance calculations)
  /// 
  /// Make sure the following APIs are enabled in Google Cloud Console:
  /// - Maps SDK for Android
  /// - Maps SDK for iOS
  /// - Places API
  /// - Directions API
  /// - Distance Matrix API
  static const String googleApiKey = 'AIzaSyAOZKD90SxW5dwOZVEe-nCm8dA6jXs-5AQ';
}

