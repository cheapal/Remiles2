import 'package:flutter/foundation.dart';
import 'package:remiles/modules/carrier_dashboard/views/dashboard/pages/academy.dart';
import 'package:remiles/modules/carrier_dashboard/views/dashboard/pages/messages_page.dart';
import 'package:remiles/modules/carrier_dashboard/views/dashboard/pages/notification.dart';
import 'package:remiles/modules/carrier_dashboard/views/dashboard/pages/support.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:remiles/providers/notification_provider.dart';

Widget TopNavigationBar(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isSmallScreen = screenWidth < 375; // iPhone SE and similar
  final isVerySmallScreen = screenWidth < 360; // Very small screens

  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: isVerySmallScreen
          ? 8
          : isSmallScreen
          ? 12
          : 16,
      vertical: 12,
    ),
    decoration: BoxDecoration(
      color: Color(0xFF0A6837), // dark green background
      image: DecorationImage(
        image: AssetImage('assets/leather_square.png'),
        fit: BoxFit.cover,
      ),
    ),
    child: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                flex: isSmallScreen ? 2 : 3,
                fit: FlexFit.loose,
                child: SvgPicture.asset(
                  'assets/remiles.svg',
                  width: isVerySmallScreen
                      ? 70
                      : isSmallScreen
                      ? 80
                      : null,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                flex: isSmallScreen ? 5 : 4,
                fit: FlexFit.tight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: _navItem(
                        context,
                        icon: SvgPicture.asset(
                          "assets/academy_top_nav.svg",
                          width: isVerySmallScreen
                              ? 18
                              : isSmallScreen
                              ? 20
                              : 24,
                          height: isVerySmallScreen
                              ? 18
                              : isSmallScreen
                              ? 20
                              : 24,
                        ),
                        label: "Academy",
                        fontSize: isVerySmallScreen
                            ? 9
                            : isSmallScreen
                            ? 10
                            : 12,
                        page: const AcademyScreen(),
                      ),
                    ),
                    SizedBox(
                      width: isVerySmallScreen
                          ? 4
                          : isSmallScreen
                          ? 6
                          : 8,
                    ),
                    Flexible(
                      child: _navItem(
                        context,
                        icon: SvgPicture.asset(
                          "assets/support_top_nav.svg",
                          width: isVerySmallScreen
                              ? 18
                              : isSmallScreen
                              ? 20
                              : 24,
                          height: isVerySmallScreen
                              ? 18
                              : isSmallScreen
                              ? 20
                              : 24,
                        ),
                        label: "Support",
                        fontSize: isVerySmallScreen
                            ? 9
                            : isSmallScreen
                            ? 10
                            : 12,
                        page: SupportScreen(),
                      ),
                    ),
                    SizedBox(
                      width: isVerySmallScreen
                          ? 4
                          : isSmallScreen
                          ? 6
                          : 8,
                    ),
                    Flexible(
                      child: _navItem(
                        context,
                        icon: SvgPicture.asset(
                          "assets/messages_top_nav.svg",
                          width: isVerySmallScreen
                              ? 18
                              : isSmallScreen
                              ? 20
                              : 24,
                          height: isVerySmallScreen
                              ? 18
                              : isSmallScreen
                              ? 20
                              : 24,
                        ),
                        label: "Messages",
                        fontSize: isVerySmallScreen
                            ? 9
                            : isSmallScreen
                            ? 10
                            : 12,
                        page: const MessagesPage(),
                      ),
                    ),
                    SizedBox(
                      width: isVerySmallScreen
                          ? 4
                          : isSmallScreen
                          ? 6
                          : 8,
                    ),
                    Flexible(
                      child: _notificationNavItem(
                        context,
                        icon: SvgPicture.asset(
                          "assets/notification_top_nav.svg",
                          width: isVerySmallScreen
                              ? 18
                              : isSmallScreen
                              ? 20
                              : 24,
                          height: isVerySmallScreen
                              ? 18
                              : isSmallScreen
                              ? 20
                              : 24,
                        ),
                        label: "Notifications",
                        fontSize: isVerySmallScreen
                            ? 9
                            : isSmallScreen
                            ? 10
                            : 12,
                        page: const NoNotificationPage(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

Widget _navItem(
  BuildContext context, {
  required SvgPicture icon,
  required String label,
  required Widget page,
  double fontSize = 12,
}) {
  return InkWell(
    onTap: () {
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    },
    borderRadius: BorderRadius.circular(8),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        icon,
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(color: Colors.white, fontSize: fontSize),
          ),
        ),
      ],
    ),
  );
}

Widget _notificationNavItem(
  BuildContext context, {
  required SvgPicture icon,
  required String label,
  required Widget page,
  double fontSize = 12,
}) {
  return Consumer<NotificationProvider>(
    builder: (context, notificationProvider, child) {
      final hasUnread = notificationProvider.hasUnreadNotifications;
      final unreadCount = notificationProvider.unreadCount;

      return InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        },
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                icon,
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(color: Colors.white, fontSize: fontSize),
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
