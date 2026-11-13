import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/food_repository.dart';
import '../l10n/strings.dart';
import '../models/season_state.dart';
import '../providers/settings_controller.dart';
import 'help_button.dart';
import 'seasonality_three_dots.dart';

/// Legend of colours and micro-icons, with the database descriptions.
class SeasonLegendSheet extends StatelessWidget {
  const SeasonLegendSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const SeasonLegendSheet(),
  );

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.8,
    maxChildSize: 0.95,
    builder: (context, scroll) => ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: const [SeasonLegendContent()],
    ),
  );
}

/// Legend content, used by the sheet and inside the calendar's "?"
/// explanations.
class SeasonLegendContent extends StatelessWidget {
  const SeasonLegendContent({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = context.watch<SettingsController>().language;
    final db = context.read<FoodDatabase>();
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final estimate = db.glossary['seasonality_estimate'];

    Widget row(Widget leading, String title, String text, {Widget? help}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 28, child: Center(child: leading)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(title, style: theme.textTheme.titleSmall)),
                    ?help,
                  ],
                ),
                const SizedBox(height: 2),
                Text(text, style: theme.textTheme.bodySmall?.copyWith(color: muted, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(s.legend, style: theme.textTheme.titleLarge)),
            const HelpButton(ids: ['seasonality_states'], size: 22),
          ],
        ),
        const SizedBox(height: 8),
        for (final st in SeasonState.values)
          if (st == SeasonState.unknown)
            row(SeasonDot(state: st, size: 28, showIcon: true), s.unknownTitle, s.unknownDescription)
          else
            row(
              SeasonDot(state: st, size: 28, showIcon: true),
              s.state(st),
              db.seasonLegend[st]?.description.of(lang) ?? '',
            ),
        const Divider(height: 24),
        row(
          Text('≈', style: theme.textTheme.titleLarge?.copyWith(color: muted)),
          estimate?.term.of(lang) ?? s.approxNote,
          estimate?.short.of(lang) ?? '',
          help: const HelpButton(ids: ['seasonality_estimate']),
        ),
      ],
    );
  }
}
