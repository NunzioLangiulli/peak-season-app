import 'package:flutter/material.dart';

import '../models/season_state.dart';
import 'icon_service.dart';

/// Colori e micro-icone degli stati stagionali, con varianti per tema chiaro
/// e scuro. Il colore del simbolo (bianco o quasi nero) è scelto in base alla
/// luminanza dello sfondo per avere sempre contrasto sufficiente.
class SeasonPalette {
  const SeasonPalette._();

  static Color color(SeasonState s, Brightness b) {
    final dark = b == Brightness.dark;
    return switch (s) {
      SeasonState.primizie => dark ? const Color(0xFFAED581) : const Color(0xFF8BC34A),
      SeasonState.inSeason => dark ? const Color(0xFF66BB6A) : const Color(0xFF4CAF50),
      SeasonState.peakSeason => dark ? const Color(0xFF2E7D32) : const Color(0xFF1B5E20),
      SeasonState.endOfSeason => dark ? const Color(0xFFFFCA28) : const Color(0xFFFFB300),
      SeasonState.outOfSeason => dark ? const Color(0xFFEF6F6C) : const Color(0xFFE05A55),
      SeasonState.notApplicable => dark ? const Color(0xFF42A5F5) : const Color(0xFF1E88E5),
      SeasonState.unknown => dark ? const Color(0xFF4A4F4A) : const Color(0xFFD5D8D2),
    };
  }

  /// Bordo luminoso del Peak in tema scuro, perché il verde scuro su sfondo
  /// scuro altrimenti si perde.
  static Color? accentBorder(SeasonState s, Brightness b) {
    if (s == SeasonState.peakSeason && b == Brightness.dark) {
      return const Color(0xFFA5D6A7);
    }
    return null;
  }

  static Color onColor(SeasonState s, Brightness b) {
    final bg = color(s, b);
    return bg.computeLuminance() > 0.45 ? const Color(0xFF1B1F1B) : Colors.white;
  }

  /// Slot di IconService dell'icona di uno stato (set A "Crescita" per le
  /// fasi di stagione, scelto dall'utente il 2026-11-06).
  static String iconSlot(SeasonState s) => s == SeasonState.unknown
      ? 'seasonality.estimates.unknown'
      : 'seasonality.state.${s.code}';
}

/// Micro-icona di uno stato (slot `seasonality.state.*` di ui_config.json),
/// già colorata.
class SeasonGlyph extends StatelessWidget {
  const SeasonGlyph({super.key, required this.state, required this.size, required this.color});

  final SeasonState state;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      SlotIcon(SeasonPalette.iconSlot(state), size: size, color: color);
}
