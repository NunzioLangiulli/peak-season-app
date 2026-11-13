import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:peak_season/theme/icon_service.dart';
import 'package:peak_season/theme/material_icon_names.dart';

/// Icon map (data/ui_config.json, Admin Studio → Icons tab).
void main() {
  final raw = File('assets/data/ui_config.json').readAsStringSync();

  test('la copia in assets coincide con data/ui_config.json', () {
    expect(raw, File('../data/ui_config.json').readAsStringSync());
  });

  test('slot del file = slot dell\'app, ogni icona esiste', () {
    IconService.loadFromString(raw);
    final slots = (jsonDecode(raw)['icon_slots'] as List).cast<Map>();
    final names = slots.map((e) => e['slot']).toList();
    expect(names.toSet().length, names.length, reason: 'slot duplicati');
    expect(names.toSet(), IconService.defaults.keys.toSet());
    for (final e in slots) {
      // The Admin Studio is in English: group and description also need an EN version
      for (final f in const ['group', 'group_en', 'description', 'description_en']) {
        expect('${e[f] ?? ''}'.isNotEmpty, isTrue, reason: '${e['slot']}: missing $f');
      }
      final ref = '${e['icon']}';
      if (ref.startsWith('material:')) {
        expect(materialIconNames.containsKey(ref.substring(9)), isTrue, reason: '${e['slot']}: $ref');
      } else {
        expect(ref.startsWith('svg:'), isTrue, reason: '${e['slot']}: $ref');
        expect(File('assets/icons/${ref.substring(4)}.svg').existsSync(), isTrue, reason: '${e['slot']}: $ref');
      }
    }
  });

  test('ogni slot scritto nel codice è tra quelli definiti', () {
    final used = <String>{};
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.endsWith('icon_service.dart')) continue;
      final src = f.readAsStringSync();
      used.addAll(RegExp(r"SlotIcon\(\s*'([\w.]+)'").allMatches(src).map((m) => m[1]!));
      // slots passed as strings (actions, navigation bar, views, sections)
      used.addAll(RegExp(r"'((?:action|nav|home\.view|detail\.section)\.[\w.]+)'").allMatches(src).map((m) => m[1]!));
    }
    expect(used.difference(IconService.defaults.keys.toSet()), isEmpty);
    expect(used.length, greaterThan(40));
  });
}
