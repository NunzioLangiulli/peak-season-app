import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_enums.dart';
import '../providers/settings_controller.dart';

/// Colori degli aloni dello sfondo per ogni scelta di Impostazioni → Aspetto.
class BackdropColors {
  const BackdropColors(this.first, this.second);
  final Color first;
  final Color second;

  static BackdropColors? of(BackdropPalette p, bool dark) => switch (p) {
        BackdropPalette.none => null,
        BackdropPalette.green => dark
            ? const BackdropColors(Color(0xFF0E2C14), Color(0xFF0A2412))
            : const BackdropColors(Color(0xFFD2EAC8), Color(0xFFE2F1D6)),
        BackdropPalette.greenTeal => dark
            ? const BackdropColors(Color(0xFF0E2C14), Color(0xFF06262A))
            : const BackdropColors(Color(0xFFD2EAC8), Color(0xFFCDEAE5)),
        BackdropPalette.greenAmber => dark
            ? const BackdropColors(Color(0xFF0E2C14), Color(0xFF1F1806))
            : const BackdropColors(Color(0xFFD2EAC8), Color(0xFFFCEBCB)),
      };
}

/// Sfondo di ogni pagina: tinta di base + due aloni morbidi (di default solo
/// verdi), così le superfici semitrasparenti sopra (card, barre, pannelli)
/// hanno l'effetto "vetro satinato". Nel tema scuro la base resta nera
/// (AMOLED) e gli aloni sono appena accennati.
class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = context.select<SettingsController, BackdropPalette>((s) => s.palette);
    final colors = BackdropColors.of(palette, dark);
    final base = dark ? Colors.black : const Color(0xFFF3F5EE);
    if (colors == null) return ColoredBox(color: base, child: child);
    return DecoratedBox(
      decoration: BoxDecoration(color: base),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.9, -1.0),
            radius: 1.25,
            colors: [colors.first.withValues(alpha: dark ? 0.75 : 1), colors.first.withValues(alpha: 0)],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(1.0, 0.85),
              radius: 1.1,
              colors: [colors.second.withValues(alpha: dark ? 0.6 : 1), colors.second.withValues(alpha: 0)],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Route delle pagine: ogni pagina porta il proprio sfondo opaco, così le
/// pagine trasparenti non si sovrappongono durante le transizioni.
class AppPageRoute<T> extends MaterialPageRoute<T> {
  AppPageRoute({required WidgetBuilder builder, super.settings})
      : super(builder: (context) => AppBackdrop(child: builder(context)));
}
