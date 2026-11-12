import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/food_repository.dart';
import '../l10n/strings.dart';
import '../models/notification_prefs.dart';
import '../notifications/notification_content.dart';
import '../notifications/notification_service.dart';
import 'app_navigation.dart';
import 'library_controller.dart';
import 'settings_controller.dart';

/// Collega lo stato dell'app alle notifiche: modalità spesa (on/off e
/// aggiornamento del contenuto) e riprogrammazione degli avvisi di picco.
class NotificationController extends ChangeNotifier with WidgetsBindingObserver {
  NotificationController({
    required SharedPreferences prefs,
    required this.db,
    required this.settings,
    required this.library,
    required this.navigation,
    NotificationService? service,
    DateTime Function()? clock,
  })  : _prefs = prefs, // ignore: prefer_initializing_formals
        _service = service ?? NotificationService.instance,
        _clock = clock ?? DateTime.now {
    _shoppingActive = _prefs.getBool(PrefKeys.shoppingModeActive) ?? false;
    _service.onResponse = handleResponse;
    settings.addListener(_onDataChanged);
    library.addListener(_onDataChanged);
    WidgetsBinding.instance.addObserver(this);
    _schedulePeakSoon();
    // All'avvio lo stato salvato può essere vecchio (notifica tolta con uno
    // swipe, app chiusa forzatamente): si controlla la notifica reale.
    syncShoppingWithSystem();
  }

  final SharedPreferences _prefs;
  final FoodDatabase db;
  final SettingsController settings;
  final LibraryController library;
  final AppNavigation navigation;
  final NotificationService _service;
  final DateTime Function() _clock;

  late bool _shoppingActive;
  Timer? _debounce;

  bool get shoppingActive => _shoppingActive;
  bool get isSupported => _service.isSupported;

  S get _s => S(settings.language);

  NotificationContentBuilder get _builder => NotificationContentBuilder(
        db: db,
        resolver: settings.resolver,
        language: settings.language,
        disliked: library.dislikedIds,
      );

  /// Contenuto attuale della notifica della spesa (usato anche dalle anteprime).
  NotificationContent shoppingContent() => _builder.shopping(
        month: _clock().month - 1,
        shoppingIds: library.shoppingListIds,
        listMode: settings.shoppingListMode,
      );

  /// Attiva/disattiva la modalità spesa. Restituisce false se il permesso
  /// di notifica è stato negato.
  Future<bool> setShoppingMode(bool on) async {
    if (on && _service.isSupported && !await _service.requestPermission()) return false;
    _shoppingActive = on;
    await _prefs.setBool(PrefKeys.shoppingModeActive, on);
    notifyListeners();
    if (on) {
      await _service.showShopping(shoppingContent(), _s);
    } else {
      await _service.cancelShopping();
    }
    return true;
  }

  /// Tocco su una notifica (o su "Chiudi") con l'app in esecuzione.
  void handleResponse(NotificationResponse r) {
    if (r.actionId == NotificationService.closeActionId) {
      _shoppingActive = false;
      _prefs.setBool(PrefKeys.shoppingModeActive, false);
      notifyListeners();
      if (settings.storageTipsAfterShopping) {
        showStorageTipsNotification(notificationPlugin(), _s, delayMinutes: settings.storageTipsDelay);
      }
      return;
    }
    openPayload(r.payload);
  }

  void openPayload(String? payload) {
    switch (payload) {
      case NotificationPayload.openShopping:
        navigation.open(tab: 1);
      case NotificationPayload.openSeason:
        navigation.open(tab: 0);
      case NotificationPayload.openStorage:
        navigation.open(route: AppNavigation.routeStorageTips);
      case final String p when p.startsWith('peak:'):
        navigation.open(tab: 0, month: int.tryParse(p.substring(5)));
    }
  }

  void _onDataChanged() {
    // Lista, lingua, zona o modalità cambiate: aggiorna la notifica aperta e
    // riprogramma gli avvisi (con un piccolo ritardo per raggruppare i tocchi).
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      if (_shoppingActive) await _service.showShopping(shoppingContent(), _s);
      await _reschedulePeak();
    });
  }

  PeakNotifMode? _lastMode;

  void _schedulePeakSoon() => Future<void>.delayed(const Duration(seconds: 2), _reschedulePeak);

  Future<void> _reschedulePeak() async {
    final mode = settings.peakNotifMode;
    if (mode != PeakNotifMode.off && _lastMode != mode) {
      await _service.requestPermission();
    }
    _lastMode = mode;
    await _service.reschedulePeak(
      builder: _builder,
      mode: mode,
      favorites: library.favoriteIds,
      s: _s,
      now: _clock(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) syncShoppingWithSystem(refresh: true);
  }

  /// Allinea il pulsante "Sono a fare la spesa" alla notifica reale.
  /// "Chiudi" premuto in background scrive da un altro isolate (si rilegge
  /// da disco); uno swipe sulla notifica non avvisa l'app, quindi su Android
  /// si guarda se la notifica è ancora visibile. Lo stato spento viene anche
  /// salvato: riaprendo l'app il pulsante non si riaccende da solo.
  @visibleForTesting
  Future<void> syncShoppingWithSystem({bool refresh = false}) async {
    await _prefs.reload();
    final saved = _prefs.getBool(PrefKeys.shoppingModeActive) ?? false;
    var active = saved;
    final visible = await _service.isShoppingVisible();
    if (visible != null) active = active && visible;
    if (saved != active) await _prefs.setBool(PrefKeys.shoppingModeActive, active);
    if (active != _shoppingActive) {
      _shoppingActive = active;
      notifyListeners();
    } else if (active && refresh) {
      await _service.showShopping(shoppingContent(), _s); // il mese può essere cambiato
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    settings.removeListener(_onDataChanged);
    library.removeListener(_onDataChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
