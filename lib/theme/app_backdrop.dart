import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_enums.dart';
import '../providers/settings_controller.dart';

/// Background glow colours for each choice in Settings → Appearance.
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

/// Background of every page: base tint + two soft glows (green only by
/// default), so the semi-transparent surfaces on top (cards, bars, panels)
/// get the "frosted glass" effect. In the dark theme the base stays black
/// (AMOLED) and the glows are barely visible.
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

/// Page route: every page carries its own opaque background, so
/// transparent pages do not overlap during transitions.
class AppPageRoute<T> extends MaterialPageRoute<T> {
  AppPageRoute({required WidgetBuilder builder, super.settings})
      : super(builder: (context) => AppBackdrop(child: builder(context)));
}
