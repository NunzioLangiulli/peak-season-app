/// Stato stagionale di un alimento in un mese.
///
/// I primi sei valori corrispondono ai codici di `seasonality.*` nel database;
/// [unknown] è uno stato solo dell'app, usato quando per la zona scelta non
/// esistono dati (il database non li inventa, quindi l'app non li inventa).
enum SeasonState {
  peakSeason('peak_season', 0),
  primizie('primizie', 1),
  inSeason('in_season', 2),
  endOfSeason('end_of_season', 3),
  notApplicable('not_applicable', 4),
  outOfSeason('out_of_season', 5),
  unknown('unknown', 6);

  const SeasonState(this.code, this.sortRank);

  /// Codice usato nel database JSON.
  final String code;

  /// Ordine di rilevanza per l'ordinamento intelligente (0 = più rilevante).
  final int sortRank;

  static SeasonState fromCode(Object? code) {
    for (final s in values) {
      if (s.code == code) return s;
    }
    return SeasonState.unknown;
  }

  /// Stati che l'utente può scegliere nel filtro avanzato, nell'ordine
  /// mostrato: Picco, Di Stagione, Primizia, Fine, Fuori, Non Coltivato.
  static const filterable = [
    peakSeason,
    inSeason,
    primizie,
    endOfSeason,
    outOfSeason,
    notApplicable,
  ];

  bool get isAvailable =>
      this == peakSeason ||
      this == primizie ||
      this == inSeason ||
      this == endOfSeason;
}

/// Calendario di 12 mesi risolto per la zona scelta dall'utente.
class SeasonCalendar {
  const SeasonCalendar(this.months, {this.isApproximate = false, this.sourceKey});

  static final empty = SeasonCalendar(
    List.filled(12, SeasonState.unknown),
  );

  /// 12 stati, indice 0 = gennaio.
  final List<SeasonState> months;

  /// true se i dati vengono da una zona vicina (dato stimato, non esatto).
  final bool isApproximate;

  /// Chiave della serie usata (es. `nord`, `italy_national`, `continental`).
  final String? sourceKey;

  SeasonState at(int monthIndex) => months[(monthIndex % 12 + 12) % 12];

  bool get hasData => months.any((m) => m != SeasonState.unknown);
}
