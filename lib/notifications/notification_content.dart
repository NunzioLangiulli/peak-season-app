import '../data/food_repository.dart';
import '../data/seasonality_resolver.dart';
import '../l10n/strings.dart';
import '../models/app_enums.dart';
import '../models/food_item.dart';
import '../models/notification_prefs.dart';
import '../models/season_state.dart';
import '../providers/home_controller.dart';

/// Testo di una notifica, indipendente dal plugin (così è testabile e
/// riusabile per le anteprime).
class NotificationContent {
  const NotificationContent({
    required this.title,
    required this.body,
    required this.lines,
    required this.payload,
    this.summary,
  });

  /// Titolo (null = nessun titolo: Android mostra solo il nome dell'app).
  final String? title;

  /// Riga unica, mostrata a notifica chiusa.
  final String body;

  /// Righe della notifica espansa (InboxStyle), con `<b>` per evidenziare.
  final List<String> lines;
  final String payload;
  final String? summary;
}

/// Payload delle notifiche: dicono all'app cosa aprire quando le tocchi.
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

  /// Notifica fissa "modalità spesa" per il mese [month] (0-11).
  ///
  /// Niente titolo (il mese lo sai già) e niente riga separata per la lista:
  /// una riga per fase di stagione con l'etichetta in grassetto.
  /// - [ShoppingNotifListMode.highlight]: tutti gli alimenti di stagione, con
  ///   quelli in lista in grassetto e per primi;
  /// - [ShoppingNotifListMode.onlyList]: solo gli alimenti della lista,
  ///   comprese le righe "fuori stagione"/"senza dati" se servono.
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
      // Gli alimenti in lista vanno per primi, così restano visibili
      // (partizione e non sort: List.sort non è stabile).
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

  /// Alimenti che nel mese [month] entrano nel picco della stagione
  /// (picco in [month] ma non nel mese precedente).
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
