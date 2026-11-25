import '../data/food_repository.dart';
import '../data/seasonality_resolver.dart';
import '../l10n/strings.dart';
import '../models/app_enums.dart';
import '../models/food_item.dart';
import '../models/notification_prefs.dart';
import '../models/season_state.dart';
import '../providers/home_controller.dart';

/// Text of a notification, independent of the plugin (so it is testable and
/// reusable for previews).
class NotificationContent {
  const NotificationContent({
    required this.title,
    required this.body,
    required this.lines,
    required this.payload,
    this.summary,
  });

  /// Title (null = no title: Android shows only the app name).
  final String? title;

  /// Riga unica, mostrata a notifica chiusa.
  final String body;

  /// Lines of the expanded notification (InboxStyle), with `<b>` for highlighting.
  final List<String> lines;
  final String payload;
  final String? summary;
}

/// Notification payloads: they tell the app what to open when tapped.
class NotificationPayload {
  static const openSeason = 'open:season';
  static const openShopping = 'open:shopping';
  static const openStorage = 'open:storage';
  static String peak(int month) => 'peak:$month';
}

class NotificationContentBuilder {
  NotificationContentBuilder({required this.db, required this.resolver, required this.language, required this.disliked})
    : s = S(language);

  final FoodDatabase db;
  final SeasonalityResolver resolver;
  final AppLanguage language;
  final Set<String> disliked;
  final S s;

  static const _maxNamesPerLine = 6;

  /// Name for notifications: without the part in brackets ("Fagiolino
  /// (Tegolina / Cornetto)" → "Fagiolino"), because space is short here.
  /// Only in notifications: the app keeps the full name.
  String _name(FoodItem i) => i.name.of(language).replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();

  /// Persistent "shopping mode" notification for month [month] (0-11).
  ///
  /// No title (you already know the month): one line per season phase, with
  /// the label in bold.
  /// - [ShoppingNotifListMode.highlight]: a first "Shopping List:" line with
  ///   the products still to buy (in bold too, where Android shows it), then
  ///   every other in-season product, without repeating those of the list;
  /// - [ShoppingNotifListMode.onlyList]: a single "Shopping List:" line with
  ///   every product still to buy, in season or not, without season lines.
  /// - [ShoppingNotifListMode.onlySeason]: only the in-season products, as
  ///   if the list were empty.
  /// - [customItems]: free-text "Other Items" of the list still to buy. They
  ///   join the end of the "Shopping List" line.
  /// - [fullList]: every name written out, without the "+N" shortcut.
  NotificationContent shopping({
    required int month,
    required List<String> shoppingIds,
    required ShoppingNotifListMode listMode,
    bool fullList = false,
    Set<String> inCartIds = const {},
    List<String> customItems = const [],
  }) {
    final seasonOnly = listMode == ShoppingNotifListMode.onlySeason;
    final list = seasonOnly ? const <String>[] : shoppingIds.where(db.byId.containsKey).toList();
    final custom = seasonOnly ? const <String>[] : [for (final t in customItems) if (t.trim().isNotEmpty) t.trim()];
    final inList = list.toSet();
    final hasList = list.isNotEmpty || custom.isNotEmpty;
    final onlyList = hasList && listMode == ShoppingNotifListMode.onlyList;
    final entries = <FoodEntry>[
      for (final item in db.items)
        // With "list only", products already picked up leave the notification.
        if (!disliked.contains(item.id) &&
            (!onlyList || (inList.contains(item.id) && !inCartIds.contains(item.id))))
          FoodEntry(item, resolver.resolve(item)),
    ];
    HomeController.sortBySeason(entries, month, language);
    final payload = hasList ? NotificationPayload.openShopping : NotificationPayload.openSeason;

    // Order chosen by the owner: peak, in season, (early,) end of season.
    const groups = [SeasonState.peakSeason, SeasonState.inSeason, SeasonState.primizie, SeasonState.endOfSeason];
    final lines = <String>[];
    // Own line for the list, first: the bold alone was not visible on every
    // phone. Products already picked up are left out.
    final toBuy = [
      for (final e in entries)
        if (inList.contains(e.item.id) && !inCartIds.contains(e.item.id)) e.item,
    ];
    final listNames = [...toBuy.map(_name), ...custom];
    if (listNames.isNotEmpty) {
      // "List only": the whole notification is the list, so no bold names.
      final names = onlyList ? listNames : listNames.map((n) => '<b>$n</b>');
      lines.add('<b>${s.lineList}:</b> ${names.join(', ')}');
    }
    final peakNames = <String>[];
    final listAvailable = <FoodItem>[];
    var available = 0;
    for (final st in onlyList ? const <SeasonState>[] : groups) {
      final items = [
        for (final e in entries)
          if (e.calendar.at(month) == st) e.item,
      ];
      if (st.isAvailable) available += items.length;
      if (st == SeasonState.peakSeason) peakNames.addAll(items.map(_name));
      if (st.isAvailable) listAvailable.addAll(items.where((i) => inList.contains(i.id) && !inCartIds.contains(i.id)));
      // The list already has its own line: not repeated here.
      final ordered = [...items.where((i) => !inList.contains(i.id))];
      if (ordered.isEmpty) continue;
      final max = fullList ? ordered.length : _maxNamesPerLine;
      final shown = ordered.take(max).map(_name).join(', ');
      final more = ordered.length > max ? ' +${ordered.length - max}' : '';
      lines.add('<b>${s.state(st)}:</b> $shown$more');
    }
    // Collapsed line (what the lock screen shows first): the products of the
    // list that are in season come first and in bold, then the peak ones.
    final String body;
    final pending = [for (final id in list) if (!inCartIds.contains(id)) id];
    if (onlyList && pending.isEmpty) {
      body = '${custom.take(3).join(', ')}${custom.length > 3 ? '…' : ''}';
    } else if (onlyList) {
      body = s.notifListTitle(
        pending.where((id) => resolver.resolve(db.byId[id]!).at(month).isAvailable).length,
        pending.length,
      );
    } else {
      final lead = [
        ...listAvailable.map((i) => '<b>${_name(i)}</b>'),
        ...custom.map((t) => '<b>$t</b>'),
        ...peakNames.where((n) => !listAvailable.any((i) => _name(i) == n)),
      ];
      body = lead.isEmpty
          ? s.pulse(0, available)
          : '${lead.take(3).join(', ')}${lead.length > 3 ? '…' : ''} · ${s.pulse(peakNames.length, available)}';
    }
    return NotificationContent(title: null, body: body, lines: lines, payload: payload);
  }

  /// Products entering peak season in month [month]
  /// (peak in [month] but not in the previous month).
  List<FoodItem> enteringPeak(int month, {required PeakNotifMode mode, required Set<String> favorites}) {
    if (mode == PeakNotifMode.off) return const [];
    final out = <FoodItem>[];
    for (final item in db.items) {
      if (mode == PeakNotifMode.favorites && !favorites.contains(item.id)) continue;
      if (mode == PeakNotifMode.allExceptDisliked && disliked.contains(item.id)) continue;
      final cal = resolver.resolve(item);
      if (cal.at(month) == SeasonState.peakSeason && cal.at(month - 1) != SeasonState.peakSeason) {
        out.add(item);
      }
    }
    out.sort((a, b) => normalizeForSearch(_name(a)).compareTo(normalizeForSearch(_name(b))));
    return out;
  }

  NotificationContent peak(int month, List<FoodItem> items) {
    final names = items.map(_name).toList();
    return NotificationContent(
      title: s.notifPeakTitle(s.monthName(month)),
      body: names.join(', '),
      lines: [for (final n in names.take(7)) '★ $n', if (names.length > 7) '+${names.length - 7} ${s.lineMore}'],
      payload: NotificationPayload.peak(month),
    );
  }
}
