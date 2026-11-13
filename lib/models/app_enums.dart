/// Supported languages: the whole app is either in Italian or in English.
enum AppLanguage {
  it,
  en;

  static AppLanguage fromCode(String? code) =>
      code == 'en' ? AppLanguage.en : AppLanguage.it;
}

/// Database categories (`category`).
enum FoodCategory {
  verdura('verdura'),
  frutta('frutta'),
  erbeSpezie('erbe_spezie'),
  funghi('funghi'),
  cereali('cereali');

  const FoodCategory(this.code);
  final String code;

  static FoodCategory fromCode(Object? code) => values.firstWhere(
        (c) => c.code == code,
        orElse: () => FoodCategory.verdura,
      );
}

/// The 6 EUFIC climate zones (`seasonality.eufic_climatic_zones`).
enum ClimaticZone {
  mediterranean('mediterranean'),
  continental('continental'),
  atlantic('atlantic'),
  boreal('boreal'),
  mountain('mountain'),
  pannonian('pannonian');

  const ClimaticZone(this.code);
  final String code;

  static ClimaticZone fromCode(String? code) => values.firstWhere(
        (z) => z.code == code,
        orElse: () => ClimaticZone.mediterranean,
      );
}

/// Sub-area for the Mediterranean zone: Italian macro-areas (local) or
/// the generic EUFIC Mediterranean series.
enum ItalyMacroArea {
  nord('italia_nord', 'nord'),
  centro('italia_centro', 'centro'),
  sudIsole('italia_sud_isole', 'sud_isole'),
  euficMediterranean('eufic_mediterranean', null);

  const ItalyMacroArea(this.code, this.dbKey);

  /// Valore salvato nelle preferenze.
  final String code;

  /// Chiave in `seasonality.italy_macro_areas` (null = EUFIC generica).
  final String? dbKey;

  static ItalyMacroArea fromCode(String? code) => values.firstWhere(
        (a) => a.code == code,
        orElse: () => ItalyMacroArea.nord,
      );
}

enum HomeViewMode {
  grid,
  list,
  calendar;

  HomeViewMode get next => values[(index + 1) % values.length];

  static HomeViewMode fromName(String? name) => values.firstWhere(
        (v) => v.name == name,
        orElse: () => HomeViewMode.grid,
      );
}

/// Mutually exclusive quick filters of the command bar.
enum QuickFilter { all, favorites }

/// Barra rapida Tutti / Frutta / Verdura / Altro (Altro = erbe e spezie,
/// funghi, cereali).
enum QuickCategory { all, fruit, vegetables, other }

/// Background tints (glows behind the frosted surfaces).
enum BackdropPalette {
  /// Greens only (default).
  green,

  /// Green and teal.
  greenTeal,

  /// Two colours chosen by the user (Settings → Background Tints).
  custom,

  /// No tint: plain background.
  none;

  /// Unknown or removed names (e.g. the old "greenAmber") fall back to green.
  static BackdropPalette fromName(String? n) =>
      values.firstWhere((v) => v.name == n, orElse: () => BackdropPalette.green);
}
