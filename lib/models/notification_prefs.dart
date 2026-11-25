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
  /// The shopping list first, on its own line, then the other in-season
  /// products. Stored name kept as "highlight" for saved settings.
  highlight,

  /// Only the products on the list, with their state.
  onlyList,

  /// Only the in-season products: the shopping list is ignored.
  onlySeason;

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
