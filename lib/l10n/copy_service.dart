import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/app_enums.dart';

/// Testi dell'interfaccia letti da `assets/data/ui_copy.json` (copia di
/// `data/ui_copy.json`, che l'utente modifica con scripts/copy_editor.py).
///
/// Si carica una volta all'avvio ([load]); poi [t] è sincrono. Una chiave
/// mancante restituisce la chiave stessa, così salta all'occhio nell'app.
/// I segnaposto sono tra graffe: `{n} prodotti` + `{'n': 3}` → `3 prodotti`.
class CopyService {
  CopyService._();

  static const asset = 'assets/data/ui_copy.json';

  /// Lingua usata da [t] quando non se ne passa una.
  static AppLanguage language = AppLanguage.it;

  static Map<String, Map<String, String>> _strings = const {};
  static bool get isLoaded => _strings.isNotEmpty;

  static Future<void> load({AssetBundle? bundle}) async {
    if (isLoaded) return;
    final raw = await (bundle ?? rootBundle).loadString(asset);
    loadFromString(raw);
  }

  /// Usato dai test (legge il file dal disco) e da [load].
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

  /// Tutte le chiavi (per i test).
  static Iterable<String> get keys => _strings.keys;

  static final _placeholder = RegExp(r'\{(\w+)\}');

  static String t(String key, {AppLanguage? lang, Map<String, Object?> params = const {}}) {
    final entry = _strings[key];
    final l = (lang ?? language).name;
    var text = entry?[l];
    if (text == null || text.isEmpty) {
      if (kDebugMode) debugPrint('CopyService: testo mancante "$key" ($l)');
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
