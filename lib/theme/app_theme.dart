import 'package:flutter/material.dart';

/// Tema Material 3 con seme verde naturale.
/// - Chiaro: superfici leggermente calde.
/// - Scuro "AMOLED": sfondo nero puro (pixel spenti sugli schermi OLED) e
///   superfici "satinate", cioè veli bianchi semitrasparenti con un bordo
///   sottile, invece di grigi pieni.
/// Font di sistema (Roboto su Android, San Francisco su iOS): zero download,
/// funziona offline e rispetta le impostazioni di accessibilità.
class AppTheme {
  const AppTheme._();

  static const seed = Color(0xFF2E7D32);
  static const radiusCard = 20.0;

  /// Velo satinato del tema scuro (bianco a bassa opacità sul nero).
  static Color satin(double opacity) => Colors.white.withValues(alpha: opacity);

  /// [frost]: intensità del vetro satinato (Impostazioni → Aspetto), 0-1.
  static ThemeData light({double frost = 0.6}) => _build(Brightness.light, frost);
  static ThemeData dark({double frost = 0.6}) => _build(Brightness.dark, frost);

  /// Opacità delle card: più "frost" = più trasparenza.
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
      // Le pagine sono trasparenti: lo sfondo lo dipinge AppBackdrop.
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        // vetro satinato: bianco semitrasparente sopra lo sfondo con aloni
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
        // Nel tema scuro i pannelli sono un vetro satinato sopra il nero.
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
