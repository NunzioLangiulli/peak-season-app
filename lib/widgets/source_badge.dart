import 'package:flutter/material.dart';

import '../data/source_logos.g.dart';
import '../theme/icon_service.dart';

/// Favicon del sito della fonte (`assets/sources/<chiave>.png`, PNG con sfondo
/// trasparente generati da scripts/fetch_source_favicons.py). Nel tema scuro i
/// loghi scuri hanno la luminosità invertita. Se manca il file, sigla su colore.
class SourceBadge extends StatelessWidget {
  const SourceBadge({super.key, required this.sourceKey, this.favicon, this.size = 40});

  final String? sourceKey;

  /// File del logo indicato dal database (`favicon`), se diverso da
  /// `<sourceKey>.png`.
  final String? favicon;
  final double size;

  static const _styles = <String, (String, Color, Color)>{
    'eufic_map': ('EUFIC', Color(0xFF0B6E4F), Colors.white),
    'crea': ('CREA', Color(0xFF00796B), Colors.white),
    'bda_ieo': ('IEO', Color(0xFF0D47A1), Colors.white),
    'usda_fdc': ('FDC', Color(0xFF1F3B73), Colors.white),
    'usda_hb66': ('HB66', Color(0xFF1F3B73), Colors.white),
    'uc_davis': ('UCD', Color(0xFF022851), Color(0xFFFFBF00)),
    'eppo': ('EPPO', Color(0xFF2B5797), Colors.white),
    'wfo': ('WFO', Color(0xFF2E7D32), Colors.white),
    'gbif': ('GBIF', Color(0xFF4E9F3D), Colors.white),
    'eambrosia': ('UE', Color(0xFF003399), Color(0xFFFFCC00)),
    'slow_food': ('SF', Color(0xFFB71C1C), Colors.white),
    'ortodacoltivare': ('ODC', Color(0xFF558B2F), Colors.white),
    'altroconsumo': ('AC', Color(0xFFC62828), Colors.white),
    'my_personaltrainer': ('MPT', Color(0xFFE65100), Colors.white),
  };

  /// "Inversione intelligente": inverte la luminosità mantenendo le tinte
  /// (inversione + rotazione di 180° della tinta), per i loghi scuri sul nero.
  static const _smartInvert = ColorFilter.matrix(<double>[
    0.574, -1.43, -0.144, 0, 255, //
    -0.426, -0.43, -0.144, 0, 255, //
    -0.426, -1.43, 0.856, 0, 255, //
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final fallback = _monogram(context);
    if (sourceKey == null && favicon == null) return fallback;
    // Leggi e regolamenti: icona generica al posto del logo.
    final k = sourceKey ?? '';
    if (favicon == null && (k.startsWith('reg_') || k.startsWith('legge_'))) {
      return SizedBox(
        width: size,
        height: size,
        child: SlotIcon('sources.law', size: size * 0.7, color: Theme.of(context).colorScheme.primary),
      );
    }
    final file = favicon ?? '$sourceKey.png';
    final dark = Theme.of(context).brightness == Brightness.dark;
    Widget logo = Image.asset(
      'assets/sources/$file',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => fallback,
    );
    if (dark && darkSourceLogos.contains(file.replaceAll('.png', ''))) {
      logo = ColorFiltered(colorFilter: _smartInvert, child: logo);
    }
    return SizedBox(width: size, height: size, child: logo);
  }

  Widget _monogram(BuildContext context) {
    // Fonte senza logo né sigla nota (es. link aggiunti dall'utente,
    // source_key "user"): icona generica di link.
    if (!_styles.containsKey(sourceKey)) {
      return SizedBox(
        width: size,
        height: size,
        child: SlotIcon('sources.generic', size: size * 0.6, color: Theme.of(context).colorScheme.primary),
      );
    }
    final style = _styles[sourceKey] ??
        ((sourceKey ?? '?').replaceAll('_', ' ').split(' ').map((w) => w.isEmpty ? '' : w[0]).join().toUpperCase(),
            Theme.of(context).colorScheme.secondary,
            Theme.of(context).colorScheme.onSecondary);
    final (label, bg, fg) = style;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(bg, Colors.white, 0.12)!, bg],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: FittedBox(
          child: Text(
            label,
            style: TextStyle(color: fg, fontWeight: FontWeight.w900, letterSpacing: 0.3, fontSize: size * 0.32),
          ),
        ),
      ),
    );
  }
}
