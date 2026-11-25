import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// iPhone "shopping mode" as a Live Activity (lock screen and Dynamic Island),
/// iOS 16.1 or later. iOS has no persistent notifications: this is its
/// equivalent. The Swift side is ios/Runner/LiveActivityBridge.swift; the
/// layout is in ios/PeakSeasonLiveActivity/.
///
/// The content is the same as the Android notification: lines with `<b>`
/// tags, turned here into runs of plain and bold text.
class LiveActivity {
  LiveActivity._() {
    if (_onIOS) _channel.setMethodCallHandler(_onCall);
  }
  static final instance = LiveActivity._();

  static const _channel = MethodChannel('peak_season/live_activity');

  /// ActivityKit accepts at most 4 KB of data: lines beyond this are left out.
  static const _maxBytes = 3000;

  /// Called when the Live Activity is tapped (opens the shopping list). Set by
  /// `NotificationController`.
  VoidCallback? onOpenShopping;

  static bool get _onIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<dynamic> _onCall(MethodCall call) async {
    if (call.method == 'openShopping') onOpenShopping?.call();
  }

  /// True if this iPhone can show Live Activities and the user has not
  /// turned them off in Settings.
  Future<bool> isSupported() async {
    if (!_onIOS) return false;
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Starts the Live Activity, or updates the one already running.
  /// Returns false if iOS refused it.
  Future<bool> show(List<String> lines) async {
    if (!_onIOS) return false;
    try {
      return await _channel.invokeMethod<bool>('show', {'lines': toRuns(lines)}) ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> end() async {
    if (!_onIOS) return;
    try {
      await _channel.invokeMethod<void>('end');
    } on PlatformException {
      // nothing to end
    }
  }

  /// False if the user removed it from the lock screen.
  Future<bool> isActive() async {
    if (!_onIOS) return false;
    try {
      return await _channel.invokeMethod<bool>('isActive') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// True once if the app was opened by tapping the Live Activity.
  Future<bool> takePendingOpen() async {
    if (!_onIOS) return false;
    try {
      return await _channel.invokeMethod<bool>('takePendingOpen') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// `"<b>Peak:</b> Apple, Pear"` → `[{t: "Peak:", b: true}, {t: " Apple, Pear", b: false}]`,
  /// one list of runs per line, cut to stay under the ActivityKit size limit.
  @visibleForTesting
  static List<List<Map<String, Object>>> toRuns(List<String> lines) {
    final out = <List<Map<String, Object>>>[];
    var size = 0;
    for (final line in lines) {
      final runs = <Map<String, Object>>[];
      var bold = false;
      for (final part in line.split(RegExp(r'(?=</?b>)|(?<=</?b>)'))) {
        if (part == '<b>') {
          bold = true;
        } else if (part == '</b>') {
          bold = false;
        } else if (part.isNotEmpty) {
          runs.add({'t': part, 'b': bold});
        }
      }
      final bytes = utf8.encode(jsonEncode(runs)).length;
      if (size + bytes > _maxBytes) break;
      size += bytes;
      out.add(runs);
    }
    return out;
  }
}
