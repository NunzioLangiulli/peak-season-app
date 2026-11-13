import 'package:flutter/material.dart';

/// Material 3 theme with a natural green seed.
/// - Light: slightly warm surfaces.
/// - Dark "AMOLED": pure black background (pixels off on OLED screens) and
///   "frosted" surfaces, i.e. semi-transparent white veils with a thin
///   border, instead of solid greys.
/// System font (Roboto on Android, San Francisco on iOS): no download,
/// works offline and respects accessibility settings.
class AppTheme {
  const AppTheme._();

  static const seed = Color(0xFF2E7D32);
  static const radiusCard = 20.0;

  /// Frosted veil of the dark theme (low-opacity white on black).
  static Color satin(double opacity) => Colors.white.withValues(alpha: opacity);

  /// [frost]: frosted-glass intensity (Settings → Appearance), 0-1.
  static ThemeData light({double frost = 0.6}) => _build(Brightness.light, frost);
  static ThemeData dark({double frost = 0.6}) => _build(Brightness.dark, frost);

  /// Card opacity: more "frost" = more transparency.
  static double cardOpacity(bool dark, double frost) =>
      dark ? 0.11 - 0.07 * frost : 0.97 - 0.42 * frost;

  static ThemeData _build(Brightness b, double frost) {
    final dark = b == Brightness.dark;
    var scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: b,
      surface: dark ? Colors.black : const Color(0xFFF7F8F3),
    );
    if (dark) {
      scheme = scheme.copyWith(
        surfaceContainerLowest: const Color(0xFF000000),
        surfaceContainerLow: const Color(0xFF0B0D0B),
        surfaceContainer: const Color(0xFF121412),
        surfaceContainerHigh: const Color(0xFF181B18),
        surfaceContainerHighest: const Color(0xFF202420),
        outlineVariant: satin(0.12),
      );
    }
    final base = ThemeData(colorScheme: scheme, useMaterial3: true, brightness: b);
    return base.copyWith(
      // Pages are transparent: the background is painted by AppBackdrop.
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        // frosted glass: semi-transparent white over the background with glows
        color: dark ? satin(cardOpacity(true, frost)) : Colors.white.withValues(alpha: cardOpacity(false, frost)),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: BorderSide(color: dark ? satin(0.10) : Colors.white.withValues(alpha: 0.9)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const StadiumBorder(),
        side: BorderSide(color: dark ? satin(0.14) : scheme.outlineVariant),
        backgroundColor: dark ? satin(0.04) : null,
        showCheckmark: false,
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        titleSmall: base.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        // In the dark theme panels are frosted glass over black.
        backgroundColor: dark
            ? const Color(0xFF101310).withValues(alpha: 0.96)
            : const Color(0xFFF7F8F3).withValues(alpha: 0.975),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          side: BorderSide(color: dark ? satin(0.12) : Colors.white),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dark ? const Color(0xFF121512) : null,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(color: dark ? satin(0.10) : null),
      segmentedButtonTheme: dark
          ? SegmentedButtonThemeData(
              style: ButtonStyle(side: WidgetStatePropertyAll(BorderSide(color: satin(0.18)))),
            )
          : null,
    );
  }
}
