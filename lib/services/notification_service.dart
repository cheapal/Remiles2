import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../core/firebase_service.dart';

/// Top-level function for handling background messages
/// Must be a top-level function, not a class method
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  // Background messages are handled here
  // You can perform tasks like updating local database, etc.
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _fcmToken;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _fcmToken != null;

  /// Initialize notification service
  Future<void> initialize() async {
    try {
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
    _handleMessage(message);
  }

  /// Handle incoming messages
  void _handleMessage(RemoteMessage message) {
    debugPrint('Handling message: ${message.messageId}');
    debugPrint('Message data: ${message.data}');
    debugPrint('Message notification: ${message.notification?.title}');

    // The notification is already saved to Firestore by Cloud Functions
    // Here we just need to handle any app-specific logic
    // The NotificationProvider will automatically update via Firestore listener
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
