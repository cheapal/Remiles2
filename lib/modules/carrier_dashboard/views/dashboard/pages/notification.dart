import 'package:remiles/modules/carrier_dashboard/views/common/widgets/top_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:remiles/providers/notification_provider.dart';
import 'package:remiles/providers/auth_provider.dart';
import 'package:remiles/models/notification_model.dart';
import 'package:remiles/services/notification_service.dart';
import 'package:intl/intl.dart';

class NoNotificationPage extends StatefulWidget {
  const NoNotificationPage({super.key});

  @override
  State<NoNotificationPage> createState() => _NoNotificationPageState();
}

class _NoNotificationPageState extends State<NoNotificationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final firebaseUser = authProvider.firebaseUser;
      if (firebaseUser != null) {
        final notificationProvider = Provider.of<NotificationProvider>(
          context,
          listen: false,
        );
        notificationProvider.initialize(firebaseUser.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          TopNavigationBar(context),
          Expanded(
            child: Consumer<NotificationProvider>(
              builder: (context, notificationProvider, child) {
                if (notificationProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (notificationProvider.notifications.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 200.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 120,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No Notifications",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    if (notificationProvider.hasUnreadNotifications)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: Colors.blue.shade50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${notificationProvider.unreadCount} unread notification${notificationProvider.unreadCount == 1 ? '' : 's'}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                notificationProvider.markAllAsRead();
                              },
                              child: const Text('Mark all as read'),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: notificationProvider.notifications.length,
                        itemBuilder: (context, index) {
                          final notification =
                              notificationProvider.notifications[index];
                          return _buildNotificationCard(
                            context,
                            notification,
                            notificationProvider,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationModel notification,
    NotificationProvider provider,
  ) {
    final dateFormat = DateFormat('MMM d, y • h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: notification.isRead ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: notification.isRead
              ? Colors.transparent
              : Colors.blue.shade200,
          width: notification.isRead ? 0 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            provider.markAsRead(notification.id);
          }
          NotificationService().handleNotificationTap(notification);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6, right: 12),
                decoration: BoxDecoration(
                  color: notification.isRead ? Colors.transparent : Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: notification.isRead
                            ? FontWeight.w500
                            : FontWeight.bold,
                        color: notification.isRead
                            ? Colors.grey.shade800
                            : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dateFormat.format(notification.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: Colors.grey.shade400,
                onPressed: () {
                  provider.deleteNotification(notification.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
