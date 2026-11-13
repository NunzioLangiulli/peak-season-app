import 'package:flutter/material.dart';

/// Navigation requests coming from outside the widget tree
/// (tapping a notification): the shell listens to them and switches tab or opens pages.
class AppNavigation extends ChangeNotifier {
  final navigatorKey = GlobalKey<NavigatorState>();

  int _tab = 0;
  int get tab => _tab;

  /// Page to open on top of the shell (consumed by the shell).
  String? pendingRoute;

  /// Month to select on Home ("peak season" alert).
  int? pendingMonth;

  static const routeStorageTips = 'storage-tips';

  void selectTab(int i) {
    if (i == _tab) return;
    _tab = i;
    notifyListeners();
  }

  void open({int? tab, String? route, int? month}) {
    navigatorKey.currentState?.popUntil((r) => r.isFirst);
    if (tab != null) _tab = tab;
    pendingRoute = route;
    pendingMonth = month;
    notifyListeners();
  }
}
