import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../core/firebase_service.dart';
import '../firebase_options.dart';
import '../core/navigator_service.dart';
import '../modules/carrier_dashboard/views/dashboard/pages/chat_screen.dart';
import '../modules/shipper_dashboard/pages/shipper_load_details_page.dart';
import '../modules/carrier_dashboard/views/dashboard/pages/carrier_manage_load_screen.dart';
import 'conversation_tracker.dart';

/// Top-level function for handling background messages
/// Must be a top-level function, not a class method
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized in background isolate
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Message title: ${message.notification?.title}');
  debugPrint('Message body: ${message.notification?.body}');
  debugPrint('Message data: ${message.data}');

  // Background messages are handled here
  // The notification is already sent by Cloud Functions
  // Here we can perform additional tasks like updating local database, etc.
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  bool _localNotificationsInitialized = false;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _fcmToken != null;

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      // Initialize local notifications first
      await _initializeLocalNotifications();

      // Request permission for iOS
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('User granted notification permission');
      } else {
        debugPrint('User declined or has not accepted notification permission');
        return;
      }

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Get FCM token
      await _getFCMToken();

      // Listen for token refresh
      _tokenSubscription = _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _saveTokenToFirestore(newToken);
        debugPrint('FCM Token refreshed: $newToken');
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle messages when app is opened from terminated state
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessage(initialMessage);
      }

      // Handle messages when app is opened from background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

      debugPrint('Notification service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null) {
            try {
              final Map<String, dynamic> data = jsonDecode(response.payload!);
              _navigateToScreen(data);
            } catch (e) {
              debugPrint('Error parsing notification payload: $e');
              // Fallback for old string payload
              debugPrint(
                'Notification tapped with raw payload: ${response.payload}',
              );
            }
          }
        },
      );

      // Create notification channel for Android 8.0+
      const androidChannel = AndroidNotificationChannel(
        'remiles_channel',
        'Remiles Notifications',
        description: 'Notifications for Remiles app',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);

      _localNotificationsInitialized = true;
      debugPrint('Local notifications initialized');
    } catch (e) {
      debugPrint('Error initializing local notifications: $e');
    }
  }

  /// Get FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        debugPrint('FCM Token: $_fcmToken');
        await _saveTokenToFirestore(_fcmToken!);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  /// Save FCM token to Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseService.currentUser;
      if (user == null) return;

      // Save to users collection
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also save to role-specific collection (shipper or carrier)
      final userData = await FirebaseService.getCurrentUserData();
      if (userData != null) {
        final role = userData.role;
        if (role == UserRole.shipper) {
          await _firestore.collection('shippers').doc(user.uid).update({
            'fcmToken': token,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          });
        } else if (role == UserRole.carrier) {
          await _firestore.collection('carriers').doc(user.uid).update({
            'fcmToken': token,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint('Error saving FCM token to Firestore: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');

    // Check if this is a message notification for the currently open conversation
    final messageType = message.data['type'] as String?;
    final conversationId = message.data['conversationId'] as String?;

    // Skip showing notification if it's a message for the currently open conversation
    if (messageType == 'message' &&
        conversationId != null &&
        ConversationTracker.isConversationOpen(conversationId)) {
      debugPrint(
        'Skipping notification for open conversation: $conversationId',
      );
      return;
    }

    // Show local notification for foreground messages
    _showLocalNotification(message);

    _handleMessage(message);
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (!_localNotificationsInitialized) {
      debugPrint('Local notifications not initialized, skipping');
      return;
    }

    try {
      final notification = message.notification;

      // Use notification title/body if available, otherwise use data
      final title =
          notification?.title ?? message.data['title'] ?? 'New Notification';
      final body = notification?.body ?? message.data['body'] ?? '';

      const androidDetails = AndroidNotificationDetails(
        'remiles_channel',
        'Remiles Notifications',
        channelDescription: 'Notifications for Remiles app',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Generate a unique notification ID based on message ID or timestamp
      final notificationId =
          message.messageId?.hashCode ??
          DateTime.now().millisecondsSinceEpoch.hashCode;

      await _localNotifications.show(
        notificationId.abs(),
        title,
        body,
        details,
        payload: jsonEncode(message.data),
      );

      debugPrint('Local notification shown: $title - $body');
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  /// Handle incoming messages
  void _handleMessage(RemoteMessage message) {
    debugPrint('Handling message: ${message.messageId}');
    debugPrint('Message data: ${message.data}');

    _navigateToScreen(message.data);
  }

  /// Handle tapping on a notification in the UI
  void handleNotificationTap(NotificationModel notification) {
    final Map<String, dynamic> data = notification.data != null
        ? Map.from(notification.data!)
        : {};

    // Ensure type and relatedId are available in the data map
    data['type'] = notification.type.toString().split('.').last;
    if (notification.relatedId != null) {
      if (notification.type == NotificationType.message) {
        data['conversationId'] ??= notification.relatedId;
      } else {
        data['loadId'] ??= notification.relatedId;
      }
    }

    _navigateToScreen(data);
  }

  /// Navigate to appropriate screen based on notification data
  Future<void> _navigateToScreen(Map<String, dynamic> data) async {
    final type = data['type'] as String?;
    debugPrint('Navigating to screen for notification type: $type');

    if (type == 'message') {
      final conversationId = data['conversationId'] as String?;
      if (conversationId != null) {
        NavigatorService.push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversationId,
              otherUserId: data['senderId'],
              otherUserName: data['senderName'],
              loadId: data['loadId'],
              listingId: data['listingId'],
            ),
          ),
        );
      }
    } else if (type == 'offerAccepted' ||
        type == 'offerReceived' ||
        type == 'counterOfferReceived' ||
        type == 'offerRejected' ||
        type == 'orderStatus' ||
        type == 'paymentReceived' ||
        type == 'paymentFailed') {
      final loadId = data['loadId'] as String?;
      if (loadId != null) {
        _navigateToLoadDetails(loadId);
      }
    }
  }

  /// Navigate to load details, fetching data if necessary
  Future<void> _navigateToLoadDetails(String loadId) async {
    try {
      final userData = await FirebaseService.getCurrentUserData();
      if (userData == null) return;

      if (userData.role == UserRole.shipper) {
        // Find the load in shipper's collection
        final loadDoc = await FirebaseFirestore.instance
            .collection('shippers')
            .doc(userData.uid)
            .collection('loads')
            .doc(loadId)
            .get();

        if (loadDoc.exists) {
          final loadData = loadDoc.data();
          if (loadData != null) {
            loadData['id'] = loadDoc.id;
            NavigatorService.push(
              MaterialPageRoute(
                builder: (context) => ShipperLoadDetailsPage(load: loadData),
              ),
            );
          }
        }
      } else if (userData.role == UserRole.carrier) {
        NavigatorService.push(
          MaterialPageRoute(
            builder: (context) =>
                CarrierManageLoadScreen(initialLoadId: loadId),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error navigating to load details: $e');
    }
  }

  /// Create a notification in Firestore (for local notifications)
  static Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? relatedId,
  }) async {
    try {
      final notification = NotificationModel(
        id: '', // Will be set by Firestore
        userId: userId,
        type: type,
        title: title,
        body: body,
        data: data,
        isRead: false,
        createdAt: DateTime.now(),
        relatedId: relatedId,
      );

      await FirebaseFirestore.instance
          .collection('notifications')
          .add(notification.toFirestore());
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  /// Delete FCM token on logout
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _fcmToken = null;

      final user = FirebaseService.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
        });
      }
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }

  /// Dispose
  void dispose() {
    _tokenSubscription?.cancel();
    _messageSubscription?.cancel();
  }
}
