/// Which products trigger the "entering peak season" alert.
enum PeakNotifMode {
  /// Nessuna notifica.
  off,

  /// Favourite products ❤️ only.
  favorites,

  /// All except those marked "I Don't Eat It" 🚫.
  allExceptDisliked;

  static PeakNotifMode fromName(String? n) =>
      values.firstWhere((v) => v.name == n, orElse: () => PeakNotifMode.off);
}

/// How to show the shopping list in the persistent "shopping mode" notification.
enum ShoppingNotifListMode {
  /// All in-season products, with those on the list highlighted.
  highlight,

  /// Only the products on the list, with their state.
  onlyList;

  static ShoppingNotifListMode fromName(String? n) =>
      values.firstWhere((v) => v.name == n, orElse: () => ShoppingNotifListMode.highlight);
}

/// shared_preferences keys also read by the background isolate that
/// handles the notification's "Close" button.
class PrefKeys {
  static const language = 'language';
  static const shoppingModeActive = 'shoppingModeActive';
  static const storageTipsAfterShopping = 'storageTipsAfterShopping';

  /// Minutes to wait before the storage notification (0 = immediately).
  static const storageTipsDelayMinutes = 'storageTipsDelayMinutes';
}
