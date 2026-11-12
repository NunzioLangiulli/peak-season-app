import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:peak_season/data/food_repository.dart';
import 'package:peak_season/data/seasonality_resolver.dart';
import 'package:peak_season/models/app_enums.dart';
import 'package:peak_season/models/food_item.dart';
import 'package:peak_season/models/season_state.dart';
import 'package:peak_season/providers/home_controller.dart';
import 'package:peak_season/providers/library_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FoodDatabase db;

  setUpAll(() {
    db = FoodRepository.parseDatabase(
      File('assets/data/database.json').readAsStringSync(),
    );
  });

  test('il database reale si carica con tutti i campi della Fase 2', () {
    expect(db.items.length, 153);
    final garlic = db.byId['aglio_garlic']!;
    expect(garlic.name.it, 'Aglio');
    expect(garlic.name.en, 'Garlic');
    expect(garlic.category, FoodCategory.verdura);
    expect(garlic.primaryImage, 'aglio_garlic_02.jpg');
    expect(garlic.gallery.first, 'aglio_garlic_02.jpg');
    expect(garlic.hasDopIgp, isTrue);
    expect(garlic.cardShortStorage.of(AppLanguage.en), isNotEmpty);
    expect(garlic.shoppingListPreview.of(AppLanguage.it), isNotEmpty);
    expect(garlic.seasonality.italyMacroAreas.keys, containsAll(['nord', 'centro', 'sud_isole']));
    expect(db.seasonLegend.length, 6);
    expect(db.zoneCountries[ClimaticZone.mediterranean], contains('Italy'));
    expect(db.sustainableDiet.text.it, isNotEmpty);
  });

  test('ogni immagine citata esiste negli asset WebP', () {
    for (final item in db.items) {
      if (item.primaryImage != null) {
        expect(File(AssetPaths.thumb(item.primaryImage!)).existsSync(), isTrue,
            reason: item.primaryImage);
      }
      for (final f in item.gallery) {
        expect(File(AssetPaths.full(f)).existsSync(), isTrue, reason: f);
      }
    }
  });

  test('ogni alimento ha i testi delle card in IT e EN', () {
    for (final item in db.items) {
      for (final lang in AppLanguage.values) {
        expect(item.name.of(lang), isNotEmpty, reason: item.id);
        expect(item.cardShortStorage.of(lang), isNotEmpty, reason: item.id);
      }
    }
  });

  group('SeasonalityResolver (stime dal database)', () {
    test('macro-area italiana esatta', () {
      const r = SeasonalityResolver(zone: ClimaticZone.mediterranean, area: ItalyMacroArea.nord);
      final cal = r.resolve(db.byId['aglio_garlic']!);
      expect(cal.isApproximate, isFalse);
      expect(cal.sourceKey, 'nord');
    });

    test('zona senza dato: stima del database marcata ≈, oppure niente se disattivata', () {
      final cece = db.byId['cece_chickpea']!; // nessuna zona EUFIC vera
      const approx = SeasonalityResolver(zone: ClimaticZone.pannonian, area: ItalyMacroArea.nord);
      final cal = approx.resolve(cece);
      expect(cal.isApproximate, isTrue);
      expect(cal.sourceKey, cece.seasonality.estimatedZones['pannonian']!.from);
      const strict = SeasonalityResolver(
        zone: ClimaticZone.pannonian,
        area: ItalyMacroArea.nord,
        allowApproximate: false,
      );
      expect(strict.resolve(cece).hasData, isFalse);
    });

    test('nessun dato e nessuna stima: stato unknown', () {
      final cece = db.byId['cece_chickpea']!; // atlantica: né dato né stima
      const r = SeasonalityResolver(zone: ClimaticZone.atlantic, area: ItalyMacroArea.nord);
      final cal = r.resolve(cece);
      expect(cal.hasData, isFalse);
      expect(cal.months.toSet(), {SeasonState.unknown});
    });

    test('zona con dato vero non è una stima', () {
      final parsnip = db.byId['pastinaca_parsnip']!;
      const r = SeasonalityResolver(zone: ClimaticZone.continental, area: ItalyMacroArea.nord);
      expect(r.resolve(parsnip).isApproximate, isFalse);
    });

    test('esotici: "non coltivato qui" dal database', () {
      final passion = db.byId['maracuja_passion_fruit']!;
      const r = SeasonalityResolver(zone: ClimaticZone.boreal, area: ItalyMacroArea.nord);
      expect(r.resolve(passion).months.toSet(), {SeasonState.notApplicable});
    });
  });

  test('ordinamento: peak → primizie → in season → fine → n.a. → fuori → ignoto, poi alfabetico', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final home = HomeController(prefs, now: DateTime(2026, 11, 6))..setIncludeNoData(true);
    final list = home.visibleEntries(
      db: db,
      library: LibraryController(prefs),
      resolver: const SeasonalityResolver(
        zone: ClimaticZone.mediterranean,
        area: ItalyMacroArea.nord,
      ),
      language: AppLanguage.it,
    );
    expect(list.length, 153);
    for (var i = 1; i < list.length; i++) {
      final a = list[i - 1], b = list[i];
      final ra = a.calendar.at(10).sortRank, rb = b.calendar.at(10).sortRank;
      expect(ra <= rb, isTrue);
      if (ra == rb) {
        expect(
          normalizeForSearch(a.item.name.it).compareTo(normalizeForSearch(b.item.name.it)) <= 0,
          isTrue,
        );
      }
    }
  });

  test('filtri: nascosti, preferiti, categorie, ricerca', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final lib = LibraryController(prefs)
      ..toggleDisliked('aglio_garlic')
      ..toggleFavorite('mela_apple');
    final home = HomeController(prefs, now: DateTime(2026, 11, 6));
    const r = SeasonalityResolver(zone: ClimaticZone.mediterranean, area: ItalyMacroArea.nord);
    List<String> ids() => home
        .visibleEntries(db: db, library: lib, resolver: r, language: AppLanguage.it)
        .map((e) => e.item.id)
        .toList();

    expect(ids(), isNot(contains('aglio_garlic')));
    home.setShowHidden(true);
    expect(ids(), contains('aglio_garlic'));
    home.setShowHidden(false);

    home.setQuickFilter(QuickFilter.favorites);
    expect(ids(), ['mela_apple']);
    home.setQuickFilter(QuickFilter.all);

    home.toggleQuickCategory(QuickCategory.fruit);
    expect(ids().every((id) => db.byId[id]!.category == FoodCategory.frutta), isTrue);
    expect(home.advancedFilterCount, 1);
    // Frutta + Altro = 4 filtri; Altro si accende, nessun tag (tutte e tre)
    home.toggleQuickCategory(QuickCategory.other);
    expect(home.advancedFilterCount, 4);
    expect(home.quickCategories, {QuickCategory.fruit, QuickCategory.other});
    expect(home.otherCategoryTags, isEmpty);
    expect(ids().any((id) => db.byId[id]!.category == FoodCategory.funghi), isTrue);
    // Togliendo i funghi dai filtri Altro resta acceso e compaiono i tag
    home.toggleCategory(FoodCategory.funghi);
    expect(home.quickCategories, contains(QuickCategory.other));
    expect(home.otherCategoryTags, {FoodCategory.erbeSpezie, FoodCategory.cereali});
    home.toggleQuickCategory(QuickCategory.all);
    expect(home.advancedFilterCount, 0);

    home.toggleRipening('climaterico');
    expect(ids().every((id) => db.byId[id]!.ripeningType == 'climaterico'), isTrue);
    home.toggleRipening('climaterico');
    home.toggleCarbon('low');
    home.toggleWater('high');
    expect(ids().every((id) => db.byId[id]!.carbonLevel == 'low' && db.byId[id]!.waterLevel == 'high'), isTrue);
    home.resetAdvanced();

    home.setQuery('Solanàcea'); // famiglia botanica, senza badare ad accenti/maiuscole
    expect(ids(), contains('pomodoro_tomato'));
    home.setQuery('tomato');
    expect(ids(), contains('pomodoro_tomato'));
    // singolare e plurale, in italiano e in inglese
    home.setQuery('pomodori');
    expect(ids(), contains('pomodoro_tomato'));
    home.setQuery('tomatoes');
    expect(ids(), contains('pomodoro_tomato'));
    home.setQuery('mele');
    expect(ids(), contains('mela_apple'));
    home.setQuery('apples');
    expect(ids(), contains('mela_apple'));
  });

  test('famiglia botanica: Solanaceae raggruppa pomodoro, melanzana, peperone', () {
    final ids = db.items.where((i) => i.family == 'Solanaceae').map((i) => i.id).toSet();
    expect(ids, containsAll(['pomodoro_tomato', 'melanzana_eggplant', 'peperone_bell_pepper']));
  });

  test('nomi delle famiglie e ordine di riferimento dal database', () {
    expect(db.familyName('Solanaceae').it, 'Solanacee');
    expect(db.referenceOrder.first, 'italy_national');
  });
}
