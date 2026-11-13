import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/food_repository.dart';
import '../data/seasonality_resolver.dart';
import '../models/app_enums.dart';
import '../models/food_item.dart';
import '../models/season_state.dart';
import 'library_controller.dart';

/// Product ready for the UI: calendar already resolved for the user's zone.
class FoodEntry {
  const FoodEntry(this.item, this.calendar);
  final FoodItem item;
  final SeasonCalendar calendar;
}

/// State of the Peak Season screen: month, view, filters, search.
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

  /// Advanced filters by database code: `ripening_type`,
  /// `primary_location`, carbon and water footprint level.
  Set<String> get ripening => Set.unmodifiable(_ripening);
  Set<String> get storage => Set.unmodifiable(_storage);
  Set<String> get carbon => Set.unmodifiable(_carbon);
  Set<String> get water => Set.unmodifiable(_water);
  bool get dopOnly => _dopOnly;
  bool get showHidden => _showHidden;

  /// If true, products without data for the zone are in the main
  /// list (at the bottom, with grey dots); otherwise in a separate,
  /// collapsed "No Data for This Zone" section.
  bool get includeNoData => _includeNoData;
  String get query => _query;
  bool get searchOpen => _searchOpen;

  /// Categories grouped under "Other" in the quick bar.
  static const otherCategories = {FoodCategory.erbeSpezie, FoodCategory.funghi, FoodCategory.cereali};

  /// Buttons lit in the quick bar, derived from the chosen categories
  /// (also from the advanced filters): "Other" lights up if at least one of the
  /// its sub-categories.
  Set<QuickCategory> get quickCategories {
    if (_categories.isEmpty) return {QuickCategory.all};
    return {
      if (_categories.contains(FoodCategory.frutta)) QuickCategory.fruit,
      if (_categories.contains(FoodCategory.verdura)) QuickCategory.vegetables,
      if (_categories.any(otherCategories.contains)) QuickCategory.other,
    };
  }

  /// Sub-categories of "Other" to show as tags under the bar: only if
  /// not all three are selected (with all three the lit button is enough).
  Set<FoodCategory> get otherCategoryTags {
    final sel = _categories.where(otherCategories.contains).toSet();
    return sel.length == otherCategories.length ? const {} : sel;
  }

  /// Number of active filters (badge on the filter icon): each chosen
  /// value counts as one, including the quick-bar categories
  /// (e.g. Fruit + Other = 4).
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

  /// Tap on a quick-bar button: All clears the categories,
  /// Fruit and Vegetables toggle on and off, Other selects (or removes)
  /// all three of its sub-categories.
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

  /// Main list for the month: filters and sorting applied.
  /// Products without data for the zone are excluded (they go to
  /// [noDataEntries]) unless [includeNoData] is on: a product without
  /// data must never look "in season" mixed with the others.
  List<FoodEntry> visibleEntries({
    required FoodDatabase db,
    required LibraryController library,
    required SeasonalityResolver resolver,
    required AppLanguage language,
  }) =>
      computeLists(db: db, library: library, resolver: resolver, language: language).main;

  /// Separate "No Data for This Zone" section (empty if [includeNoData]
  /// is on or if a seasonal-state filter is active).
  List<FoodEntry> noDataEntries({
    required FoodDatabase db,
    required LibraryController library,
    required SeasonalityResolver resolver,
    required AppLanguage language,
  }) =>
      computeLists(db: db, library: library, resolver: resolver, language: language).noData;

  /// 153 products: fast enough to redo on every build.
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

  /// peak → early → in season → end → not grown → out → no data,
  /// then alphabetical in the active language.
  static void sortBySeason(List<FoodEntry> list, int month, AppLanguage lang) {
    list.sort((a, b) {
      final r = a.calendar.at(month).sortRank.compareTo(b.calendar.at(month).sortRank);
      if (r != 0) return r;
      return normalizeForSearch(a.item.name.of(lang))
          .compareTo(normalizeForSearch(b.item.name.of(lang)));
    });
  }
}
