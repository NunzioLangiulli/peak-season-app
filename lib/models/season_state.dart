/// Seasonal state of a product in a month.
///
/// The first six values match the `seasonality.*` codes in the database;
/// [unknown] is an app-only state, used when the chosen zone has no
/// data (the database does not invent data, so neither does the app).
enum SeasonState {
  peakSeason('peak_season', 0),
  primizie('primizie', 1),
  inSeason('in_season', 2),
  endOfSeason('end_of_season', 3),
  notApplicable('not_applicable', 4),
  outOfSeason('out_of_season', 5),
  unknown('unknown', 6);

  const SeasonState(this.code, this.sortRank);

  /// Code used in the JSON database.
  final String code;

  /// Relevance order for smart sorting (0 = most relevant).
  final int sortRank;

  static SeasonState fromCode(Object? code) {
    for (final s in values) {
      if (s.code == code) return s;
    }
    return SeasonState.unknown;
  }

  /// States the user can pick in the advanced filter, in the order
  /// shown: Peak, In Season, Early, End, Out, Not Grown.
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

/// 12-month calendar resolved for the user's chosen zone.
class SeasonCalendar {
  const SeasonCalendar(this.months, {this.isApproximate = false, this.sourceKey});

  static final empty = SeasonCalendar(
    List.filled(12, SeasonState.unknown),
  );

  /// 12 stati, indice 0 = gennaio.
  final List<SeasonState> months;

  /// true if the data come from a neighbouring zone (estimated, not exact).
  final bool isApproximate;

  /// Key of the series used (e.g. `nord`, `italy_national`, `continental`).
  final String? sourceKey;

  SeasonState at(int monthIndex) => months[(monthIndex % 12 + 12) % 12];

  bool get hasData => months.any((m) => m != SeasonState.unknown);
}
