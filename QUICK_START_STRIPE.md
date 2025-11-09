# Quick Start: Stripe + Firebase Functions Integration

## 🚀 Quick Setup (5 Steps)

### Step 1: Install Firebase CLI & Login
```bash
npm install -g firebase-tools
firebase login
```

### Step 2: Initialize Functions (if needed)
```bash
cd /Users/admin/StudioProjects/Remiles2-updated
firebase init functions
# Choose JavaScript, install dependencies
```

### Step 3: Set Stripe Secret Key
```bash
firebase functions:config:set stripe.secret_key="test key"
```

### Step 4: Deploy Functions
```bash
firebase deploy --only functions
```

### Step 5: Update Flutter App
1. Open `lib/core/stripe_service.dart`
2. Replace `_publishableKey` with your actual Stripe publishable key
3. Update `ios/Runner/Info.plist` and `android/app/src/main/AndroidManifest.xml` with publishable key

## ✅ That's It!

Your Stripe integration is now connected to Firebase Cloud Functions. The app will:
- ✅ Securely create payment intents via Firebase Functions
- ✅ Process payments using Stripe Payment Sheet
- ✅ Save subscription data to Firestore after successful payment

## 🧪 Test It

1. Run the app
2. Go to "Boost My Load"
3. Select a plan
4. Use test card: `4242 4242 4242 4242`
5. Complete payment

## 📚 Full Documentation

See `FIREBASE_FUNCTIONS_SETUP.md` for detailed setup instructions.

