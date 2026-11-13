import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:peak_season/data/food_repository.dart';
import 'package:peak_season/data/seasonality_resolver.dart';
import 'package:peak_season/l10n/copy_service.dart';
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

  NotificationContentBuilder builder({Set<String> disliked = const {}}) => NotificationContentBuilder(
        db: db,
        resolver: resolver,
        language: AppLanguage.it,
        disliked: disliked,
      );

  test('modalità spesa senza lista: alimenti di stagione, apre la Home', () {
    final c = builder().shopping(month: 10, shoppingIds: const [], listMode: ShoppingNotifListMode.highlight);
    expect(c.title, isNull); // you already know the month
    expect(c.payload, NotificationPayload.openSeason);
    expect(c.lines.first, startsWith('<b>Picco di Stagione:</b>'));
  });

  test('lista evidenziata: niente riga separata, alimenti in lista in grassetto, apre la lista', () {
    final c = builder().shopping(
      month: 10,
      shoppingIds: const ['mela_apple', 'zucca_pumpkin'],
      listMode: ShoppingNotifListMode.highlight,
    );
    expect(c.payload, NotificationPayload.openShopping);
    expect(c.lines.any((l) => l.contains('Lista')), isFalse);
    expect(c.lines.join(), contains('<b>Mela</b>'));
  });

  test('solo lista: una riga per alimento con lo stato', () {
    final c = builder().shopping(
      month: 10,
      shoppingIds: const ['mela_apple', 'pomodoro_tomato'],
      listMode: ShoppingNotifListMode.onlyList,
    );
    final all = c.lines.join(' ');
    expect(all, contains('Mela'));
    expect(all, contains('Pomodoro')); // out of season too, on its own line
    expect(all, isNot(contains('Bietola'))); // no products outside the list
    expect(c.body, startsWith('La Tua Lista:'));
  });

  test('"non lo mangio" escluso dalla notifica', () {
    final b = builder(disliked: {'bietola_da_coste_swiss_chard'});
    final c = b.shopping(month: 10, shoppingIds: const [], listMode: ShoppingNotifListMode.highlight);
    expect(c.lines.join(), isNot(contains('Bietola')));
  });

  test('avvisi picco: solo chi entra nel picco quel mese, filtrati per modalità', () {
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
        b.enteringPeak(m, mode: PeakNotifMode.favorites, favorites: const {'mela_apple'})
            .every((i) => i.id == 'mela_apple'),
        isTrue,
      );
    }
  });
}
