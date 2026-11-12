import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:peak_season/data/food_repository.dart';
import 'package:peak_season/data/seasonality_resolver.dart';
import 'package:peak_season/models/app_enums.dart';
import 'package:peak_season/models/season_state.dart';
import 'package:peak_season/providers/home_controller.dart';
import 'package:peak_season/providers/library_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Alimenti con "Dati Non Disponibili" per la zona scelta (regola approvata
/// dall'utente il 2026-11-06): mai mescolati agli alimenti di stagione.
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

  test('di default: sezione separata, nessun alimento senza dati nella lista principale', () async {
    final (home, lib) = await setup();
    final l = home.computeLists(db: db, library: lib, resolver: atlantic, language: AppLanguage.it);
    expect(l.main.every((e) => e.calendar.hasData), isTrue);
    expect(l.noData, isNotEmpty);
    expect(l.noData.every((e) => !e.calendar.hasData), isTrue);
    expect(l.noData.map((e) => e.item.id), contains('cece_chickpea'));
    expect(l.main.length + l.noData.length, db.items.length); // nessuno sparisce
  });

  test('"Includi Alimenti Senza Dati": tutti nella lista principale, sezione vuota, salvato', () async {
    final (home, lib) = await setup();
    home.setIncludeNoData(true);
    final l = home.computeLists(db: db, library: lib, resolver: atlantic, language: AppLanguage.it);
    expect(l.noData, isEmpty);
    expect(l.main.map((e) => e.item.id), contains('cece_chickpea'));
    // in fondo, dopo gli alimenti con dati
    expect(l.main.last.calendar.hasData, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('includeFoodsWithoutData'), isTrue);
    expect(HomeController(prefs).includeNoData, isTrue);
  });

  test('ricerca: l\'alimento senza dati resta trovabile (nella sezione)', () async {
    final (home, lib) = await setup();
    home.setQuery('cece');
    final l = home.computeLists(db: db, library: lib, resolver: atlantic, language: AppLanguage.it);
    expect(l.noData.map((e) => e.item.id), contains('cece_chickpea'));
  });

  test('con un filtro per stato la sezione non compare', () async {
    final (home, lib) = await setup();
    home.toggleState(SeasonState.peakSeason);
    final l = home.computeLists(db: db, library: lib, resolver: atlantic, language: AppLanguage.it);
    expect(l.noData, isEmpty);
  });

  group('calendario di riferimento', () {
    test('priorità 1: serie nazionale italiana', () {
      final ref = atlantic.reference(db.byId['cima_di_rapa_turnip_greens']!);
      expect(ref?.sourceKey, 'italy_national');
    });

    test('priorità 2: prima zona EUFIC con dato vero', () {
      final ref = atlantic.reference(db.byId['cardo_cardoon']!);
      expect(ref?.sourceKey, 'mediterranean');
      expect(ref?.isApproximate, isFalse);
    });

    test('nessun dato vero da nessuna parte: nessun riferimento (le stime non valgono)', () {
      expect(atlantic.reference(db.byId['cece_chickpea']!), isNull);
    });

    test('se la zona ha un dato o una stima attiva: nessun riferimento', () {
      const med = SeasonalityResolver(zone: ClimaticZone.mediterranean, area: ItalyMacroArea.nord);
      expect(med.reference(db.byId['aglio_garlic']!), isNull);
      const pan = SeasonalityResolver(zone: ClimaticZone.pannonian, area: ItalyMacroArea.nord);
      expect(pan.resolve(db.byId['cece_chickpea']!).isApproximate, isTrue);
      expect(pan.reference(db.byId['cece_chickpea']!), isNull);
    });
  });
}
