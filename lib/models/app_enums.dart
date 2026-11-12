/// Lingue supportate: tutta l'app è in italiano o tutta in inglese.
enum AppLanguage {
  it,
  en;

  static AppLanguage fromCode(String? code) =>
      code == 'en' ? AppLanguage.en : AppLanguage.it;
}

/// Categorie del database (`category`).
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

/// Le 6 zone climatiche EUFIC (`seasonality.eufic_climatic_zones`).
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

/// Sotto-area per la zona mediterranea: macro-aree italiane (Km 0) oppure
/// la serie EUFIC mediterranea generica.
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

/// Filtri rapidi esclusivi della barra comandi.
enum QuickFilter { all, favorites }

/// Barra rapida Tutti / Frutta / Verdura / Altro (Altro = erbe e spezie,
/// funghi, cereali).
enum QuickCategory { all, fruit, vegetables, other }

/// Sfumature dello sfondo (aloni dietro le superfici satinate).
enum BackdropPalette {
  /// Solo verdi (default).
  green,

  /// Verde e verde acqua.
  greenTeal,

  /// Verde e ambra.
  greenAmber,

  /// Nessuna sfumatura: tinta unita.
  none;

  static BackdropPalette fromName(String? n) =>
      values.firstWhere((v) => v.name == n, orElse: () => BackdropPalette.green);
}
