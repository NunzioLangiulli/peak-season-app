import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/copy_service.dart';
import '../l10n/strings.dart';
import '../models/app_enums.dart';
import '../models/notification_prefs.dart';
import 'notification_content.dart';

/// Notifiche locali (nessun server, funzionano offline):
/// - modalità spesa: notifica fissa con gli alimenti di stagione;
/// - dopo la chiusura, notifica con i consigli di conservazione;
/// - avvisi "picco di stagione" programmati il 1° di ogni mese alle 9.
///
/// Su web (anteprime) non fa nulla: [isSupported] è false.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  static const shoppingId = 100;
  static const storageTipsId = 101;
  static const _peakIdBase = 2000;
  static const closeActionId = 'close_shopping';

  static const _chShopping = 'shopping_mode';
  static const _chTips = 'storage_tips';
  static const _chPeak = 'peak_season';
  static const _smallIcon = 'ic_notification';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Chiamata quando l'utente tocca una notifica o un suo pulsante con
  /// l'app aperta (o la apre). Impostata da `main.dart`.
  void Function(NotificationResponse response)? onResponse;

  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> init() async {
    if (!isSupported || _ready) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/Rome'));
    }
    await _plugin.initialize(
      settings: _settings,
      onDidReceiveNotificationResponse: (r) => onResponse?.call(r),
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );
    _ready = true;
  }

  static const _settings = InitializationSettings(
    android: AndroidInitializationSettings(_smallIcon),
    iOS: DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    ),
  );

  /// Payload della notifica che ha aperto l'app (null se aperta normalmente).
  Future<NotificationResponse?> launchResponse() async {
    if (!isSupported) return null;
    final d = await _plugin.getNotificationAppLaunchDetails();
    return (d?.didNotificationLaunchApp ?? false) ? d!.notificationResponse : null;
  }

  /// Chiede il permesso (Android 13+, iOS). Restituisce false se negato.
  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? true;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, badge: false, sound: true) ?? false;
  }

  // --- Modalità spesa -----------------------------------------------------

  /// Mostra o aggiorna la notifica fissa. Su Android è "ongoing": fino ad
  /// Android 13 si toglie solo con "Chiudi", da Android 14 anche con uno swipe
  /// (l'app se ne accorge con [isShoppingVisible]). iOS non ha notifiche
  /// fisse: lì è una notifica normale (per una vera notifica persistente
  /// servirebbe una Live Activity, da valutare).
  Future<void> showShopping(NotificationContent c, S s) async {
    if (!isSupported) return;
    await _plugin.show(
      id: shoppingId,
      title: c.title,
      body: c.body,
      payload: c.payload,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _chShopping,
          s.notifChannelShopping,
          importance: Importance.low, // niente suono a ogni aggiornamento
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
          showWhen: false,
          visibility: NotificationVisibility.public, // leggibile dalla schermata di blocco
          category: AndroidNotificationCategory.reminder,
          color: const Color(0xFF2E7D32),
          styleInformation: InboxStyleInformation(
            c.lines,
            htmlFormatLines: true,
            contentTitle: c.title,
            summaryText: c.summary,
          ),
          actions: [
            AndroidNotificationAction(
              closeActionId,
              s.notifClose,
              cancelNotification: true,
              showsUserInterface: false,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(presentSound: false, interruptionLevel: InterruptionLevel.passive),
      ),
    );
  }

  Future<void> cancelShopping() async {
    if (!isSupported) return;
    await _plugin.cancel(id: shoppingId);
  }

  /// Vero se la notifica fissa è ancora visibile (Android). Su iOS non
  /// si può sapere: si usa lo stato salvato.
  Future<bool?> isShoppingVisible() async {
    if (!isSupported || defaultTargetPlatform != TargetPlatform.android) return null;
    final active = await _plugin.getActiveNotifications();
    return active.any((n) => n.id == shoppingId);
  }

  // --- Avvisi picco di stagione ------------------------------------------

  /// Cancella e riprogramma gli avvisi dei prossimi 12 mesi. Chiamata
  /// quando cambiano zona, preferiti, "non lo mangio" o la modalità.
  Future<void> reschedulePeak({
    required NotificationContentBuilder builder,
    required PeakNotifMode mode,
    required Set<String> favorites,
    required S s,
    DateTime? now,
  }) async {
    if (!isSupported) return;
    for (var i = 0; i < 12; i++) {
      await _plugin.cancel(id: _peakIdBase + i);
    }
    if (mode == PeakNotifMode.off) return;
    final today = now ?? DateTime.now();
    for (var i = 1; i <= 12; i++) {
      final first = DateTime(today.year, today.month + i, 1, 9);
      final month = first.month - 1;
      final items = builder.enteringPeak(month, mode: mode, favorites: favorites);
      if (items.isEmpty) continue;
      final c = builder.peak(month, items);
      await _plugin.zonedSchedule(
        id: _peakIdBase + month,
        scheduledDate: tz.TZDateTime(tz.local, first.year, first.month, 1, 9),
        title: c.title,
        body: c.body,
        payload: c.payload,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _chPeak,
            s.notifChannelPeak,
            importance: Importance.defaultImportance,
            color: const Color(0xFF1B5E20),
            styleInformation: InboxStyleInformation(c.lines, contentTitle: c.title),
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    }
  }
}

/// Testo e invio della notifica "consigli di conservazione", subito o dopo
/// [delayMinutes] minuti. Funzione statica perché la usa anche l'isolate in
/// background. Il ritardo è relativo, quindi basta l'ora UTC (niente fuso).
Future<void> showStorageTipsNotification(
  FlutterLocalNotificationsPlugin plugin,
  S s, {
  int delayMinutes = 0,
}) async {
  final details = NotificationDetails(
    android: AndroidNotificationDetails(
      NotificationService._chTips,
      s.notifChannelTips,
      importance: Importance.defaultImportance,
      color: const Color(0xFF2E7D32),
    ),
    iOS: const DarwinNotificationDetails(),
  );
  if (delayMinutes <= 0) {
    await plugin.show(
      id: NotificationService.storageTipsId,
      title: s.notifStorageTitle,
      body: s.notifStorageBody,
      payload: NotificationPayload.openStorage,
      notificationDetails: details,
    );
    return;
  }
  tzdata.initializeTimeZones();
  await plugin.zonedSchedule(
    id: NotificationService.storageTipsId,
    scheduledDate: tz.TZDateTime.now(tz.UTC).add(Duration(minutes: delayMinutes)),
    title: s.notifStorageTitle,
    body: s.notifStorageBody,
    payload: NotificationPayload.openStorage,
    notificationDetails: details,
    // Allarme non esatto: niente permesso speciale, Android può spostarlo di
    // qualche minuto per risparmiare batteria (spiegato nelle Impostazioni).
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  );
}

/// Pulsante "Chiudi" premuto con l'app chiusa o in background: gira in un
/// isolate separato, quindi legge le preferenze da disco.
@pragma('vm:entry-point')
Future<void> notificationBackgroundHandler(NotificationResponse response) async {
  if (response.actionId != NotificationService.closeActionId) return;
  DartPluginRegistrant.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(PrefKeys.shoppingModeActive, false);
  if (prefs.getBool(PrefKeys.storageTipsAfterShopping) ?? true) {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(settings: NotificationService._settings);
    WidgetsFlutterBinding.ensureInitialized();
    await CopyService.load();
    final s = S(AppLanguage.fromCode(prefs.getString(PrefKeys.language)));
    await showStorageTipsNotification(
      plugin,
      s,
      delayMinutes: prefs.getInt(PrefKeys.storageTipsDelayMinutes) ?? 0,
    );
  }
}

/// Accesso al plugin per [showStorageTipsNotification] dall'app in primo piano.
FlutterLocalNotificationsPlugin notificationPlugin() => NotificationService.instance._plugin;
