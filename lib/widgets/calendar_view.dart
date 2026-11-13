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

/// Width of the name column, shared by header and rows so that the 12
/// squares stay aligned with the month initials.
const double _nameColumnWidth = 118;
const EdgeInsets _rowPadding = EdgeInsets.symmetric(horizontal: 16);

/// MODE 3 — 12-month annual calendar.
class CalendarView extends StatelessWidget {
  const CalendarView({super.key, required this.entries, required this.bottomPadding, this.footer});

  final List<FoodEntry> entries;
  final double bottomPadding;

  /// Content at the bottom of the rows ("No Data for This Zone" section).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final month = context.select<HomeController, int>((h) => h.month);
    return LayoutBuilder(builder: (context, box) {
      // Months fixed from January to December; the pill moves to the month
      // chosen in the month slider at the top.
      final col = (box.maxWidth - _rowPadding.horizontal - _nameColumnWidth - 4) / 12;
      final left = _rowPadding.left + _nameColumnWidth + 2 + col * month;
      return Stack(
        children: [
          // A single vertical pill, from the initial in the header down to the
          // bottom of the rows, behind the dots.
          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
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

/// Position (0-11) of the selected month in the 12-month view: 5 months before on
/// the left, the selected month in 6th place, the next 6 on the right.
const int centeredMonthIndex = 5;

/// Order of the 12 months: January to December, or rotated so that
/// [selected] is at position [centeredMonthIndex].
List<int> monthOrder(int selected, {bool rotate = false}) => [
      for (var i = 0; i < 12; i++) rotate ? (selected - centeredMonthIndex + i + 12) % 12 : i,
    ];

/// Light green band, low opacity and with a slight glow, that
/// highlights the selected month's column (12-month view and product page).
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

/// Name without the part in brackets ("Caco (Kaki)" → "Caco"), for the view
/// compact 12-month view.
String compactName(String name) {
  final out = name.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
  return out.isEmpty ? name : out;
}

/// Fixed header: the 12 initials from January to December, above the
/// vertical pill.
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
                  for (var m = 0; m < 12; m++)
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
                child: MonthSquares(calendar: entry.calendar, selected: month),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 12 circles, one per month. The selected month (above the vertical
/// pill drawn by the row's container) is larger, at full
/// brightness and with the "Growth" micro-icon if it is a season
/// phase; the other months are smaller, slightly dimmed dots,
/// without icon. With [rotate] the selected month is in the middle.
class MonthSquares extends StatelessWidget {
  const MonthSquares({
    super.key,
    required this.calendar,
    required this.selected,
    this.height = 20,
    this.rotate = false,
    this.allIcons = false,
  });

  /// Every dot the same size with its micro-icon (product page calendar),
  /// instead of only the selected month.

  final SeasonCalendar calendar;
  final int selected;

  /// Maximum diameter of the selected month's circle (shrinks if the
  /// column is narrow).
  final double height;
  final bool rotate;
  final bool allIcons;

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
                  final size = isSel || allIcons ? d : d * 0.78;
                  final accent = SeasonPalette.accentBorder(st, b);
                  return Opacity(
                    opacity: isSel || allIcons ? 1 : 0.82,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: SeasonPalette.color(st, b),
                        shape: BoxShape.circle,
                        border: accent != null ? Border.all(color: accent, width: 1) : null,
                      ),
                      child: (isSel || allIcons) && st.isAvailable
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
