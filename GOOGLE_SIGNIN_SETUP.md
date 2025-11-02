# Google Sign-In Setup Instructions

## Getting Your Debug SHA-1 Fingerprint

The SHA-1 certificate fingerprint is required for Google Sign-In to work on Android. Here's how to get it:

### Option 1: Using Gradle (Recommended for Android Studio)

1. Open your project in Android Studio
2. Open the terminal (bottom panel or View → Tool Windows → Terminal)
3. Navigate to your Android folder:
   ```bash
   cd android
   ```
4. Run the following command:
   ```bash
   ./gradlew signingReport
   ```
   
   On Windows, use:
   ```bash
   gradlew signingReport
   ```

5. Look for the output under `Variant: debug`:
   ```
   Variant: debug
   Config: debug
   Store: /path/to/keystore
   Alias: AndroidDebugKey
   MD5: XX:XX:XX:...
   SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
   SHA-256: XX:XX:XX:...
   Valid until: ...
   ```

6. Copy the **SHA1** value (it should look like: `AA:BB:CC:DD:EE:FF:...`)

### Option 2: Using keytool (Manual Method)

#### For Debug Keystore:

**On macOS/Linux:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**On Windows:**
```bash
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

#### For Release Keystore (when building for production):
```bash
keytool -list -v -keystore /path/to/your/keystore.jks -alias your-key-alias
```
(You'll need to provide your keystore password)

Look for the SHA1 value in the output.

### Option 3: Using Flutter Command

From your project root directory:
```bash
cd android
./gradlew signingReport
```

Or on Windows:
```bash
cd android
gradlew signingReport
```

## Adding SHA-1 to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click on the gear icon ⚙️ next to "Project Overview"
4. Select "Project settings"
5. Scroll down to "Your apps" section
6. Select your Android app (or add one if you haven't)
7. Click "Add fingerprint" button
8. Paste your SHA-1 fingerprint
9. Click "Save"

## Important Notes

- **Debug SHA-1**: Use this for development and testing
- **Release SHA-1**: You'll need to add this when building your release APK/AAB
- **Multiple SHA-1s**: You can add multiple SHA-1 fingerprints to support both debug and release builds
- **After adding SHA-1**: Download the updated `google-services.json` file and replace it in `android/app/`

## Verify Setup

After adding the SHA-1 to Firebase:
1. Download the updated `google-services.json` from Firebase Console
2. Replace the file at `android/app/google-services.json`
3. Rebuild your app
4. Test Google Sign-In functionality

## Troubleshooting

If Google Sign-In is not working:
- Make sure SHA-1 is added correctly in Firebase Console
- Ensure `google-services.json` is up to date
- Check that Google Sign-In is enabled in Firebase Console (Authentication → Sign-in method → Google)
- Verify the package name matches between your app and Firebase project
- Try clearing app data and reinstalling

## Getting SHA-256 (Optional)

If you need SHA-256 for other services:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Look for "SHA-256" in the output.

