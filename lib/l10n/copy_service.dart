import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/app_enums.dart';

/// Interface texts read from `assets/data/ui_copy.json` (a copy of
/// `data/ui_copy.json`, edited with the Admin Studio).
///
/// Loaded once at startup ([load]); after that [t] is synchronous. A missing
/// key returns the key itself, so it stands out in the app.
/// Placeholders are in braces: `{n} prodotti` + `{'n': 3}` → `3 prodotti`.
class CopyService {
  CopyService._();

  static const asset = 'assets/data/ui_copy.json';

  /// Language used by [t] when none is passed.
  static AppLanguage language = AppLanguage.it;

  static Map<String, Map<String, String>> _strings = const {};
  static bool get isLoaded => _strings.isNotEmpty;

  static Future<void> load({AssetBundle? bundle}) async {
    if (isLoaded) return;
    final raw = await (bundle ?? rootBundle).loadString(asset);
    loadFromString(raw);
  }

  /// Used by the tests (reads the file from disk) and by [load].
  static void loadFromString(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final out = <String, Map<String, String>>{};
    for (final e in (json['strings'] as List? ?? const [])) {
      if (e is Map && e['key'] is String) {
        out[e['key'] as String] = {
          'it': '${e['it'] ?? ''}',
          'en': '${e['en'] ?? ''}',
        };
      }
    }
    _strings = out;
  }

  static bool has(String key) => _strings.containsKey(key);

  /// All keys (for the tests).
  static Iterable<String> get keys => _strings.keys;

  static final _placeholder = RegExp(r'\{(\w+)\}');

  static String t(String key, {AppLanguage? lang, Map<String, Object?> params = const {}}) {
    final entry = _strings[key];
    final l = (lang ?? language).name;
    var text = entry?[l];
    if (text == null || text.isEmpty) {
      if (kDebugMode) debugPrint('CopyService: missing text "$key" ($l)');
      return key;
    }
    if (params.isNotEmpty) {
      text = text.replaceAllMapped(
        _placeholder,
        (m) => params.containsKey(m[1]) ? '${params[m[1]]}' : m[0]!,
      );
    }
    return text;
  }
}
