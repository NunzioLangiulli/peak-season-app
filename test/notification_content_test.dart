import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:peak_season/data/food_repository.dart';
import 'package:peak_season/data/seasonality_resolver.dart';
import 'package:peak_season/l10n/copy_service.dart';
import 'package:peak_season/l10n/strings.dart';
import 'package:peak_season/models/app_enums.dart';
import 'package:peak_season/models/notification_prefs.dart';
import 'package:peak_season/models/season_state.dart';
import 'package:peak_season/notifications/notification_content.dart';

void main() {
  late FoodDatabase db;
  const resolver = SeasonalityResolver(zone: ClimaticZone.mediterranean, area: ItalyMacroArea.nord);

  setUpAll(() {
    CopyService.loadFromString(File('assets/data/ui_copy.json').readAsStringSync());
    db = FoodRepository.parseDatabase(File('assets/data/database.json').readAsStringSync());
  });

  NotificationContentBuilder builder({Set<String> disliked = const {}}) =>
      NotificationContentBuilder(db: db, resolver: resolver, language: AppLanguage.it, disliked: disliked);

  test('shopping mode without a list: in-season products, opens Home', () {
    final c = builder().shopping(month: 10, shoppingIds: const [], listMode: ShoppingNotifListMode.highlight);
    expect(c.title, isNull); // you already know the month
    expect(c.payload, NotificationPayload.openSeason);
    expect(c.lines.first, startsWith('<b>Picco di Stagione:</b>'));
  });

  test('highlighted list: no separate line, list products in bold, opens the list', () {
    final c = builder().shopping(
      month: 10,
      shoppingIds: const ['mela_apple', 'zucca_pumpkin'],
      listMode: ShoppingNotifListMode.highlight,
    );
    expect(c.payload, NotificationPayload.openShopping);
    // own first line for the list, products not repeated below
    expect(c.lines.first, startsWith('<b>Lista della Spesa:</b> '));
    expect(c.lines.first, contains('<b>Mela</b>'));
    expect(c.lines.skip(1).join(), isNot(contains('Mela')));
  });

  test('order of the lines: peak, in season, end of season', () {
    final c = builder().shopping(month: 10, shoppingIds: const [], listMode: ShoppingNotifListMode.highlight);
    int at(String label) => c.lines.indexWhere((l) => l.startsWith('<b>$label:</b>'));
    final peak = at('Picco di Stagione'), inSeason = at('Di Stagione'), end = at('Fine Stagione');
    expect(peak, 0);
    if (inSeason >= 0) expect(inSeason, greaterThan(peak));
    if (end >= 0 && inSeason >= 0) expect(end, greaterThan(inSeason));
  });

  test('collapsed line: products of the list in season come first, in bold', () {
    final b = builder();
    final all = b.shopping(month: 10, shoppingIds: const [], listMode: ShoppingNotifListMode.highlight);
    // a product in season that is NOT at peak, so it would not be in the line without the list
    final notPeak = db.items.firstWhere((i) {
      final st = resolver.resolve(i).at(10);
      return st.isAvailable && st != SeasonState.peakSeason;
    });
    final c = b.shopping(month: 10, shoppingIds: [notPeak.id], listMode: ShoppingNotifListMode.highlight);
    expect(c.body, startsWith('<b>${notPeak.name.it}</b>'));
    expect(all.body, isNot(contains('<b>')));
  });

  test('names without brackets, products already picked up left out of the list line', () {
    final bracketed = db.items.firstWhere((i) => i.name.it.contains('('));
    final c = builder().shopping(
      month: 10,
      shoppingIds: [bracketed.id, 'mela_apple'],
      listMode: ShoppingNotifListMode.highlight,
      inCartIds: const {'mela_apple'},
      fullList: true,
    );
    final all = [c.body, ...c.lines].join(' ');
    expect(all, isNot(contains('(')));
    expect(c.lines.first, contains(bracketed.name.it.split(' (').first));
    expect(c.lines.first, isNot(contains('Mela')));
  });

  test('full list: no "+N" shortcut', () {
    final short = builder().shopping(month: 10, shoppingIds: const [], listMode: ShoppingNotifListMode.highlight);
    final full = builder().shopping(
      month: 10,
      shoppingIds: const [],
      listMode: ShoppingNotifListMode.highlight,
      fullList: true,
    );
    expect(short.lines.any((l) => RegExp(r' \+\d+$').hasMatch(l)), isTrue);
    expect(full.lines.any((l) => RegExp(r' \+\d+$').hasMatch(l)), isFalse);
  });

  test('list only: every product of the list, out of season too', () {
    final c = builder().shopping(
      month: 10,
      shoppingIds: const ['mela_apple', 'pomodoro_tomato'],
      listMode: ShoppingNotifListMode.onlyList,
    );
    final all = c.lines.join(' ');
    expect(all, contains('Mela'));
    expect(all, contains('Pomodoro')); // out of season too
    expect(all, isNot(contains('Bietola'))); // no products outside the list
    expect(c.body, startsWith('La Tua Lista:'));
  });

  test('"I don\'t eat it" excluded from the notification', () {
    final b = builder(disliked: {'bietola_da_coste_swiss_chard'});
    final c = b.shopping(month: 10, shoppingIds: const [], listMode: ShoppingNotifListMode.highlight);
    expect(c.lines.join(), isNot(contains('Bietola')));
  });

  test('peak alerts: only what enters peak that month, filtered by mode', () {
    final b = builder(disliked: {'pera_pear'});
    for (var m = 0; m < 12; m++) {
      for (final item in b.enteringPeak(m, mode: PeakNotifMode.allExceptDisliked, favorites: const {})) {
        final cal = resolver.resolve(item);
        expect(cal.at(m), SeasonState.peakSeason);
        expect(cal.at(m - 1), isNot(SeasonState.peakSeason));
        expect(item.id, isNot('pera_pear'));
      }
      expect(b.enteringPeak(m, mode: PeakNotifMode.off, favorites: const {}), isEmpty);
      expect(
        b
            .enteringPeak(m, mode: PeakNotifMode.favorites, favorites: const {'mela_apple'})
            .every((i) => i.id == 'mela_apple'),
        isTrue,
      );
    }
  });

  test('"Other Items" join the shopping list line, after the products', () {
    final c = builder().shopping(
      month: 10,
      shoppingIds: const ['mela_apple'],
      listMode: ShoppingNotifListMode.highlight,
      customItems: const ['Latte', 'Pane'],
    );
    expect(c.lines.first, startsWith('<b>Lista della Spesa:</b> <b>Mela</b>, <b>Latte</b>, <b>Pane</b>'));
    expect(c.payload, NotificationPayload.openShopping);
  });

  test('only "Other Items" on the list: they still get the list line and open the list', () {
    final c = builder().shopping(
      month: 10,
      shoppingIds: const [],
      listMode: ShoppingNotifListMode.highlight,
      customItems: const ['Latte'],
    );
    expect(c.lines.first, '<b>Lista della Spesa:</b> <b>Latte</b>');
    expect(c.payload, NotificationPayload.openShopping);
  });

  test('list only: one "Shopping List" line, no season lines, "Other Items" at the end', () {
    final c = builder().shopping(
      month: 10,
      shoppingIds: const ['mela_apple', 'zucca_pumpkin'],
      listMode: ShoppingNotifListMode.onlyList,
      customItems: const ['Latte'],
    );
    expect(c.lines, hasLength(1));
    expect(c.lines.single, startsWith('<b>Lista della Spesa:</b> '));
    expect(c.lines.single, contains('Mela'));
    expect(c.lines.single, contains('Zucca'));
    expect(c.lines.single, endsWith(', Latte'));
    final onlyCustom = builder().shopping(
      month: 10,
      shoppingIds: const [],
      listMode: ShoppingNotifListMode.onlyList,
      customItems: const ['Latte'],
    );
    expect(onlyCustom.lines, ['<b>Lista della Spesa:</b> Latte']);
    expect(onlyCustom.body, 'Latte');
  });

  test('seasonal products only: the shopping list is ignored', () {
    final c = builder().shopping(
      month: 10,
      shoppingIds: const ['mela_apple'],
      listMode: ShoppingNotifListMode.onlySeason,
      customItems: const ['Latte'],
    );
    final plain = builder().shopping(month: 10, shoppingIds: const [], listMode: ShoppingNotifListMode.highlight);
    expect(c.lines, plain.lines);
    expect(c.body, plain.body);
    expect(c.payload, NotificationPayload.openSeason);
  });

  test('products picked up leave the notification, in every list mode', () {
    for (final mode in [ShoppingNotifListMode.highlight, ShoppingNotifListMode.onlyList]) {
      final c = builder().shopping(
        month: 10,
        shoppingIds: const ['mela_apple', 'zucca_pumpkin'],
        listMode: mode,
        inCartIds: const {'mela_apple'},
      );
      expect(c.lines.join(), isNot(contains('Mela')), reason: mode.name);
      expect(c.lines.join(), contains('Zucca'), reason: mode.name);
    }
  });

  group('list only with nothing to show: a title and a text that say why, opens the list', () {
    void expectState(NotificationContent c, String title, String body) {
      expect(c.title, title);
      expect(c.body, body);
      expect(c.lines, [body]);
      expect(c.payload, NotificationPayload.openShopping);
    }

    test('empty list', () {
      final c = builder().shopping(month: 10, shoppingIds: const [], listMode: ShoppingNotifListMode.onlyList);
      expectState(c, 'La Tua Lista è Vuota', S(AppLanguage.it).notifEmptyListBody);
    });

    test('every product already picked up (also Other Items)', () {
      final c = builder().shopping(
        month: 10,
        shoppingIds: const ['mela_apple', 'zucca_pumpkin'],
        listMode: ShoppingNotifListMode.onlyList,
        inCartIds: const {'mela_apple', 'zucca_pumpkin'},
      );
      expectState(c, 'Hai Già Preso Tutto', S(AppLanguage.it).notifAllPickedBody);
      final onlyOther = builder().shopping(
        month: 10,
        shoppingIds: const [],
        listMode: ShoppingNotifListMode.onlyList,
        pickedOtherItems: 2,
      );
      expect(onlyOther.title, 'Hai Già Preso Tutto');
    });

    test('only Other Items, with their switch off', () {
      final c = builder().shopping(
        month: 10,
        shoppingIds: const ['mela_apple'],
        listMode: ShoppingNotifListMode.onlyList,
        inCartIds: const {'mela_apple'},
        hiddenOtherItems: 1,
      );
      expectState(c, 'La Tua Lista ha Solo Altri Articoli', S(AppLanguage.it).notifOnlyOtherItemsBody);
    });

    test('highlight mode keeps the season lines', () {
      final c = builder().shopping(month: 10, shoppingIds: const [], listMode: ShoppingNotifListMode.highlight);
      expect(c.title, isNull);
      expect(c.payload, NotificationPayload.openSeason);
    });
  });
}
