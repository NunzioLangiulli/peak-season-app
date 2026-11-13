import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/season_state.dart';
import '../theme/season_palette.dart';

/// "o O o" indicator: previous month, selected month (larger, with
/// micro-icon) and next month.
class SeasonalityThreeDots extends StatelessWidget {
  const SeasonalityThreeDots({
    super.key,
    required this.calendar,
    required this.month,
    this.scale = 1.0,
  });

  final SeasonCalendar calendar;

  /// Mese selezionato, 0-11.
  final int month;

  /// 1.0 = card; about 1.3 for the product page.
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final prev = calendar.at(month - 1);
    final cur = calendar.at(month);
    final next = calendar.at(month + 1);
    final semantic = '${s.monthName(month - 1)}: ${s.state(prev)}. '
        '${s.monthName(month)}: ${s.state(cur)}. '
        '${s.monthName(month + 1)}: ${s.state(next)}.'
        '${calendar.isApproximate ? ' ${s.approxNote}' : ''}';

    return Tooltip(
      message: semantic,
      triggerMode: TooltipTriggerMode.longPress,
      child: Semantics(
        label: semantic,
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SeasonDot(state: prev, size: 10 * scale),
            SizedBox(width: 3 * scale),
            SeasonDot(state: cur, size: 22 * scale, showIcon: true),
            SizedBox(width: 3 * scale),
            SeasonDot(state: next, size: 10 * scale),
            if (calendar.isApproximate)
              Padding(
                padding: EdgeInsets.only(left: 2 * scale),
                child: Text(
                  '≈',
                  style: TextStyle(
                    fontSize: 11 * scale,
                    height: 1,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Coloured dot of a state, with optional micro-icon.
class SeasonDot extends StatelessWidget {
  const SeasonDot({
    super.key,
    required this.state,
    required this.size,
    this.showIcon = false,
    this.square = false,
  });

  final SeasonState state;
  final double size;
  final bool showIcon;

  /// Rounded square (calendar) instead of a circle.
  final bool square;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final border = SeasonPalette.accentBorder(state, b);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: SeasonPalette.color(state, b),
        shape: square ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: square ? BorderRadius.circular(size * 0.22) : null,
        border: border != null ? Border.all(color: border, width: 1.2) : null,
      ),
      child: showIcon
          ? Center(
              child: SeasonGlyph(
                state: state,
                size: size * 0.72,
                color: SeasonPalette.onColor(state, b),
              ),
            )
          : null,
    );
  }
}
