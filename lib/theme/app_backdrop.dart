import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_enums.dart';
import '../providers/settings_controller.dart';

/// Background glow colours for each choice in Settings → Appearance:
/// [first] glows from the top of the screen, [second] from the bottom.
class BackdropColors {
  const BackdropColors(this.first, this.second);
  final Color first;
  final Color second;

  /// Soft tint of a colour chosen by the user: pale in the light theme,
  /// very dark in the dark theme (AMOLED).
  static Color soften(Color c, bool dark) =>
      dark ? Color.lerp(c, Colors.black, 0.8)! : Color.lerp(c, Colors.white, 0.7)!;

  static BackdropColors? of(BackdropPalette p, bool dark, {int customTop = 0, int customBottom = 0}) => switch (p) {
    BackdropPalette.none => null,
    BackdropPalette.green =>
      dark
          ? const BackdropColors(Color(0xFF0E2C14), Color(0xFF0A2412))
          : const BackdropColors(Color(0xFFD2EAC8), Color(0xFFE2F1D6)),
    BackdropPalette.greenTeal =>
      dark
          ? const BackdropColors(Color(0xFF0E2C14), Color(0xFF06262A))
          : const BackdropColors(Color(0xFFD2EAC8), Color(0xFFCDEAE5)),
    BackdropPalette.custom => BackdropColors(soften(Color(customTop), dark), soften(Color(customBottom), dark)),
  };
}

/// Background of every page: base tint + two soft glows, one coming down
/// from the top edge and one rising from the bottom edge, so the
/// semi-transparent surfaces on top (cards, bars, panels) get the "frosted
/// glass" effect. In the dark theme the base stays black (AMOLED).
class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final st = context.watch<SettingsController>();
    final colors = BackdropColors.of(st.palette, dark, customTop: st.customTop, customBottom: st.customBottom);
    final base = dark ? Colors.black : const Color(0xFFF3F5EE);
    if (colors == null) return ColoredBox(color: base, child: child);
    final a1 = dark ? 0.85 : 1.0;
    final a2 = dark ? 0.7 : 1.0;
    // (a gradient replaces the colour of the same BoxDecoration: base underneath)
    return ColoredBox(
      color: base,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.first.withValues(alpha: a1),
              colors.first.withValues(alpha: 0),
              colors.second.withValues(alpha: 0),
              colors.second.withValues(alpha: a2),
            ],
            stops: const [0, 0.45, 0.55, 1],
          ),
        ),
        child: child,
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
