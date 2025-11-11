# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.kts.

# Stripe Android SDK - Push Provisioning
# These rules prevent R8 from removing Stripe push provisioning classes
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider
-dontwarn com.stripe.android.pushProvisioning.EphemeralKeyUpdateListener

# Keep Stripe classes
-keep class com.stripe.android.** { *; }
-keep class com.stripe.android.pushProvisioning.** { *; }

# Keep React Native Stripe SDK classes
-keep class com.reactnativestripesdk.** { *; }

