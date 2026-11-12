import '../models/app_enums.dart';
import '../models/food_item.dart';
import '../models/season_state.dart';

/// Sceglie la serie di 12 mesi da mostrare per la zona dell'utente.
///
/// Le stime NON sono calcolate dall'app: sono nel database
/// (`seasonality.estimates`, metodo in `metadata.seasonality_estimates_method`,
/// script `scripts/estimate_zone_gaps.py`). Ordine:
/// 1. dato vero della zona (o della macro-area italiana);
/// 2. stima del database, marcata ≈ (solo se `allowApproximate`);
/// 3. per gli esotici, "non coltivato qui" (`estimates.not_grown`);
/// 4. altrimenti stato [SeasonState.unknown].
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

    // Esotici: il database dichiara le zone in cui non sono coltivati.
    final zoneForNotGrown = zone.code;
    if (s.notGrownZones.contains(zoneForNotGrown)) {
      return SeasonCalendar(
        List.filled(12, SeasonState.notApplicable),
        sourceKey: 'not_grown',
      );
    }
    return SeasonCalendar.empty;
  }

  /// Ordine di default per il calendario di riferimento; il database lo
  /// riporta in `metadata.seasonality_reference_order` (ha la precedenza).
  static const defaultReferenceOrder = [
    'italy_national', 'mediterranean', 'continental', 'atlantic', 'mountain', 'pannonian', 'boreal',
  ];

  /// Calendario "di riferimento" da mostrare nella scheda quando per la zona
  /// scelta non c'è né un dato né una stima attiva. Solo dati veri (mai
  /// stime), nell'ordine [order]. `null` se la zona ha dati o se non esiste
  /// nessun riferimento. `sourceKey` = `italy_national` o il codice della zona.
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
