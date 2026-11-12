import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:peak_season/data/food_repository.dart';
import 'package:peak_season/l10n/copy_service.dart';
import 'package:peak_season/l10n/strings.dart';
import 'package:peak_season/models/app_enums.dart';
import 'package:peak_season/models/glossary.dart';

/// Testi dell'app (data/ui_copy.json) e corpus condiviso del database.
void main() {
  final copyRaw = File('assets/data/ui_copy.json').readAsStringSync();

  test('la copia in assets coincide con data/ui_copy.json', () {
    expect(copyRaw, File('../data/ui_copy.json').readAsStringSync());
  });

  test('ogni chiave usata in strings.dart esiste in IT e EN, chiavi uniche', () {
    CopyService.loadFromString(copyRaw);
    final entries = (jsonDecode(copyRaw)['strings'] as List).cast<Map>();
    final keys = entries.map((e) => e['key']).toList();
    expect(keys.toSet().length, keys.length);
    final src = File('lib/l10n/strings.dart').readAsStringSync();
    final used = RegExp(r"_c\('([\w.]+)'").allMatches(src).map((m) => m[1]!).toSet();
    // chiavi composte a runtime (mesi, paesi)
    for (var i = 1; i <= 12; i++) {
      used.addAll(['common.month.$i', 'common.month_short.$i', 'common.month_initial.$i']);
    }
    final missing = used.where((k) => !CopyService.has(k)).toList();
    expect(missing, isEmpty);
    for (final e in entries) {
      expect('${e['it']}'.isNotEmpty && '${e['en']}'.isNotEmpty, isTrue, reason: '${e['key']}');
    }
    const it = S(AppLanguage.it);
    const en = S(AppLanguage.en);
    expect(it.shoppingCounter(3, 1), '3 prodotti da comprare · 1 nel carrello');
    expect(en.monthName(10), 'November');
    expect(it.country('Czech Republic'), 'Repubblica Ceca');
    expect(it.country('Atlantis'), 'Atlantis');
  });

  test('corpus_ref risolti ovunque, con aggiunta specifica', () {
    final raw = File('assets/data/database.json').readAsStringSync();
    expect(raw.contains('"corpus_ref"'), isTrue);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    FoodRepository.resolveCorpusRefs(json);
    expect(jsonEncode(json['items']).contains('corpus_ref'), isFalse);
    final db = FoodRepository.parseDatabase(raw);
    final garlic = db.byId['aglio_garlic']!;
    expect(garlic.raw.text('seasonality.availability_note').of(AppLanguage.it), isNotEmpty);

    final mini = jsonDecode(jsonEncode(<String, dynamic>{
      'shared_descriptions_corpus': {
        'k': {'it': 'Base.', 'en': 'Base.'},
      },
      'items': [
        {
          'a': {'corpus_ref': 'k', 'specific_addition': {'it': 'Più.', 'en': 'More.'}},
          'b': [
            {'corpus_ref': 'k'},
          ],
          'c': {'corpus_ref': 'missing'},
        },
      ],
    })) as Map<String, dynamic>;
    FoodRepository.resolveCorpusRefs(mini);
    final item = (mini['items'] as List).first as Map;
    expect(item['a'], {'it': 'Base. Più.', 'en': 'Base. More.'});
    expect((item['b'] as List).first, {'it': 'Base.', 'en': 'Base.'});
    expect(item['c'], {'it': '', 'en': ''});
  });
}
