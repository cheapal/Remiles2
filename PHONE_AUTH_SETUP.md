# Phone Authentication Setup Guide

## Issue
You're getting the error:
```
This operation is not allowed. This may be because the given sign-in method is disabled for this Firebase project.
```

This means **Phone Authentication is not enabled** in your Firebase Console.

## Solution: Enable Phone Authentication in Firebase Console

### Step 1: Open Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project

### Step 2: Enable Phone Authentication
1. Navigate to **Authentication** in the left sidebar
2. Click on the **Sign-in method** tab
3. Find **Phone** in the list of providers
4. Click on **Phone** to open its settings
5. Toggle **Enable** to ON
6. Click **Save**

### Step 3: Configure Phone Authentication (Optional but Recommended)

#### For Android:
- **Android app verification** is usually handled automatically
- Make sure your `google-services.json` is properly configured
- The app should use SMS Retriever API for automatic verification

#### For iOS:
- You may need to configure **reCAPTCHA** for web verification
- Or use **Silent Push Notifications** for automatic verification

### Step 4: Test Phone Authentication
After enabling:
1. Restart your app
2. Try sending an OTP again
3. You should receive the verification code via SMS

## Additional Notes

### App Check Warning
The warning about App Check is not critical for development, but you can enable it for production:
- Go to **App Check** in Firebase Console
- Register your app
- This helps prevent abuse

### Phone Number Format
- Always include country code (e.g., +923178826365)
- Format: `+[country code][phone number]`
- No spaces or special characters

### Testing
- Use test phone numbers in Firebase Console for development
- Go to **Authentication > Sign-in method > Phone > Phone numbers for testing**
- Add test numbers to avoid using real SMS credits during development

## Troubleshooting

### Still Getting Errors?
1. **Wait a few minutes** after enabling - Firebase needs time to propagate changes
2. **Check Firebase project settings** - Ensure you're using the correct project
3. **Verify API is enabled** - Go to Google Cloud Console and ensure Identity Toolkit API is enabled
4. **Check billing** - Phone Authentication requires a paid plan (Blaze plan) for production use

### Error Codes Reference
- `operation-not-allowed` (17006): Phone auth not enabled
- `invalid-phone-number` (17010): Invalid phone format
- `too-many-requests` (17010): Rate limit exceeded
- `quota-exceeded`: SMS quota exceeded

## Production Considerations

1. **Enable App Check** for better security
2. **Set up reCAPTCHA** for web platforms
3. **Monitor usage** in Firebase Console
4. **Set up billing alerts** to avoid unexpected charges
5. **Use test numbers** during development to save costs

