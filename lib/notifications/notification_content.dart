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
  NotificationContentBuilder({
    required this.db,
    required this.resolver,
    required this.language,
    required this.disliked,
  }) : s = S(language);

  final FoodDatabase db;
  final SeasonalityResolver resolver;
  final AppLanguage language;
  final Set<String> disliked;
  final S s;

  static const _maxNamesPerLine = 6;

  String _name(FoodItem i) => i.name.of(language);

  /// Persistent "shopping mode" notification for month [month] (0-11).
  ///
  /// No title (you already know the month) and no separate line for the list:
  /// one line per season phase, with the label in bold.
  /// - [ShoppingNotifListMode.highlight]: every in-season product, with
  ///   those on the list in bold and first;
  /// - [ShoppingNotifListMode.onlyList]: only the products on the list,
  ///   including the "out of season"/"no data" lines when needed.
  NotificationContent shopping({
    required int month,
    required List<String> shoppingIds,
    required ShoppingNotifListMode listMode,
  }) {
    final list = shoppingIds.where(db.byId.containsKey).toList();
    final inList = list.toSet();
    final onlyList = list.isNotEmpty && listMode == ShoppingNotifListMode.onlyList;
    final entries = <FoodEntry>[
      for (final item in db.items)
        if (!disliked.contains(item.id) && (!onlyList || inList.contains(item.id)))
          FoodEntry(item, resolver.resolve(item)),
    ];
    HomeController.sortBySeason(entries, month, language);
    final payload =
        list.isEmpty ? NotificationPayload.openSeason : NotificationPayload.openShopping;

    String fmt(FoodItem i) => !onlyList && inList.contains(i.id) ? '<b>${_name(i)}</b>' : _name(i);
    final groups = [
      SeasonState.peakSeason,
      SeasonState.primizie,
      SeasonState.inSeason,
      SeasonState.endOfSeason,
      if (onlyList) ...[SeasonState.outOfSeason, SeasonState.notApplicable, SeasonState.unknown],
    ];
    final lines = <String>[];
    final peakNames = <String>[];
    var available = 0;
    for (final st in groups) {
      final items = [
        for (final e in entries)
          if (e.calendar.at(month) == st) e.item,
      ];
      if (st.isAvailable) available += items.length;
      if (st == SeasonState.peakSeason) peakNames.addAll(items.map(_name));
      if (items.isEmpty) continue;
      // Products on the list go first, so they stay visible
      // (partition, not sort: List.sort is not stable).
      final ordered = [
        ...items.where((i) => inList.contains(i.id)),
        ...items.where((i) => !inList.contains(i.id)),
      ];
      final max = onlyList ? ordered.length : _maxNamesPerLine;
      final shown = ordered.take(max).map(fmt).join(', ');
      final more = ordered.length > max ? ' +${ordered.length - max}' : '';
      lines.add('<b>${s.state(st)}:</b> $shown$more');
    }
    final body = onlyList
        ? s.notifListTitle(list.where((id) => resolver.resolve(db.byId[id]!).at(month).isAvailable).length, list.length)
        : (peakNames.isEmpty
            ? s.pulse(0, available)
            : '${peakNames.take(3).join(', ')}${peakNames.length > 3 ? '…' : ''} · ${s.pulse(peakNames.length, available)}');
    return NotificationContent(
      title: null,
      body: body,
      lines: lines,
      payload: payload,
    );
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
      lines: [
        for (final n in names.take(7)) '★ $n',
        if (names.length > 7) '+${names.length - 7} ${s.lineMore}',
      ],
      payload: NotificationPayload.peak(month),
    );
  }
}
