# Analytics & Production Configuration

## Overview
This app includes comprehensive Firebase Analytics integration with proper production environment handling.

## Files Added/Modified

### Core Files
- `app_config.dart` - Environment configuration management
- `analytics_helper.dart` - Analytics helper methods
- `firebase_service.dart` - Enhanced with analytics methods
- `main.dart` - Updated with production checks

## Environment Configuration

### Debug Mode (`flutter run`)
- ✅ Analytics test events enabled
- ✅ Debug logging enabled
- ✅ All analytics events logged
- ✅ Console output for debugging

### Release Mode (`flutter run --release`)
- ❌ Analytics test events disabled
- ❌ Debug logging disabled
- ✅ Production analytics events logged
- ❌ No console output

## Analytics Events Tracked

### Authentication
- `login` - User sign in attempts
- `sign_up` - User registration
- `shipper_signup` / `carrier_signup` - Role-specific signup
- `logout` - User sign out

### User Journey
- `onboarding_complete` - Onboarding completion
- `load_created` - Load creation
- `load_booked` - Load booking

### Debug Events (Debug Only)
- `analytics_test` - Test event for verification

## Usage Examples

### Basic Event Logging
```dart
// Log custom events
await FirebaseService.logEvent('custom_event', parameters: {
  'key': 'value',
});

// Using helper methods
await AnalyticsHelper.logScreenView('dashboard');
await AnalyticsHelper.logButtonClick('create_load');
```

### Environment Checks
```dart
// Check if in debug mode
if (AppConfig.isDebug) {
  print('Debug mode active');
}

// Check if analytics is enabled
if (AppConfig.enableAnalytics) {
  // Log analytics event
}
```

## Production Deployment

### Before Release
1. ✅ Test analytics in debug mode
2. ✅ Verify events appear in Firebase Console
3. ✅ Confirm no test events in release builds

### Release Build
```bash
# Build release version
flutter build apk --release
flutter build ios --release

# Analytics will automatically:
# - Disable test events
# - Disable debug logging
# - Continue tracking production events
```

## Firebase Console

### Viewing Analytics
1. Go to Firebase Console
2. Select your project
3. Navigate to Analytics → Events
4. Events appear within 24 hours

### Key Metrics to Monitor
- User engagement (screen views, button clicks)
- Conversion funnel (signup → onboarding → load creation)
- Error rates and crash analytics
- User retention and behavior patterns

## Configuration Options

### AppConfig Settings
```dart
// Enable/disable analytics
AppConfig.enableAnalytics // Always true

// Enable/disable debug logging
AppConfig.enableDebugLogging // true in debug, false in release

// Enable/disable test events
AppConfig.enableTestEvents // true in debug, false in release
```

## Troubleshooting

### Analytics Not Working
1. Check Firebase Console for events
2. Verify internet connection
3. Check if analytics is enabled in Firebase Console
4. Look for error messages in debug logs

### Production Issues
1. Ensure release build is used
2. Check Firebase Console for production events
3. Verify no test events in production data
4. Monitor crashlytics for analytics-related errors

## Best Practices

1. **Always use AppConfig** for environment checks
2. **Test in debug mode** before releasing
3. **Monitor Firebase Console** regularly
4. **Use meaningful event names** and parameters
5. **Avoid logging sensitive data** in analytics
6. **Set up conversion goals** in Firebase Console
