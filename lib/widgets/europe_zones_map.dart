import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../data/food_repository.dart';
import '../l10n/strings.dart';
import '../models/app_enums.dart';
import '../providers/settings_controller.dart';
import 'source_badge.dart';
import '../theme/icon_service.dart';

/// Mappa dell'Europa con i confini degli Stati, colorata per zona climatica
/// EUFIC (generata da scripts/build_europe_map.py con Natural Earth e i colori
/// del database). La zona scelta dall'utente è evidenziata nella legenda.
class EuropeZonesMap extends StatelessWidget {
  const EuropeZonesMap({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final db = context.read<FoodDatabase>();
    final current = context.select<SettingsController, ClimaticZone>((x) => x.zone);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SvgPicture.asset(
            dark ? 'assets/maps/europe_zones_dark.svg' : 'assets/maps/europe_zones_light.svg',
            fit: BoxFit.fitWidth,
            semanticsLabel: s.climateZone,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (final z in ClimaticZone.values)
              _ZoneChip(
                color: Color(db.zoneColors[z] ?? 0xFF9E9E9E),
                icon: IconService.ref('zone.${z.code}'),
                label: s.zone(z),
                selected: z == current,
              ),
            // Artica: presente sulla mappa EUFIC, non è una zona dell'app
            _ZoneChip(color: const Color(0xFF5B6670), icon: 'svg:zones/snowflake', label: s.zoneArctic, selected: false),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SourceBadge(sourceKey: 'eea_biogeo', size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                s.mapNote,
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Voce di legenda come sulla mappa EUFIC: riquadro del colore della zona con
/// il suo simbolo bianco e il nome.
class _ZoneChip extends StatelessWidget {
  const _ZoneChip({required this.color, required this.icon, required this.label, required this.selected});
  final Color color;
  final String? icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            RefIcon(icon!, size: 18, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: Colors.white, fontWeight: selected ? FontWeight.w900 : FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
