import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tag personali dell'utente sugli alimenti: preferiti ❤️, "non lo mangio"
/// 🚫 e lista della spesa 📋. Salvati come liste di id.
class LibraryController extends ChangeNotifier {
  LibraryController(this._prefs)
      : _favorites = {...?_prefs.getStringList(_kFav)},
        _disliked = {...?_prefs.getStringList(_kDisliked)},
        _shopping = [...?_prefs.getStringList(_kShopping)],
        _inCart = {...?_prefs.getStringList(_kInCart)};

  static const _kFav = 'favoriteIds';
  static const _kDisliked = 'dislikedIds';
  static const _kShopping = 'shoppingListIds';
  static const _kInCart = 'inCartIds';

  final SharedPreferences _prefs;
  final Set<String> _favorites;
  final Set<String> _disliked;

  /// Lista ordinata per data di aggiunta (la più recente in fondo).
  final List<String> _shopping;

  /// Alimenti della lista già "presi / nel carrello".
  final Set<String> _inCart;

  Set<String> get inCartIds => Set.unmodifiable(_inCart);
  bool isInCart(String id) => _inCart.contains(id);

  void toggleInCart(String id) {
    if (!_shopping.contains(id)) return;
    if (!_inCart.remove(id)) _inCart.add(id);
    _save(_kInCart, _inCart);
    notifyListeners();
  }

  /// Toglie dalla lista gli alimenti già nel carrello.
  void clearCompleted() {
    _shopping.removeWhere(_inCart.contains);
    _inCart.clear();
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
      _disliked.remove(id); // un preferito non può essere "non mi piace"
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
    _save(_kInCart, _inCart);
    _save(_kShopping, _shopping);
    notifyListeners();
  }

  void _save(String key, Iterable<String> ids) =>
      _prefs.setStringList(key, ids.toList());
}
