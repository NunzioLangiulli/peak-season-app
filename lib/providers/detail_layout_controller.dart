import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Blocks of the product page, in the wireframe's default order.
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

/// How a block appears when the product page opens.
enum SectionMode {
  /// Open (can be collapsed by tapping the title).
  open,

  /// Collapsed: only the title is visible, it opens when needed.
  collapsed,

  /// Completely hidden.
  hidden;

  static SectionMode fromName(String? n) =>
      values.firstWhere((v) => v.name == n, orElse: () => SectionMode.open);
}

/// Order and mode of the product page blocks (Settings).
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

  /// Moves a block (indices already adjusted for the removed element).
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
