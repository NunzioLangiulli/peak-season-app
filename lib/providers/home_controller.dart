import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/food_repository.dart';
import '../data/seasonality_resolver.dart';
import '../models/app_enums.dart';
import '../models/food_item.dart';
import '../models/season_state.dart';
import 'library_controller.dart';

/// Alimento pronto per la UI: calendario già risolto per la zona dell'utente.
class FoodEntry {
  const FoodEntry(this.item, this.calendar);
  final FoodItem item;
  final SeasonCalendar calendar;
}

/// Stato della schermata Peak Season: mese, vista, filtri, ricerca.
class HomeController extends ChangeNotifier {
  HomeController(this._prefs, {DateTime? now})
      : _month = (now ?? DateTime.now()).month - 1,
        currentMonth = (now ?? DateTime.now()).month - 1 {
    _viewMode = HomeViewMode.fromName(_prefs.getString(_kView));
    _showHidden = _prefs.getBool(_kShowHidden) ?? false;
    _includeNoData = _prefs.getBool(_kIncludeNoData) ?? false;
  }

  static const _kView = 'homeViewMode';
  static const _kShowHidden = 'showHiddenTemporarily';
  static const _kIncludeNoData = 'includeFoodsWithoutData';

  final SharedPreferences _prefs;

  /// Mese reale all'avvio (0-11).
  final int currentMonth;
  int _month;
  late HomeViewMode _viewMode;
  QuickFilter _quickFilter = QuickFilter.all;
  Set<FoodCategory> _categories = {};
  Set<SeasonState> _states = {};
  Set<String> _ripening = {};
  Set<String> _storage = {};
  Set<String> _carbon = {};
  Set<String> _water = {};
  bool _dopOnly = false;
  late bool _showHidden;
  late bool _includeNoData;
  String _query = '';
  bool _searchOpen = false;

  int get month => _month;
  HomeViewMode get viewMode => _viewMode;
  QuickFilter get quickFilter => _quickFilter;
  Set<FoodCategory> get categories => Set.unmodifiable(_categories);
  Set<SeasonState> get states => Set.unmodifiable(_states);

  /// Filtri avanzati per codice del database: `ripening_type`,
  /// `primary_location`, livello dell'impronta di carbonio e idrica.
  Set<String> get ripening => Set.unmodifiable(_ripening);
  Set<String> get storage => Set.unmodifiable(_storage);
  Set<String> get carbon => Set.unmodifiable(_carbon);
  Set<String> get water => Set.unmodifiable(_water);
  bool get dopOnly => _dopOnly;
  bool get showHidden => _showHidden;

  /// Se vero, gli alimenti senza dati per la zona stanno nella lista
  /// principale (in fondo, con i pallini grigi); altrimenti in una sezione
  /// separata e chiusa "Senza Dati per Questa Zona".
  bool get includeNoData => _includeNoData;
  String get query => _query;
  bool get searchOpen => _searchOpen;

  /// Categorie raccolte sotto "Altro" nella barra rapida.
  static const otherCategories = {FoodCategory.erbeSpezie, FoodCategory.funghi, FoodCategory.cereali};

  /// Pulsanti accesi nella barra rapida, derivati dalle categorie scelte
  /// (anche dai filtri avanzati): "Altro" si accende se c'è almeno una delle
  /// sue sottocategorie.
  Set<QuickCategory> get quickCategories {
    if (_categories.isEmpty) return {QuickCategory.all};
    return {
      if (_categories.contains(FoodCategory.frutta)) QuickCategory.fruit,
      if (_categories.contains(FoodCategory.verdura)) QuickCategory.vegetables,
      if (_categories.any(otherCategories.contains)) QuickCategory.other,
    };
  }

  /// Sottocategorie di "Altro" da mostrare come tag sotto la barra: solo se
  /// non sono tutte e tre (con tutte e tre basta il pulsante acceso).
  Set<FoodCategory> get otherCategoryTags {
    final sel = _categories.where(otherCategories.contains).toSet();
    return sel.length == otherCategories.length ? const {} : sel;
  }

  /// Numero di filtri attivi (badge sull'icona dei filtri): ogni valore
  /// scelto conta uno, comprese le categorie della barra rapida
  /// (es. Frutta + Altro = 4).
  int get advancedFilterCount =>
      _categories.length +
      _states.length +
      _ripening.length +
      _storage.length +
      _carbon.length +
      _water.length +
      (_dopOnly ? 1 : 0) +
      (_showHidden ? 1 : 0) +
      (_includeNoData ? 1 : 0);

  bool get hasAnyFilter =>
      _quickFilter != QuickFilter.all ||
      _categories.isNotEmpty ||
      _states.isNotEmpty ||
      _ripening.isNotEmpty ||
      _storage.isNotEmpty ||
      _carbon.isNotEmpty ||
      _water.isNotEmpty ||
      _dopOnly ||
      _query.isNotEmpty;

  void setMonth(int m) {
    m = (m % 12 + 12) % 12;
    if (m == _month) return;
    _month = m;
    notifyListeners();
  }

  void cycleViewMode() {
    _viewMode = _viewMode.next;
    _prefs.setString(_kView, _viewMode.name);
    notifyListeners();
  }

  void setQuickFilter(QuickFilter f) {
    _quickFilter = (_quickFilter == f) ? QuickFilter.all : f;
    if (f == QuickFilter.all) _quickFilter = QuickFilter.all;
    notifyListeners();
  }

  /// Tocco su un pulsante della barra rapida: Tutti azzera le categorie,
  /// Frutta e Verdura si accendono e spengono, Altro seleziona (o toglie)
  /// tutte e tre le sue sottocategorie.
  void toggleQuickCategory(QuickCategory c) {
    final next = {..._categories};
    switch (c) {
      case QuickCategory.all:
        next.clear();
      case QuickCategory.fruit:
        if (!next.remove(FoodCategory.frutta)) next.add(FoodCategory.frutta);
      case QuickCategory.vegetables:
        if (!next.remove(FoodCategory.verdura)) next.add(FoodCategory.verdura);
      case QuickCategory.other:
        if (otherCategories.every(next.contains)) {
          next.removeAll(otherCategories);
        } else {
          next.addAll(otherCategories);
        }
    }
    _categories = next.length == FoodCategory.values.length ? {} : next;
    notifyListeners();
  }

  void toggleCategory(FoodCategory c) {
    _categories = {..._categories};
    if (!_categories.remove(c)) _categories.add(c);
    if (_categories.length == FoodCategory.values.length) _categories = {};
    notifyListeners();
  }

  void toggleState(SeasonState s) {
    _states = {..._states};
    if (!_states.remove(s)) _states.add(s);
    notifyListeners();
  }

  void _toggle(Set<String> Function() get, void Function(Set<String>) set, String code) {
    final next = {...get()};
    if (!next.remove(code)) next.add(code);
    set(next);
    notifyListeners();
  }

  void toggleRipening(String code) => _toggle(() => _ripening, (v) => _ripening = v, code);
  void toggleStorage(String code) => _toggle(() => _storage, (v) => _storage = v, code);
  void toggleCarbon(String code) => _toggle(() => _carbon, (v) => _carbon = v, code);
  void toggleWater(String code) => _toggle(() => _water, (v) => _water = v, code);

  void setDopOnly(bool v) {
    _dopOnly = v;
    notifyListeners();
  }

  void setShowHidden(bool v) {
    _showHidden = v;
    _prefs.setBool(_kShowHidden, v);
    notifyListeners();
  }

  void setIncludeNoData(bool v) {
    _includeNoData = v;
    _prefs.setBool(_kIncludeNoData, v);
    notifyListeners();
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void setSearchOpen(bool open) {
    _searchOpen = open;
    if (!open) _query = '';
    notifyListeners();
  }

  void resetAdvanced() {
    _categories = {};
    _states = {};
    _ripening = {};
    _storage = {};
    _carbon = {};
    _water = {};
    _dopOnly = false;
    _showHidden = false;
    _prefs.setBool(_kShowHidden, false);
    _includeNoData = false;
    _prefs.setBool(_kIncludeNoData, false);
    notifyListeners();
  }

  void resetAll() {
    _quickFilter = QuickFilter.all;
    _query = '';
    _searchOpen = false;
    resetAdvanced();
  }

  /// Lista principale del mese: filtri e ordinamento applicati.
  /// Gli alimenti senza dati per la zona sono esclusi (vanno in
  /// [noDataEntries]) a meno che [includeNoData] sia attivo: un alimento senza
  /// dati non deve mai sembrare "di stagione" mescolato agli altri.
  List<FoodEntry> visibleEntries({
    required FoodDatabase db,
    required LibraryController library,
    required SeasonalityResolver resolver,
    required AppLanguage language,
  }) =>
      computeLists(db: db, library: library, resolver: resolver, language: language).main;

  /// Sezione separata "Senza Dati per Questa Zona" (vuota se [includeNoData]
  /// è attivo o se è attivo un filtro per stato stagionale).
  List<FoodEntry> noDataEntries({
    required FoodDatabase db,
    required LibraryController library,
    required SeasonalityResolver resolver,
    required AppLanguage language,
  }) =>
      computeLists(db: db, library: library, resolver: resolver, language: language).noData;

  /// 153 alimenti: abbastanza veloce da rifarlo a ogni build.
  ({List<FoodEntry> main, List<FoodEntry> noData}) computeLists({
    required FoodDatabase db,
    required LibraryController library,
    required SeasonalityResolver resolver,
    required AppLanguage language,
  }) {
    final q = normalizeForSearch(_query);
    final main = <FoodEntry>[];
    final noData = <FoodEntry>[];
    for (final item in db.items) {
      if (!_showHidden && library.isDisliked(item.id)) continue;
      if (_quickFilter == QuickFilter.favorites && !library.isFavorite(item.id)) continue;
      if (_categories.isNotEmpty && !_categories.contains(item.category)) continue;
      if (_dopOnly && !item.hasDopIgp) continue;
      if (_ripening.isNotEmpty && !_ripening.contains(item.ripeningType)) continue;
      if (_storage.isNotEmpty && !_storage.contains(item.primaryLocation)) continue;
      if (_carbon.isNotEmpty && !_carbon.contains(item.carbonLevel)) continue;
      if (_water.isNotEmpty && !_water.contains(item.waterLevel)) continue;
      if (!item.matches(q)) continue;
      final cal = resolver.resolve(item);
      final entry = FoodEntry(item, cal);
      if (!cal.hasData && !_includeNoData) {
        if (_states.isEmpty) noData.add(entry);
        continue;
      }
      if (_states.isNotEmpty && !_states.contains(cal.at(_month))) continue;
      main.add(entry);
    }
    sortBySeason(main, _month, language);
    sortBySeason(noData, _month, language);
    return (main: main, noData: noData);
  }

  /// peak → primizie → in season → fine → non coltivato → fuori → nessun dato,
  /// poi alfabetico nella lingua attiva.
  static void sortBySeason(List<FoodEntry> list, int month, AppLanguage lang) {
    list.sort((a, b) {
      final r = a.calendar.at(month).sortRank.compareTo(b.calendar.at(month).sortRank);
      if (r != 0) return r;
      return normalizeForSearch(a.item.name.of(lang))
          .compareTo(normalizeForSearch(b.item.name.of(lang)));
    });
  }
}
