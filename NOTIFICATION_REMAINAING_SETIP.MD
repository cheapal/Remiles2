iOS — needs additional configuration
The code is ready, but you need to complete these steps:
Xcode project settings:
Open ios/Runner.xcworkspace in Xcode
Select the Runner target → Signing & Capabilities
Add "Push Notifications" capability
Add "Background Modes" capability and enable "Remote notifications"
Firebase Console:
Upload your APNs certificate or key
Go to Firebase Console → Project Settings → Cloud Messaging → iOS app configuration
Upload either:
APNs Authentication Key (.p8 file) — recommended
APNs Certificates (.p12 file)
AppDelegate updated:
Notification permissions requested
Remote notification registration handled
Background notification handling implemented