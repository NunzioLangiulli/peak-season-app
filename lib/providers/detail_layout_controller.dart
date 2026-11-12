import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Blocchi della scheda alimento, nell'ordine di default del wireframe.
enum DetailSection {
  calendar,
  varieties,
  buyStore,
  nutrition,
  sustainability,
  garden,
  curiosities,
  recipes,
  links;

  static DetailSection? fromName(String n) {
    for (final v in values) {
      if (v.name == n) return v;
    }
    return null;
  }
}

/// Come appare un blocco quando si apre la scheda.
enum SectionMode {
  /// Aperto (si può chiudere toccando il titolo).
  open,

  /// Chiuso: si vede solo il titolo, si apre quando serve.
  collapsed,

  /// Nascosto del tutto.
  hidden;

  static SectionMode fromName(String? n) =>
      values.firstWhere((v) => v.name == n, orElse: () => SectionMode.open);
}

/// Ordine e modalità dei blocchi della scheda alimento (Impostazioni).
class DetailLayoutController extends ChangeNotifier {
  DetailLayoutController(this._prefs) {
    final saved = _prefs.getStringList(_kOrder);
    if (saved != null) {
      final parsed = [...saved.map(DetailSection.fromName).whereType<DetailSection>()];
      // blocchi aggiunti in versioni successive vanno in fondo
      for (final s in DetailSection.values) {
        if (!parsed.contains(s)) parsed.add(s);
      }
      _order = parsed;
    }
    for (final entry in _prefs.getStringList(_kModes) ?? const <String>[]) {
      final [name, mode] = entry.split(':').length == 2 ? entry.split(':') : ['', ''];
      final s = DetailSection.fromName(name);
      if (s != null) _modes[s] = SectionMode.fromName(mode);
    }
  }

  static const _kOrder = 'detailSectionOrder';
  static const _kModes = 'detailSectionModes';

  final SharedPreferences _prefs;
  List<DetailSection> _order = [...DetailSection.values];
  final Map<DetailSection, SectionMode> _modes = {};

  List<DetailSection> get order => List.unmodifiable(_order);
  List<DetailSection> get visibleOrder =>
      [for (final s in _order) if (modeOf(s) != SectionMode.hidden) s];
  SectionMode modeOf(DetailSection s) => _modes[s] ?? SectionMode.open;

  /// Sposta un blocco (indici già corretti per l'elemento rimosso).
  void moveItem(int oldIndex, int newIndex) {
    final s = _order.removeAt(oldIndex);
    _order.insert(newIndex, s);
    _prefs.setStringList(_kOrder, [..._order.map((e) => e.name)]);
    notifyListeners();
  }

  void setMode(DetailSection s, SectionMode m) {
    _modes[s] = m;
    _prefs.setStringList(_kModes, [for (final e in _modes.entries) '${e.key.name}:${e.value.name}']);
    notifyListeners();
  }

  void reset() {
    _order = [...DetailSection.values];
    _modes.clear();
    _prefs.remove(_kOrder);
    _prefs.remove(_kModes);
    notifyListeners();
  }
}
