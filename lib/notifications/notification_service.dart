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

/// Local notifications (no server, they work offline):
/// - shopping mode: persistent notification with in-season products;
/// - after closing it, a notification with storage tips;
/// - "peak season" alerts scheduled on the 1st of every month at 9 a.m.
///
/// On the web (previews) it does nothing: [isSupported] is false.
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

  /// Called when the user taps a notification or one of its buttons with
  /// the app open (or opens it). Set by `main.dart`.
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

  /// Payload of the notification that opened the app (null if opened normally).
  Future<NotificationResponse?> launchResponse() async {
    if (!isSupported) return null;
    final d = await _plugin.getNotificationAppLaunchDetails();
    return (d?.didNotificationLaunchApp ?? false) ? d!.notificationResponse : null;
  }

  /// Asks for permission (Android 13+, iOS). Returns false if denied.
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

  // --- Shopping mode -------------------------------------------------------

  /// Shows or updates the persistent notification. On Android it is "ongoing": up to
  /// Android 13 it can be removed only with "Close", from Android 14 also with a swipe
  /// (the app notices through [isShoppingVisible]). iOS has no persistent
  /// notifications: there it is a normal notification (a truly persistent one
  /// would need a Live Activity, to be evaluated).
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
          importance: Importance.low, // no sound on every update
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
          showWhen: false,
          visibility: NotificationVisibility.public, // readable from the lock screen
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

  /// True if the persistent notification is still visible (Android). On iOS it
  /// cannot be known: the saved state is used.
  Future<bool?> isShoppingVisible() async {
    if (!isSupported || defaultTargetPlatform != TargetPlatform.android) return null;
    final active = await _plugin.getActiveNotifications();
    return active.any((n) => n.id == shoppingId);
  }

  // --- Peak season alerts -------------------------------------------------

  /// Cancels and reschedules the alerts for the next 12 months. Called
  /// when the zone, favourites, "I don't eat it" or the mode change.
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

/// Text and sending of the "storage tips" notification, immediately or after
/// [delayMinutes] minutes. Static function because it is also used by the isolate in
/// the background. The delay is relative, so UTC time is enough (no time zone).
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
    // Inexact alarm: no special permission needed, Android may shift it by
    // a few minutes to save battery (explained in Settings).
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  );
}

/// "Close" button pressed with the app closed or in the background: runs in a
/// separate isolate, so it reads the preferences from disk.
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

/// Plugin access for [showStorageTipsNotification] from the app in the foreground.
FlutterLocalNotificationsPlugin notificationPlugin() => NotificationService.instance._plugin;
