# App Version Check & Maintenance Mode Setup

This document explains how to set up and use the app version checking and maintenance mode features.

## Overview

The app now includes two important features:
1. **Version Check**: Automatically checks if the app version is up to date at startup
2. **Maintenance Mode**: Allows you to temporarily disable the app for maintenance

Both features are controlled via a Firestore document that can be easily updated from the Firebase Console.

## Firestore Setup

Create a document in Firestore with the following structure:

**Collection**: `app_settings`  
**Document ID**: `settings`

### Document Structure

```json
{
  "maintenanceMode": false,
  "maintenanceMessage": "The app is currently under maintenance. Please check back later.",
  "minAppVersion": "1.0.0",
  "minBuildNumber": 1,
  "currentAppVersion": "1.0.0",
  "currentBuildNumber": 1,
  "lastVersionUpdate": "2024-01-01T00:00:00.000Z",
  "iosAppStoreUrl": "https://apps.apple.com/app/remiles",
  "androidPlayStoreUrl": "https://play.google.com/store/apps/details?id=com.example.majh"
}
```

### Field Descriptions

- **`maintenanceMode`** (boolean): Set to `true` to enable maintenance mode. When enabled, users will see a maintenance screen and cannot use the app.
- **`maintenanceMessage`** (string, optional): Custom message to display during maintenance. If not provided, a default message is shown.
- **`minAppVersion`** (string, optional): Minimum required app version (e.g., "1.0.0"). The app compares this using semantic versioning.
- **`minBuildNumber`** (number, optional): Minimum required build number. This is more precise than version strings and takes precedence.
- **`currentAppVersion`** (string, auto-populated): Current published app version. This is automatically updated when the app starts.
- **`currentBuildNumber`** (number, auto-populated): Current published app build number. This is automatically updated when the app starts.
- **`lastVersionUpdate`** (string, auto-populated): ISO timestamp of when the version was last updated. Automatically set when version is stored.
- **`iosAppStoreUrl`** (string, optional): iOS App Store URL for the update button. If not provided, a fallback URL is used.
- **`androidPlayStoreUrl`** (string, optional): Android Play Store URL for the update button. If not provided, a fallback URL is used.

### Automatic Version Tracking

The app automatically stores the current version and build number in Firestore when it starts. This means:
- You can see what version is currently running in production
- The `currentAppVersion` and `currentBuildNumber` fields are automatically updated
- You can reference these values when setting `minAppVersion` and `minBuildNumber` for updates

## How It Works

### App Startup Flow

1. App starts → `AppCheckWrapper` is loaded
2. Checks maintenance mode first (highest priority)
3. If maintenance mode is off, checks if update is required
4. If all checks pass, proceeds to `AuthWrapper` (normal app flow)

### Maintenance Mode

- When `maintenanceMode` is set to `true`, users see a maintenance screen
- The app automatically re-checks every 30 seconds
- When maintenance mode is turned off, the app automatically resumes normal operation

### Version Check

- Compares current app version/build number with minimum required values
- If the app is outdated, users see an "Update Required" screen
- Users can tap "Update Now" to open the app store
- The app re-checks every 30 seconds while update is required

## Usage Examples

### Enable Maintenance Mode

1. Open Firebase Console
2. Navigate to Firestore Database
3. Go to `app_settings` collection → `settings` document
4. Set `maintenanceMode` to `true`
5. Optionally update `maintenanceMessage` with a custom message
6. Save the document

Users will immediately see the maintenance screen (within 30 seconds).

### Disable Maintenance Mode

1. Open Firebase Console
2. Navigate to Firestore Database
3. Go to `app_settings` collection → `settings` document
4. Set `maintenanceMode` to `false`
5. Save the document

The app will automatically resume normal operation (within 30 seconds).

### Force App Update

1. Open Firebase Console
2. Navigate to Firestore Database
3. Go to `app_settings` collection → `settings` document
4. Set `minAppVersion` to the minimum required version (e.g., "1.1.0")
5. Or set `minBuildNumber` to the minimum required build number (e.g., 2)
6. Save the document

Users with older versions will see the update screen.

### Remove Update Requirement

1. Open Firebase Console
2. Navigate to Firestore Database
3. Go to `app_settings` collection → `settings` document
4. Remove or set `minAppVersion` to a lower value
5. Remove or set `minBuildNumber` to a lower value
6. Save the document

## Important Notes

- **Fail-Safe Behavior**: If the Firestore document doesn't exist or there's an error, the app will continue normally (fail gracefully)
- **Priority**: Maintenance mode takes priority over version checks
- **Periodic Checks**: The app automatically re-checks every 30 seconds when in maintenance mode or when update is required
- **Build Number vs Version**: Build numbers are more precise. If both are set, build number takes precedence
- **App Store URLs**: Make sure to update the `iosAppStoreUrl` and `androidPlayStoreUrl` with your actual app store URLs
- **Automatic Version Storage**: The app automatically stores the current version in Firestore on startup. You don't need to manually set `currentAppVersion` or `currentBuildNumber` - they are auto-populated

## Testing

### Test Maintenance Mode

1. Set `maintenanceMode` to `true` in Firestore
2. Restart the app or wait 30 seconds
3. You should see the maintenance screen
4. Set `maintenanceMode` to `false`
5. Wait 30 seconds - the app should resume

### Test Version Check

1. Set `minBuildNumber` to a number higher than your current build number
2. Restart the app
3. You should see the update required screen
4. Set `minBuildNumber` back to a lower value
5. Restart the app - it should proceed normally

## Troubleshooting

- **App not checking**: Make sure Firebase is properly initialized and Firestore is accessible
- **Maintenance mode not working**: Check that the document path is exactly `app_settings/settings`
- **Update screen not showing**: Verify that `minAppVersion` or `minBuildNumber` is set correctly
- **App store not opening**: Update the `iosAppStoreUrl` or `androidPlayStoreUrl` with correct URLs
