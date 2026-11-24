import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user's personal tags on products: favourites ❤️, "I don't eat it"
/// 🚫 and shopping list 📋. Saved as lists of ids.
class LibraryController extends ChangeNotifier {
  LibraryController(this._prefs, {Set<String>? knownIds, Map<String, String> redirects = const {}})
      : _favorites = {...?_prefs.getStringList(_kFav)},
        _disliked = {...?_prefs.getStringList(_kDisliked)},
        _shopping = [...?_prefs.getStringList(_kShopping)],
        _inCart = {...?_prefs.getStringList(_kInCart)},
        _custom = [
          for (final raw in _prefs.getStringList(_kCustom) ?? const <String>[]) ?CustomShoppingItem.tryDecode(raw),
        ] {
    if (knownIds != null) _migrate(knownIds, redirects);
  }

  /// Products removed or merged in a new database: saved ids are moved to
  /// the product that replaces them (`metadata.id_redirects`), unknown ones
  /// are dropped, so no screen meets an id the database no longer has.
  void _migrate(Set<String> known, Map<String, String> redirects) {
    String? fix(String id) {
      final to = known.contains(id) ? id : redirects[id];
      return to != null && known.contains(to) ? to : null;
    }

    List<String> clean(Iterable<String> ids) {
      final out = <String>[];
      for (final id in ids) {
        final f = fix(id);
        if (f != null && !out.contains(f)) out.add(f);
      }
      return out;
    }

    final fav = clean(_favorites), dis = clean(_disliked), shop = clean(_shopping), cart = clean(_inCart);
    if (fav.length != _favorites.length || !_favorites.containsAll(fav)) {
      _favorites..clear()..addAll(fav);
      _save(_kFav, _favorites);
    }
    if (dis.length != _disliked.length || !_disliked.containsAll(dis)) {
      _disliked..clear()..addAll(dis);
      _save(_kDisliked, _disliked);
    }
    if (!listEquals(shop, _shopping)) {
      _shopping..clear()..addAll(shop);
      _save(_kShopping, _shopping);
    }
    if (cart.length != _inCart.length || !_inCart.containsAll(cart)) {
      _inCart..clear()..addAll(cart);
      _save(_kInCart, _inCart);
    }
  }

  static const _kFav = 'favoriteIds';
  static const _kDisliked = 'dislikedIds';
  static const _kShopping = 'shoppingListIds';
  static const _kInCart = 'inCartIds';
  static const _kCustom = 'customShoppingItems';
  static const _kDoneCollapsed = 'shoppingDoneCollapsed';

  final SharedPreferences _prefs;
  final Set<String> _favorites;
  final Set<String> _disliked;

  /// List sorted by date added (most recent at the bottom).
  final List<String> _shopping;

  /// Products on the list already "picked / in the cart".
  final Set<String> _inCart;

  /// Free-text items (anything that is not one of the app's products), so
  /// the list is the only place the user needs for the whole shopping.
  /// Kept apart from the products: notifications and storage tips use only
  /// the products.
  final List<CustomShoppingItem> _custom;

  List<CustomShoppingItem> get customItems => List.unmodifiable(_custom);

  /// "Already got" section of the list folded (remembered between visits).
  bool get doneCollapsed => _prefs.getBool(_kDoneCollapsed) ?? false;

  void toggleDoneCollapsed() {
    _prefs.setBool(_kDoneCollapsed, !doneCollapsed);
    notifyListeners();
  }

  /// Adds a free-text item (ignored if empty or already on the list, to be bought).
  void addCustomItem(String text) {
    final t = text.trim();
    if (t.isEmpty || _custom.any((c) => !c.done && c.text.toLowerCase() == t.toLowerCase())) return;
    _custom.add(CustomShoppingItem(id: 'custom-${DateTime.now().microsecondsSinceEpoch}', text: t));
    _saveCustom();
    notifyListeners();
  }

  void toggleCustomDone(String id) {
    final i = _custom.indexWhere((c) => c.id == id);
    if (i < 0) return;
    _custom[i] = _custom[i].copyWith(done: !_custom[i].done);
    _saveCustom();
    notifyListeners();
  }

  /// Removes a free-text item; returns its position, for "Undo".
  int removeCustomItem(String id) {
    final i = _custom.indexWhere((c) => c.id == id);
    if (i < 0) return -1;
    _custom.removeAt(i);
    _saveCustom();
    notifyListeners();
    return i;
  }

  void insertCustomItem(int index, CustomShoppingItem item) {
    if (_custom.any((c) => c.id == item.id)) return;
    _custom.insert(index.clamp(0, _custom.length), item);
    _saveCustom();
    notifyListeners();
  }

  void _saveCustom() => _prefs.setStringList(_kCustom, [for (final c in _custom) c.encode()]);

  Set<String> get inCartIds => Set.unmodifiable(_inCart);
  bool isInCart(String id) => _inCart.contains(id);

  void toggleInCart(String id) {
    if (!_shopping.contains(id)) return;
    if (!_inCart.remove(id)) _inCart.add(id);
    _save(_kInCart, _inCart);
    notifyListeners();
  }

  /// Removes the products already in the cart from the list.
  void clearCompleted() {
    _shopping.removeWhere(_inCart.contains);
    _inCart.clear();
    _custom.removeWhere((c) => c.done);
    _saveCustom();
    _save(_kShopping, _shopping);
    _save(_kInCart, _inCart);
    notifyListeners();
  }

  Set<String> get favoriteIds => Set.unmodifiable(_favorites);
  Set<String> get dislikedIds => Set.unmodifiable(_disliked);
  List<String> get shoppingListIds => List.unmodifiable(_shopping);

  bool isFavorite(String id) => _favorites.contains(id);
  bool isDisliked(String id) => _disliked.contains(id);
  bool isInShoppingList(String id) => _shopping.contains(id);

  void toggleFavorite(String id) {
    if (!_favorites.remove(id)) {
      _favorites.add(id);
      _disliked.remove(id); // a favourite cannot be "I don't eat it"
      _save(_kDisliked, _disliked);
    }
    _save(_kFav, _favorites);
    notifyListeners();
  }

  void toggleDisliked(String id) {
    if (!_disliked.remove(id)) {
      _disliked.add(id);
      _favorites.remove(id);
      _save(_kFav, _favorites);
    }
    _save(_kDisliked, _disliked);
    notifyListeners();
  }

  void toggleShopping(String id) {
    if (!_shopping.remove(id)) {
      _shopping.add(id);
    } else if (_inCart.remove(id)) {
      _save(_kInCart, _inCart);
    }
    _save(_kShopping, _shopping);
    notifyListeners();
  }

  void removeFromShopping(String id) {
    if (_inCart.remove(id)) _save(_kInCart, _inCart);
    if (_shopping.remove(id)) {
      _save(_kShopping, _shopping);
      notifyListeners();
    }
  }

  void insertInShopping(int index, String id) {
    if (_shopping.contains(id)) return;
    _shopping.insert(index.clamp(0, _shopping.length), id);
    _save(_kShopping, _shopping);
    notifyListeners();
  }

  void clearShopping() {
    _shopping.clear();
    _inCart.clear();
    _custom.clear();
    _saveCustom();
    _save(_kInCart, _inCart);
    _save(_kShopping, _shopping);
    notifyListeners();
  }

  void _save(String key, Iterable<String> ids) =>
      _prefs.setStringList(key, ids.toList());
}

/// A free-text item of the shopping list ("Latte", "Pane"…), with its tick.
@immutable
class CustomShoppingItem {
  const CustomShoppingItem({required this.id, required this.text, this.done = false});

  final String id;
  final String text;
  final bool done;

  CustomShoppingItem copyWith({bool? done}) => CustomShoppingItem(id: id, text: text, done: done ?? this.done);

  String encode() => jsonEncode({'id': id, 'text': text, 'done': done});

  static CustomShoppingItem? tryDecode(String raw) {
    try {
      final m = jsonDecode(raw);
      if (m is! Map || m['id'] is! String || m['text'] is! String) return null;
      return CustomShoppingItem(id: m['id'] as String, text: m['text'] as String, done: m['done'] == true);
    } catch (_) {
      return null;
    }
  }
}
