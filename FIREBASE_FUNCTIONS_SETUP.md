# Firebase Cloud Functions Setup for Stripe Payments

This guide will help you set up Firebase Cloud Functions to handle Stripe payment processing securely.

## Prerequisites

1. ✅ Firebase Blaze Plan (Pay-as-you-go) - **You have this!**
2. Node.js 20+ installed on your machine
3. Firebase CLI installed (`npm install -g firebase-tools`)
4. Stripe account with API keys

## Step 1: Install Firebase CLI and Login

```bash
# Install Firebase CLI globally (if not already installed)
npm install -g firebase-tools

# Login to Firebase
firebase login

# Verify you're logged in
firebase projects:list
```

## Step 2: Initialize Firebase Functions (if not already done)

```bash
# Navigate to your project root
cd /Users/admin/StudioProjects/Remiles2-updated

# Initialize Firebase (if not already initialized)
firebase init functions

# When prompted:
# - Select your Firebase project
# - Choose JavaScript (or TypeScript if you prefer)
# - Install dependencies? Yes
```

## Step 3: Install Dependencies

```bash
# Navigate to functions directory
cd functions

# Install dependencies
npm install

# This will install:
# - firebase-admin
# - firebase-functions
# - stripe
```

## Step 4: Configure Stripe Secret Key

You need to set your Stripe secret key as a Firebase Functions config variable:

```bash
# Set Stripe secret key (use your actual secret key from Stripe Dashboard)
firebase functions:config:set stripe.secret_key="sk_test_YOUR_SECRET_KEY_HERE"

# For production, use your live secret key:
# firebase functions:config:set stripe.secret_key="sk_live_YOUR_LIVE_SECRET_KEY_HERE"
```

**Important:** 
- Never commit your secret keys to version control
- Use test keys (`sk_test_...`) for development
- Use live keys (`sk_live_...`) for production

## Step 5: Deploy Functions

```bash
# Make sure you're in the project root
cd /Users/admin/StudioProjects/Remiles2-updated

# Deploy all functions
firebase deploy --only functions

# Or deploy a specific function
firebase deploy --only functions:createPaymentIntent
```

## Step 6: Set Up Stripe Webhook (Optional but Recommended)

Webhooks allow Stripe to notify your app when payments succeed or fail.

### 6.1 Get Your Webhook Endpoint URL

After deploying, your webhook URL will be:
```
https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/handleStripeWebhook
```

To find your region and project:
```bash
# Check your Firebase project ID
firebase projects:list

# Check your function region (default is us-central1)
# You can see this in Firebase Console > Functions
```

### 6.2 Configure Webhook in Stripe Dashboard

1. Go to [Stripe Dashboard](https://dashboard.stripe.com) > Developers > Webhooks
2. Click "Add endpoint"
3. Enter your webhook URL
4. Select events to listen to:
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
5. Click "Add endpoint"
6. Copy the "Signing secret" (starts with `whsec_...`)

### 6.3 Set Webhook Secret in Firebase

```bash
# Set the webhook signing secret
firebase functions:config:set stripe.webhook_secret="whsec_YOUR_WEBHOOK_SECRET_HERE"

# Redeploy functions to apply the config
firebase deploy --only functions
```

## Step 7: Update Flutter App Configuration

### 7.1 Update Stripe Publishable Key

1. Open `lib/core/stripe_service.dart`
2. Replace the placeholder with your actual publishable key:
   ```dart
   static const String _publishableKey = 'pk_test_YOUR_PUBLISHABLE_KEY_HERE';
   ```

### 7.2 Configure Native Platforms

#### iOS (`ios/Runner/Info.plist`):
```xml
<key>StripePublishableKey</key>
<string>pk_test_YOUR_PUBLISHABLE_KEY_HERE</string>
```

#### Android (`android/app/src/main/AndroidManifest.xml`):
```xml
<meta-data
    android:name="stripe_publishable_key"
    android:value="pk_test_YOUR_PUBLISHABLE_KEY_HERE" />
```

## Step 8: Test the Integration

### 8.1 Test with Stripe Test Cards

Use these test card numbers:
- **Success**: `4242 4242 4242 4242`
- **Decline**: `4000 0000 0000 0002`
- **Requires Authentication**: `4000 0025 0000 3155`

Use any future expiry date (e.g., `12/25`) and any 3-digit CVC.

### 8.2 Test Flow

1. Run your Flutter app
2. Navigate to "Boost My Load" page
3. Select a subscription plan
4. Click "Upgrade My Plan"
5. Complete payment with test card
6. Check Firebase Console > Functions > Logs for any errors

## Step 9: Monitor and Debug

### View Function Logs

```bash
# View real-time logs
firebase functions:log

# View logs for specific function
firebase functions:log --only createPaymentIntent
```

### Check Firestore

After a payment attempt, check:
- `payment_intents` collection in Firestore
- Payment intent documents should be created automatically

### Check Stripe Dashboard

1. Go to Stripe Dashboard > Payments
2. You should see test payments
3. Check payment details and status

## Troubleshooting

### Function Deployment Fails

**Error**: "Functions did not deploy"
- **Solution**: Check Node.js version (should be 20+)
- **Solution**: Run `npm install` in functions directory
- **Solution**: Check Firebase CLI is up to date: `npm update -g firebase-tools`

### Payment Intent Creation Fails

**Error**: "unauthenticated" or "permission-denied"
- **Solution**: Ensure user is logged in before calling the function
- **Solution**: Check Firebase Authentication is working

**Error**: "Invalid Stripe API key"
- **Solution**: Verify secret key is set correctly: `firebase functions:config:get`
- **Solution**: Make sure you're using the correct key (test vs live)

### Webhook Not Working

**Error**: Webhook signature verification fails
- **Solution**: Ensure webhook secret is set correctly
- **Solution**: Verify webhook URL matches exactly in Stripe Dashboard
- **Solution**: Check that you're sending raw body in webhook handler

### Flutter App Can't Call Function

**Error**: "Function not found" or "Permission denied"
- **Solution**: Ensure function is deployed: `firebase deploy --only functions`
- **Solution**: Check function name matches exactly: `createPaymentIntent`
- **Solution**: Verify Firebase project is correctly configured in Flutter app

## Security Best Practices

1. **Never expose secret keys**:
   - Secret keys only in Firebase Functions config
   - Publishable keys are safe to use in client code

2. **Use environment-specific keys**:
   - Test keys for development
   - Live keys for production

3. **Enable Firebase App Check** (recommended):
   - Protects your functions from abuse
   - See: https://firebase.google.com/docs/app-check

4. **Monitor function usage**:
   - Check Firebase Console > Functions > Usage
   - Set up billing alerts in Firebase Console

## Going to Production

1. **Switch to Live Keys**:
   ```bash
   firebase functions:config:set stripe.secret_key="sk_live_YOUR_LIVE_SECRET_KEY"
   firebase deploy --only functions
   ```

2. **Update Flutter App**:
   - Replace test publishable key with live key
   - Update iOS Info.plist
   - Update Android AndroidManifest.xml

3. **Test Thoroughly**:
   - Test with real cards (small amounts)
   - Verify webhooks work
   - Monitor function logs

## Additional Resources

- [Firebase Functions Documentation](https://firebase.google.com/docs/functions)
- [Stripe API Documentation](https://stripe.com/docs/api)
- [Flutter Stripe Package](https://pub.dev/packages/flutter_stripe)
- [Firebase Functions Pricing](https://firebase.google.com/pricing)

## Support

If you encounter issues:
1. Check Firebase Console > Functions > Logs
2. Check Stripe Dashboard > Developers > Logs
3. Review error messages in Flutter app console
4. Verify all configuration steps are completed




## Stripe test card numbers
## Success (most common)
- Card number: 4242 4242 4242 4242
- Expiry: any future date (e.g., 12/25)
- CVC: any 3 digits (e.g., 123)
- ZIP: any 5 digits (e.g., 12345)

# Other test cards

Decline:
4000 0000 0000 0002
Requires authentication (3D Secure):
4000 0025 0000 3155
Insufficient funds:
4000 0000 0000 9995
Generic decline:
4000 0000 0000 0002
How to use
Run the app and go to "Boost My Load"
Select a plan and tap "Upgrade My Plan"
When the Stripe Payment Sheet appears, enter:
Card: 4242 4242 4242 4242
Expiry: 12/25 (or any future date)
CVC: 123 (or any 3 digits)
ZIP: 12345 (or any 5 digits)
Complete the payment