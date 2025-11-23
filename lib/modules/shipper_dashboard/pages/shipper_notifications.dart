import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:Remiles/providers/notification_provider.dart';
import 'package:Remiles/providers/auth_provider.dart';
import 'package:Remiles/models/notification_model.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ShipperNotifications(),
  ));
}

class ShipperNotifications extends StatefulWidget {
  const ShipperNotifications({super.key});

  @override
  State<ShipperNotifications> createState() => _ShipperNotificationsState();
}

class _ShipperNotificationsState extends State<ShipperNotifications>
    with TickerProviderStateMixin {
  int _selectedTab = 4; // More tab

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final firebaseUser = authProvider.firebaseUser;
      if (firebaseUser != null) {
        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
        notificationProvider.initialize(firebaseUser.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isTabletOrDesktop = MediaQuery.of(context).size.width > 600;
    const sidePadding = 470.0;
    const topPanelColor = Color(0xFF386544);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF6),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top section with background image and icons (unified)
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: isTabletOrDesktop ? sidePadding : 0.0),
                child: Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: topPanelColor,
                    image: const DecorationImage(
                      image: AssetImage('assets/top_leather.png'),
                      fit: BoxFit.fill,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Image.asset('assets/remileswhite.png', height: 60),
                        const Spacer(),
                        _buildTopIconWithLabel(Icons.school, 'Academy'),
                        _buildTopIconWithLabel(Icons.help_outline, 'Support'),
                        _buildTopIconWithLabel(Icons.message, 'Messages'),
                        _buildNotificationIconWithBadge(context),
                      ],
                    ),
                  ),
                ),
              ),

              // Main content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: isTabletOrDesktop ? 100.0 : 20.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: _buildNotificationsList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: isTabletOrDesktop ? sidePadding : 0.0),
        child: Container(
          height: 100,
          decoration: const BoxDecoration(
            color: Color(0xFF064232),
            image: DecorationImage(
              image: AssetImage('assets/nav_leather.png'),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(65),
              topRight: Radius.circular(65),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(50),
              topRight: Radius.circular(50),
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedTab,
              onTap: (index) {
                setState(() {
                  _selectedTab = index;
                });
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFFFFFBDF),
              unselectedItemColor: const Color(0xFFFFFBDF).withOpacity(0.6),
              selectedLabelStyle: const TextStyle(fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home, size: 26),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_cart, size: 29),
                  label: 'Manage Loads',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.storefront, size: 30.82),
                  label: 'Marketplace',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person, size: 31.37),
                  label: 'Profile',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.more_horiz, size: 25),
                  label: 'More',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopIconWithLabel(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 25),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationIconWithBadge(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        final hasUnread = notificationProvider.hasUnreadNotifications;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                children: [
                  Image.asset(
                    'assets/notifications.png',
                    height: 25,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (hasUnread)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF4949),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationsList() {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        if (notificationProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (notificationProvider.notifications.isEmpty) {
          return Center(
            child: _buildNoNotificationsCard(),
          );
        }

        return Column(
          children: [
            if (notificationProvider.hasUnreadNotifications)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
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
                itemCount: notificationProvider.notifications.length,
                itemBuilder: (context, index) {
                  final notification = notificationProvider.notifications[index];
                  return _buildNotificationCard(context, notification, notificationProvider);
                },
              ),
            ),
          ],
        );
      },
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
          color: notification.isRead ? Colors.transparent : Colors.blue.shade200,
          width: notification.isRead ? 0 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            provider.markAsRead(notification.id);
          }
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
                        fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                        color: notification.isRead ? Colors.grey.shade800 : Colors.black,
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

  Widget _buildNoNotificationsCard() {
    return Container(
      width: 148,
      height: 205,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/notifications.png',
            height: 80,
            color: const Color(0xFF979797),
          ),
          const SizedBox(height: 10),
          const Text(
            'No Notifications',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Color(0xFF979797),
            ),
          ),
        ],
      ),
    );
  }
}
