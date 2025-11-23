import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<QuerySnapshot>? _notificationsSubscription;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnreadNotifications => unreadCount > 0;

  // Initialize and listen to notifications for a user
  Future<void> initialize(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Cancel existing subscription if any
      await _notificationsSubscription?.cancel();

      // Listen to notifications in real-time
      _notificationsSubscription = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots()
          .listen(
            (snapshot) {
              _notifications = snapshot.docs
                  .map((doc) => NotificationModel.fromFirestore(doc))
                  .toList();
              _isLoading = false;
              notifyListeners();
            },
            onError: (error) {
              _errorMessage = error.toString();
              _isLoading = false;
              notifyListeners();
            },
          );
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final unreadNotifications = _notifications.where((n) => !n.isRead).toList();
      
      if (unreadNotifications.isEmpty) return;

      final batch = _firestore.batch();
      for (final notification in unreadNotifications) {
        batch.update(
          _firestore.collection('notifications').doc(notification.id),
          {'isRead': true},
        );
      }
      await batch.commit();

      // Update local state
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();

      // Update local state
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Clear all notifications
  Future<void> clearAll() async {
    try {
      if (_notifications.isEmpty) return;

      final batch = _firestore.batch();
      for (final notification in _notifications) {
        batch.delete(
          _firestore.collection('notifications').doc(notification.id),
        );
      }
      await batch.commit();

      _notifications = [];
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Dispose
  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }
}
