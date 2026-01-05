import 'package:flutter/material.dart';

class NavigatorService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static BuildContext? get context => navigatorKey.currentContext;

  static Future<T?>? pushNamed<T>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  static Future<T?>? push<T>(Route<T> route) {
    return navigatorKey.currentState?.push<T>(route);
  }

  static void pop<T>([T? result]) {
    navigatorKey.currentState?.pop<T>(result);
  }
}
