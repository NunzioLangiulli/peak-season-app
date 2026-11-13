import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:peak_season/data/food_repository.dart';
import 'package:peak_season/data/seasonality_resolver.dart';
import 'package:peak_season/models/app_enums.dart';
import 'package:peak_season/models/season_state.dart';
import 'package:peak_season/providers/home_controller.dart';
import 'package:peak_season/providers/library_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Products with "No Data Available" for the chosen zone (rule approved
/// by the project owner on 2026-11-06): never mixed with in-season products.
void main() {
  late FoodDatabase db;
  const atlantic = SeasonalityResolver(zone: ClimaticZone.atlantic, area: ItalyMacroArea.nord);

  setUpAll(() {
    db = FoodRepository.parseDatabase(File('assets/data/database.json').readAsStringSync());
  });

  Future<(HomeController, LibraryController)> setup() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return (HomeController(prefs, now: DateTime(2026, 11, 6)), LibraryController(prefs));
  }

  test('by default: separate section, no product without data in the main list', () async {
    final (home, lib) = await setup();
    final l = home.computeLists(db: db, library: lib, resolver: atlantic, language: AppLanguage.it);
    expect(l.main.every((e) => e.calendar.hasData), isTrue);
    expect(l.noData, isNotEmpty);
    expect(l.noData.every((e) => !e.calendar.hasData), isTrue);
    expect(l.noData.map((e) => e.item.id), contains('cece_chickpea'));
    expect(l.main.length + l.noData.length, db.items.length); // nessuno sparisce
  });

  test('"Include Products Without Data": all in the main list, empty section, saved', () async {
    final (home, lib) = await setup();
    home.setIncludeNoData(true);
    final l = home.computeLists(db: db, library: lib, resolver: atlantic, language: AppLanguage.it);
    expect(l.noData, isEmpty);
    expect(l.main.map((e) => e.item.id), contains('cece_chickpea'));
    // at the bottom, after the products with data
    expect(l.main.last.calendar.hasData, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('includeFoodsWithoutData'), isTrue);
    expect(HomeController(prefs).includeNoData, isTrue);
  });

  test('search: the product without data stays findable (in the section)', () async {
    final (home, lib) = await setup();
    home.setQuery('cece');
    final l = home.computeLists(db: db, library: lib, resolver: atlantic, language: AppLanguage.it);
    expect(l.noData.map((e) => e.item.id), contains('cece_chickpea'));
  });

  test('with a state filter the section does not appear', () async {
    final (home, lib) = await setup();
    home.toggleState(SeasonState.peakSeason);
    final l = home.computeLists(db: db, library: lib, resolver: atlantic, language: AppLanguage.it);
    expect(l.noData, isEmpty);
  });

  group('reference calendar', () {
    test('priority 1: Italian national series', () {
      final ref = atlantic.reference(db.byId['cima_di_rapa_turnip_greens']!);
      expect(ref?.sourceKey, 'italy_national');
    });

    test('priority 2: first EUFIC zone with real data', () {
      final ref = atlantic.reference(db.byId['cardo_cardoon']!);
      expect(ref?.sourceKey, 'mediterranean');
      expect(ref?.isApproximate, isFalse);
    });

    test('no real data anywhere: no reference (estimates do not count)', () {
      expect(atlantic.reference(db.byId['cece_chickpea']!), isNull);
    });

    test('if the zone has data or an active estimate: no reference', () {
      const med = SeasonalityResolver(zone: ClimaticZone.mediterranean, area: ItalyMacroArea.nord);
      expect(med.reference(db.byId['aglio_garlic']!), isNull);
      const pan = SeasonalityResolver(zone: ClimaticZone.pannonian, area: ItalyMacroArea.nord);
      expect(pan.resolve(db.byId['cece_chickpea']!).isApproximate, isTrue);
      expect(pan.reference(db.byId['cece_chickpea']!), isNull);
    });
  });
}
