/// Per quali alimenti ricevere l'avviso "entra nel picco della stagione".
enum PeakNotifMode {
  /// Nessuna notifica.
  off,

  /// Solo gli alimenti preferiti ❤️.
  favorites,

  /// Tutti tranne quelli segnati "Non lo mangio" 🚫.
  allExceptDisliked;

  static PeakNotifMode fromName(String? n) =>
      values.firstWhere((v) => v.name == n, orElse: () => PeakNotifMode.off);
}

/// Come mostrare la lista della spesa nella notifica fissa "modalità spesa".
enum ShoppingNotifListMode {
  /// Tutti gli alimenti di stagione, con quelli in lista evidenziati.
  highlight,

  /// Solo gli alimenti della lista, con il loro stato.
  onlyList;

  static ShoppingNotifListMode fromName(String? n) =>
      values.firstWhere((v) => v.name == n, orElse: () => ShoppingNotifListMode.highlight);
}

/// Chiavi di shared_preferences lette anche dall'isolate in background che
/// gestisce il pulsante "Chiudi" della notifica.
class PrefKeys {
  static const language = 'language';
  static const shoppingModeActive = 'shoppingModeActive';
  static const storageTipsAfterShopping = 'storageTipsAfterShopping';

  /// Minuti di attesa prima della notifica di conservazione (0 = subito).
  static const storageTipsDelayMinutes = 'storageTipsDelayMinutes';
}
