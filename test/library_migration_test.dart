import 'package:flutter_test/flutter_test.dart';
import 'package:peak_season/providers/library_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('saved ids of removed products move to their replacement or are dropped', () async {
    SharedPreferences.setMockInitialValues({
      'favoriteIds': ['old_chicory', 'apple', 'gone'],
      'shoppingListIds': ['gone', 'old_chicory', 'chicory'],
      'inCartIds': ['old_chicory'],
      'dislikedIds': ['gone'],
    });
    final prefs = await SharedPreferences.getInstance();
    final lib = LibraryController(
      prefs,
      knownIds: {'apple', 'chicory'},
      redirects: {'old_chicory': 'chicory'},
    );
    expect(lib.favoriteIds, {'chicory', 'apple'});
    expect(lib.shoppingListIds, ['chicory']);
    expect(lib.inCartIds, {'chicory'});
    expect(lib.isDisliked('gone'), isFalse);
    expect(prefs.getStringList('shoppingListIds'), ['chicory']);
  });
}
