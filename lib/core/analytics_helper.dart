import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_service.dart';
import 'app_config.dart';

/// Helper class for common analytics events
class AnalyticsHelper {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Track screen views
  static Future<void> logScreenView(String screenName, {String? screenClass}) async {
    if (AppConfig.enableDebugLogging) {
      print('Analytics: Screen view - $screenName');
    }
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }

  /// Track user engagement events
  static Future<void> logButtonClick(String buttonName, {String? screenName}) async {
    if (AppConfig.enableDebugLogging) {
      print('Analytics: Button click - $buttonName on ${screenName ?? 'unknown'}');
    }
    await FirebaseService.logEvent('button_click', parameters: FirebaseService.convertParameters({
      'button_name': buttonName,
      'screen_name': screenName ?? 'unknown',
    }));
  }

  /// Track form submissions
  static Future<void> logFormSubmit(String formName, {bool success = true, String? error}) async {
    await FirebaseService.logEvent('form_submit', parameters: FirebaseService.convertParameters({
      'form_name': formName,
      'success': success,
      if (error != null) 'error': error,
    }));
  }

  /// Track search events
  static Future<void> logSearch(String searchTerm, {String? category}) async {
    await FirebaseService.logEvent('search', parameters: FirebaseService.convertParameters({
      'search_term': searchTerm,
      'category': category ?? 'general',
    }));
  }

  /// Track feature usage
  static Future<void> logFeatureUsage(String featureName, {Map<String, dynamic>? parameters}) async {
    await FirebaseService.logEvent('feature_usage', parameters: FirebaseService.convertParameters({
      'feature_name': featureName,
      ...?parameters,
    }));
  }

  /// Track errors (non-fatal)
  static Future<void> logError(String errorType, String errorMessage, {String? screenName}) async {
    await FirebaseService.logEvent('error_occurred', parameters: FirebaseService.convertParameters({
      'error_type': errorType,
      'error_message': errorMessage,
      'screen_name': screenName ?? 'unknown',
    }));
  }

  /// Track user journey events
  static Future<void> logUserJourney(String step, {String? previousStep, Map<String, dynamic>? data}) async {
    await FirebaseService.logEvent('user_journey', parameters: FirebaseService.convertParameters({
      'step': step,
      if (previousStep != null) 'previous_step': previousStep,
      ...?data,
    }));
  }

  /// Track business metrics
  static Future<void> logBusinessMetric(String metricName, num value, {String? unit}) async {
    await FirebaseService.logEvent('business_metric', parameters: FirebaseService.convertParameters({
      'metric_name': metricName,
      'value': value,
      if (unit != null) 'unit': unit,
    }));
  }

  /// Set user properties for segmentation
  static Future<void> setUserSegment(String segmentName, String segmentValue) async {
    await FirebaseService.setUserProperty(segmentName, segmentValue);
  }

  /// Track app lifecycle events
  static Future<void> logAppLifecycle(String event) async {
    await FirebaseService.logEvent('app_lifecycle', parameters: FirebaseService.convertParameters({
      'event': event,
    }));
  }

  /// Track performance metrics
  static Future<void> logPerformance(String operation, int durationMs, {bool success = true}) async {
    await FirebaseService.logEvent('performance', parameters: FirebaseService.convertParameters({
      'operation': operation,
      'duration_ms': durationMs,
      'success': success,
    }));
  }
}
