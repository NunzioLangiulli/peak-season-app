import 'package:flutter/material.dart';

/// Richieste di navigazione che arrivano da fuori dell'albero dei widget
/// (tocco su una notifica): la shell le ascolta e cambia tab o apre pagine.
class AppNavigation extends ChangeNotifier {
  final navigatorKey = GlobalKey<NavigatorState>();

  int _tab = 0;
  int get tab => _tab;

  /// Pagina da aprire sopra la shell (consumata dalla shell).
  String? pendingRoute;

  /// Mese da selezionare nella Home (avviso "picco di stagione").
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
