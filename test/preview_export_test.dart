import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:peak_season/data/food_repository.dart';
import 'package:peak_season/data/seasonality_resolver.dart';
import 'package:peak_season/l10n/copy_service.dart';
import 'package:peak_season/l10n/strings.dart';
import 'package:peak_season/models/app_enums.dart';
import 'package:peak_season/models/notification_prefs.dart';
import 'package:peak_season/notifications/notification_content.dart';

/// Esporta i testi reali delle notifiche in build/notification_preview.json
/// per le anteprime (scripts/preview_screens.py). Si attiva solo con
/// PREVIEW_EXPORT=1, quindi non rallenta la suite normale.
void main() {
  test('esporta testi notifiche', () {
    CopyService.loadFromString(File('assets/data/ui_copy.json').readAsStringSync());
    final db = FoodRepository.parseDatabase(File('assets/data/database.json').readAsStringSync());
    final b = NotificationContentBuilder(
      db: db,
      resolver: const SeasonalityResolver(zone: ClimaticZone.mediterranean, area: ItalyMacroArea.nord),
      language: AppLanguage.it,
      disliked: const {},
    );
    const list = ['mela_apple', 'zucca_pumpkin', 'finocchio_fennel', 'porro_leek', 'pomodoro_tomato'];
    Map<String, Object?> j(NotificationContent c) =>
        {'title': c.title, 'body': c.body, 'lines': c.lines, 'payload': c.payload, 'summary': c.summary};
    const month = 10; // novembre
    final peakMonth = 11; // dicembre
    final peakItems = b.enteringPeak(peakMonth, mode: PeakNotifMode.allExceptDisliked, favorites: const {});
    const s = S(AppLanguage.it);
    final out = {
      'season': j(b.shopping(month: month, shoppingIds: const [], listMode: ShoppingNotifListMode.highlight)),
      'highlight': j(b.shopping(month: month, shoppingIds: list, listMode: ShoppingNotifListMode.highlight)),
      'onlyList': j(b.shopping(month: month, shoppingIds: list, listMode: ShoppingNotifListMode.onlyList)),
      'peak': j(b.peak(peakMonth, peakItems)),
      'storage': {'title': s.notifStorageTitle, 'body': s.notifStorageBody},
      'close': s.notifClose,
    };
    Directory('build').createSync(recursive: true);
    File('build/notification_preview.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(out));
  }, skip: Platform.environment['PREVIEW_EXPORT'] != '1');
}
