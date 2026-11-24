import 'package:flutter_test/flutter_test.dart';
import 'package:peak_season/providers/library_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('free-text items: add, tick, remove, undo, saved and kept apart from products', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final lib = LibraryController(prefs, knownIds: {'mela_apple'})
      ..toggleShopping('mela_apple')
      ..addCustomItem('  Latte ')
      ..addCustomItem('latte') // already on the list: ignored
      ..addCustomItem('')
      ..addCustomItem('Pane');

    expect(lib.customItems.map((c) => c.text), ['Latte', 'Pane']);
    expect(lib.shoppingListIds, ['mela_apple']); // notifications see only products

    final latte = lib.customItems.first;
    lib.toggleCustomDone(latte.id);
    expect(lib.customItems.first.done, isTrue);

    // saved, and not dropped by the product-id migration at the next start
    final again = LibraryController(prefs, knownIds: {'mela_apple'});
    expect(again.customItems.map((c) => (c.text, c.done)), [('Latte', true), ('Pane', false)]);

    final pane = again.customItems.last;
    final index = again.removeCustomItem(pane.id);
    expect(again.customItems.length, 1);
    again.insertCustomItem(index, pane);
    expect(again.customItems.last.text, 'Pane');

    again.clearCompleted(); // removes the ticked ones
    expect(again.customItems.map((c) => c.text), ['Pane']);
    again.clearShopping();
    expect(again.customItems, isEmpty);
  });
}
