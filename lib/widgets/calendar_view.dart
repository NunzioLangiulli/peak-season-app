import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/app_enums.dart';
import '../models/season_state.dart';
import '../providers/home_controller.dart';
import '../providers/settings_controller.dart';
import '../theme/season_palette.dart';
import 'food_actions.dart';
import 'food_image.dart';

/// Larghezza della colonna nome, condivisa da header e righe perché i 12
/// quadratini restino allineati alle iniziali dei mesi.
const double _nameColumnWidth = 118;
const EdgeInsets _rowPadding = EdgeInsets.symmetric(horizontal: 16);

/// MODALITÀ 3 — calendario annuale 12 mesi.
class CalendarView extends StatelessWidget {
  const CalendarView({super.key, required this.entries, required this.bottomPadding, this.footer});

  final List<FoodEntry> entries;
  final double bottomPadding;

  /// Contenuto in fondo alle righe (sezione "Senza Dati per Questa Zona").
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      // Colonna del mese selezionato: sempre al centro (i mesi ruotano).
      final col = (box.maxWidth - _rowPadding.horizontal - _nameColumnWidth - 4) / 12;
      final left = _rowPadding.left + _nameColumnWidth + 2 + col * centeredMonthIndex;
      return Stack(
        children: [
          // Un'unica pillola verticale, dall'iniziale nell'header fino in fondo
          // alle righe, dietro i pallini.
          Positioned(
            left: left + 1,
            width: col - 2,
            top: 4,
            bottom: 0,
            child: const MonthHighlightPill(),
          ),
          Column(
            children: [
              const CalendarMonthHeader(),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 4)),
                    SliverFixedExtentList.builder(
                      itemExtent: 46,
                      itemCount: entries.length,
                      itemBuilder: (context, i) => CalendarRow(entry: entries[i]),
                    ),
                    if (footer != null) SliverToBoxAdapter(child: footer),
                    SliverToBoxAdapter(child: SizedBox(height: bottomPadding)),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}

/// Posizione (0-11) del mese selezionato nella vista 12 mesi: 5 mesi prima a
/// sinistra, il mese selezionato al 6° posto, i 6 successivi a destra.
const int centeredMonthIndex = 5;

/// Ordine dei 12 mesi: da gennaio a dicembre, oppure ruotato in modo che
/// [selected] sia in posizione [centeredMonthIndex].
List<int> monthOrder(int selected, {bool rotate = false}) => [
      for (var i = 0; i < 12; i++) rotate ? (selected - centeredMonthIndex + i + 12) % 12 : i,
    ];

/// Fascia verde chiara, a bassa opacità e con un leggero alone, che
/// evidenzia la colonna del mese selezionato (vista 12 mesi e scheda).
class MonthHighlightPill extends StatelessWidget {
  const MonthHighlightPill({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: dark ? 0.12 : 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.primary.withValues(alpha: dark ? 0.22 : 0.18), width: 0.8),
          boxShadow: [
            BoxShadow(color: cs.primary.withValues(alpha: dark ? 0.16 : 0.10), blurRadius: 10, spreadRadius: 0.5),
          ],
        ),
      ),
    );
  }
}

/// Nome senza la parte tra parentesi ("Caco (Kaki)" → "Caco"), per la vista
/// compatta a 12 mesi.
String compactName(String name) {
  final out = name.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
  return out.isEmpty ? name : out;
}

/// Header fisso: le 12 iniziali, ruotate in modo che il mese selezionato
/// sia al centro, sopra la pillola verticale.
class CalendarMonthHeader extends StatelessWidget {
  const CalendarMonthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final home = context.watch<HomeController>();
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: _rowPadding.add(const EdgeInsets.only(top: 4, bottom: 4)),
      child: Row(
        children: [
          SizedBox(
            width: _nameColumnWidth,
            child: Text(
              s.monthName(home.month),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.primary),
            ),
          ),
          Expanded(
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.06)
                    : cs.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Row(
                children: [
                  for (final m in monthOrder(home.month, rotate: true))
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: m == home.month,
                        label: s.monthName(m),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            home.setMonth(m);
                          },
                          child: Center(
                            child: Text(
                              s.monthInitial(m),
                              style: TextStyle(
                                fontSize: m == home.month ? 12.5 : 11,
                                fontWeight: m == home.month || m == home.currentMonth
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: m == home.month ? cs.primary : cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CalendarRow extends StatelessWidget {
  const CalendarRow({super.key, required this.entry});
  final FoodEntry entry;

  @override
  Widget build(BuildContext context) {
    final lang = context.select<SettingsController, AppLanguage>((s) => s.language);
    final month = context.select<HomeController, int>((h) => h.month);
    final item = entry.item;
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => FoodNavigation.openDetail(context, item),
      onLongPress: () => FoodNavigation.showQuickActions(context, item),
      child: Padding(
        padding: _rowPadding,
        child: Row(
          children: [
            SizedBox(
              width: _nameColumnWidth,
              child: Row(
                children: [
                  ClipOval(
                    child: SizedBox(width: 28, height: 28, child: FoodImage(item: item)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      compactName(item.name.of(lang)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        height: 1.15,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (entry.calendar.isApproximate)
                    Text('≈', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: MonthSquares(calendar: entry.calendar, selected: month, rotate: true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 12 cerchietti, uno per mese. Il mese selezionato (sopra la pillola
/// verticale disegnata da chi contiene la riga) è più grande, a piena
/// luminosità e con la micro-icona del set "Crescita" se è una fase di
/// stagione; gli altri mesi sono pallini più piccoli e leggermente attenuati,
/// senza icona. Con [rotate] il mese selezionato sta al centro.
class MonthSquares extends StatelessWidget {
  const MonthSquares({
    super.key,
    required this.calendar,
    required this.selected,
    this.height = 20,
    this.rotate = false,
  });

  final SeasonCalendar calendar;
  final int selected;

  /// Diametro massimo del cerchietto del mese selezionato (si riduce se la
  /// colonna è stretta).
  final double height;
  final bool rotate;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return LayoutBuilder(builder: (context, c) {
      final col = c.maxWidth / 12;
      final d = (col - 3).clamp(8.0, height);
      return Row(
        children: [
          for (final m in monthOrder(selected, rotate: rotate))
            SizedBox(
              width: col,
              height: d + 6,
              child: Center(
                child: Builder(builder: (context) {
                  final st = calendar.at(m);
                  final isSel = m == selected;
                  final size = isSel ? d : d * 0.78;
                  final accent = SeasonPalette.accentBorder(st, b);
                  return Opacity(
                    opacity: isSel ? 1 : 0.82,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: SeasonPalette.color(st, b),
                        shape: BoxShape.circle,
                        border: accent != null ? Border.all(color: accent, width: 1) : null,
                      ),
                      child: isSel && st.isAvailable
                          ? Center(
                              child: SeasonGlyph(
                                state: st,
                                size: size * 0.74,
                                color: SeasonPalette.onColor(st, b),
                              ),
                            )
                          : null,
                    ),
                  );
                }),
              ),
            ),
        ],
      );
    });
  }
}
