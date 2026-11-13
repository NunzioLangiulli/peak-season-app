import '../models/app_enums.dart';
import '../models/food_item.dart';
import '../models/season_state.dart';

/// Picks the 12-month series to show for the user's zone.
///
/// Estimates are NOT computed by the app: they are in the database
/// (`seasonality.estimates`, method in `metadata.seasonality_estimates_method`,
/// script `scripts/estimate_zone_gaps.py`). Order:
/// 1. real data for the zone (or the Italian macro-area);
/// 2. database estimate, marked ≈ (only if `allowApproximate`);
/// 3. for exotic produce, "not grown here" (`estimates.not_grown`);
/// 4. otherwise state [SeasonState.unknown].
class SeasonalityResolver {
  const SeasonalityResolver({
    required this.zone,
    required this.area,
    this.allowApproximate = true,
  });

  final ClimaticZone zone;
  final ItalyMacroArea area;
  final bool allowApproximate;

  SeasonCalendar resolve(FoodItem item) {
    final s = item.seasonality;
    final areaKey = zone == ClimaticZone.mediterranean ? area.dbKey : null;

    if (areaKey != null) {
      final real = s.italyMacroAreas[areaKey];
      if (real != null) return SeasonCalendar(real, sourceKey: areaKey);
      final est = s.estimatedAreas[areaKey];
      if (allowApproximate && est != null) {
        return SeasonCalendar(est.months, isApproximate: true, sourceKey: est.from);
      }
    } else {
      final real = s.euficZones[zone.code];
      if (real != null) return SeasonCalendar(real, sourceKey: zone.code);
      final est = s.estimatedZones[zone.code];
      if (allowApproximate && est != null) {
        return SeasonCalendar(est.months, isApproximate: true, sourceKey: est.from);
      }
    }

    // Exotic produce: the database declares the zones where it is not grown.
    final zoneForNotGrown = zone.code;
    if (s.notGrownZones.contains(zoneForNotGrown)) {
      return SeasonCalendar(
        List.filled(12, SeasonState.notApplicable),
        sourceKey: 'not_grown',
      );
    }
    return SeasonCalendar.empty;
  }

  /// Default order for the reference calendar; the database
  /// stores it in `metadata.seasonality_reference_order` (which takes precedence).
  static const defaultReferenceOrder = [
    'italy_national', 'mediterranean', 'continental', 'atlantic', 'mountain', 'pannonian', 'boreal',
  ];

  /// "Reference" calendar shown on the product page when the chosen zone
  /// has neither data nor an active estimate. Real data only (never
  /// estimates), in the order [order]. `null` if the zone has data or no
  /// reference exists. `sourceKey` = `italy_national` or the zone code.
  SeasonCalendar? reference(FoodItem item, {List<String>? order}) {
    if (resolve(item).hasData) return null;
    final s = item.seasonality;
    for (final key in (order == null || order.isEmpty) ? defaultReferenceOrder : order) {
      final months = key == 'italy_national' ? s.italyNational : s.euficZones[key];
      if (months != null) return SeasonCalendar(months, sourceKey: key);
    }
    return null;
  }
}
