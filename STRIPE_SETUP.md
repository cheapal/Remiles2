# Stripe Payment Integration Setup Guide

This guide will help you set up Stripe payment processing for the subscription plans in the Remiles app.

## Prerequisites

1. A Stripe account (sign up at https://stripe.com)
2. Access to your Stripe Dashboard
3. A backend server (for production) or use test mode for development

## Step 1: Get Your Stripe API Keys

1. Log in to your [Stripe Dashboard](https://dashboard.stripe.com)
2. Navigate to **Developers** → **API keys**
3. Copy your **Publishable key** (starts with `pk_test_` for test mode or `pk_live_` for live mode)
4. Copy your **Secret key** (starts with `sk_test_` for test mode or `sk_live_` for live mode)
   - ⚠️ **Never expose your Secret key in client-side code!**

## Step 2: Configure Stripe in the App

### Update Stripe Service

1. Open `lib/core/stripe_service.dart`
2. Replace the placeholder publishable key:
   ```dart
   static const String _publishableKey = 'pk_test_YOUR_PUBLISHABLE_KEY_HERE';
   ```
   With your actual publishable key:
   ```dart
   static const String _publishableKey = 'pk_test_51AbCdEf...'; // Your actual key
   ```

### Configure Native Platforms

#### iOS Configuration

1. Open `ios/Runner/Info.plist`
2. Add your Stripe publishable key:
   ```xml
   <key>StripePublishableKey</key>
   <string>pk_test_YOUR_PUBLISHABLE_KEY_HERE</string>
   ```

#### Android Configuration

1. Open `android/app/src/main/AndroidManifest.xml`
2. Add the following within the `<application>` tag:
   ```xml
   <meta-data
       android:name="stripe_publishable_key"
       android:value="pk_test_YOUR_PUBLISHABLE_KEY_HERE" />
   ```

## Step 3: Set Up Backend (Required for Production)

Stripe requires a backend server to securely create payment intents using your secret key.

### Backend Endpoint Example (Node.js/Express)

```javascript
const express = require('express');
const stripe = require('stripe')('sk_test_YOUR_SECRET_KEY_HERE');
const app = express();

app.use(express.json());

app.post('/create-payment-intent', async (req, res) => {
  try {
    const { amount, currency = 'usd', metadata } = req.body;
    
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount, // Amount in cents
      currency: currency,
      metadata: metadata || {},
    });
    
    res.json({ 
      clientSecret: paymentIntent.client_secret 
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(3000, () => {
  console.log('Server running on port 3000');
});
```

### Update Stripe Service to Use Backend

1. Open `lib/core/stripe_service.dart`
2. Uncomment and update the backend endpoint:
   ```dart
   static const String _paymentIntentEndpoint = 'https://your-backend.com/create-payment-intent';
   ```
3. Uncomment the backend API call code in `createPaymentIntent` method

### Alternative: Firebase Cloud Functions

You can also use Firebase Cloud Functions as your backend:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const stripe = require('stripe')(functions.config().stripe.secret_key);

exports.createPaymentIntent = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  const { amount, currency = 'usd', metadata } = data;
  
  const paymentIntent = await stripe.paymentIntents.create({
    amount: amount,
    currency: currency,
    metadata: {
      ...metadata,
      userId: context.auth.uid,
    },
  });
  
  return { clientSecret: paymentIntent.client_secret };
});
```

Then update the Stripe service to use Firebase Functions:
```dart
import 'package:cloud_functions/cloud_functions.dart';

static Future<PaymentIntent?> createPaymentIntent({...}) async {
  try {
    final callable = FirebaseFunctions.instance.httpsCallable('createPaymentIntent');
    final result = await callable.call({
      'amount': amountInCents,
      'currency': currency,
      'metadata': metadata,
    });
    
    final clientSecret = result.data['clientSecret'] as String;
    return PaymentIntent(clientSecret: clientSecret);
  } catch (e) {
    debugPrint('Error creating payment intent: $e');
    rethrow;
  }
}
```

## Step 4: Test the Integration

### Test Card Numbers

Use these test card numbers in Stripe test mode:

- **Success**: `4242 4242 4242 4242`
- **Decline**: `4000 0000 0000 0002`
- **Requires Authentication**: `4000 0025 0000 3155`

Use any future expiry date (e.g., `12/25`) and any 3-digit CVC.

### Testing Flow

1. Run the app: `flutter run`
2. Navigate to "Boost My Load" page
3. Select a subscription plan
4. Click "Upgrade My Plan"
5. Choose "Stripe Payment Sheet"
6. Enter test card details
7. Complete the payment

## Step 5: Go Live

When ready for production:

1. **Switch to Live Keys**:
   - Get your live publishable and secret keys from Stripe Dashboard
   - Update `stripe_service.dart` with live publishable key
   - Update your backend with live secret key

2. **Update App Configuration**:
   - Update `Info.plist` (iOS) with live publishable key
   - Update `AndroidManifest.xml` (Android) with live publishable key

3. **Test Thoroughly**:
   - Test with real cards (use small amounts)
   - Verify webhook handling
   - Test error scenarios

## Troubleshooting

### Payment Intent Creation Fails

- **Error**: "Payment intent creation failed"
- **Solution**: Ensure your backend endpoint is correctly configured and accessible. Check that your secret key is valid.

### Payment Sheet Doesn't Show

- **Error**: Payment sheet doesn't appear
- **Solution**: 
  - Verify publishable key is set correctly
  - Check that `StripeService.initialize()` is called in `main.dart`
  - Ensure backend returns valid `clientSecret`

### iOS Build Issues

- **Error**: Stripe not working on iOS
- **Solution**: 
  - Run `pod install` in `ios/` directory
  - Ensure `Info.plist` has the publishable key
  - Check iOS deployment target is 11.0+

### Android Build Issues

- **Error**: Stripe not working on Android
- **Solution**:
  - Ensure `minSdkVersion` is 21 or higher in `android/app/build.gradle.kts`
  - Verify `AndroidManifest.xml` has the publishable key meta-data

## Security Best Practices

1. **Never commit secret keys to version control**
   - Use environment variables or secure configuration
   - Use different keys for test and production

2. **Always use HTTPS** for backend endpoints
   - Never send payment data over HTTP

3. **Validate payments on your backend**
   - Don't trust client-side payment confirmations
   - Use Stripe webhooks to verify payments

4. **Handle errors gracefully**
   - Show user-friendly error messages
   - Log errors for debugging (without exposing sensitive data)

## Additional Resources

- [Stripe Documentation](https://stripe.com/docs)
- [Flutter Stripe Package](https://pub.dev/packages/flutter_stripe)
- [Stripe Testing Guide](https://stripe.com/docs/testing)
- [Stripe Webhooks](https://stripe.com/docs/webhooks)

## Support

For issues or questions:
- Check Stripe Dashboard logs
- Review error messages in app console
- Consult Stripe support documentation

