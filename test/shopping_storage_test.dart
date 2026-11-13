import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:peak_season/data/food_repository.dart';
import 'package:peak_season/providers/library_controller.dart';
import 'package:peak_season/screens/shopping_list_screen.dart';
import 'package:peak_season/screens/storage_tips_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FoodDatabase db;
  setUpAll(() {
    db = FoodRepository.parseDatabase(File('assets/data/database.json').readAsStringSync());
  });

  test('gross weight to buy: net / yield, rounded up to 10 g', () {
    expect(grossWeight(500, 100), 500);
    expect(grossWeight(500, 75), 670); // 666,7 → 670
    expect(grossWeight(0, 80), 0);
  });

  test('ethylene: apple (producer) and kiwi/lettuce (sensitive) conflict, garlic does not', () {
    final items = [for (final id in ['mela_apple', 'pomodoro_tomato', 'aglio_garlic']) db.byId[id]!];
    final c = ethyleneConflicts(items);
    final apple = c.firstWhere((x) => x.producer.id == 'mela_apple');
    expect(apple.sensitive.map((i) => i.id), contains('pomodoro_tomato'));
    expect(c.map((x) => x.producer.id), isNot(contains('aglio_garlic')));
    expect(ethyleneConflicts([db.byId['aglio_garlic']!]), isEmpty);
  });

  test('"in the cart": saved, removed with "Remove Those in the Cart"', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final lib = LibraryController(prefs)
      ..toggleShopping('mela_apple')
      ..toggleShopping('zucca_pumpkin')
      ..toggleInCart('mela_apple');
    expect(LibraryController(prefs).isInCart('mela_apple'), isTrue);
    lib.clearCompleted();
    expect(lib.shoppingListIds, ['zucca_pumpkin']);
    expect(lib.inCartIds, isEmpty);
  });
}
