import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/food_repository.dart';
import '../l10n/strings.dart';
import '../models/glossary.dart';
import '../providers/settings_controller.dart';
import 'europe_zones_map.dart';
import 'season_legend_sheet.dart';
import 'source_link_tile.dart';

/// Small grey "?" button that opens the explanation of a term.
///
/// Pass the database field ([field], looked up in
/// `metadata.field_help`) or the glossary ids directly ([ids]).
/// If the database has no explanation for that field the button does not appear.
class HelpButton extends StatelessWidget {
  const HelpButton({
    super.key,
    this.field,
    this.ids = const [],
    this.extra,
    this.size = 18,
    this.showLegend = false,
  });

  final String? field;
  final List<String> ids;

  /// App text to show before the glossary entries (for concepts
  /// that exist only in the app, such as the "no data available" state).
  final HelpExtra? extra;
  final double size;

  /// Shows the seasonality colour legend at the top (the calendar
  /// has a single help button, not a separate one for the legend).
  final bool showLegend;

  @override
  Widget build(BuildContext context) {
    final db = context.read<FoodDatabase>();
    final entries = [
      if (field != null) ...db.helpFor(field!),
      ...db.entries(ids),
    ];
    if (entries.isEmpty && extra == null && !showLegend) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: context.s.learnMore,
      child: InkResponse(
        radius: size,
        onTap: () => HelpSheet.show(context, entries, extra: extra, showLegend: showLegend),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.onSurfaceVariant.withValues(alpha: 0.16),
            ),
            child: Text(
              '?',
              style: TextStyle(
                fontSize: size * 0.66,
                height: 1,
                fontWeight: FontWeight.w800,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HelpExtra {
  const HelpExtra({required this.title, required this.text, this.leading});
  final String title;
  final String text;
  final Widget? leading;
}

/// Sheet with one or more glossary entries; "See also" opens the linked entries.
class HelpSheet extends StatelessWidget {
  const HelpSheet({super.key, required this.entries, this.extra, this.showLegend = false});

  final List<GlossaryEntry> entries;
  final HelpExtra? extra;
  final bool showLegend;

  static Future<void> show(
    BuildContext context,
    List<GlossaryEntry> entries, {
    HelpExtra? extra,
    bool showLegend = false,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => HelpSheet(entries: entries, extra: extra, showLegend: showLegend),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = context.watch<SettingsController>().language;
    final db = context.read<FoodDatabase>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.3,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          if (showLegend) ...[
            const SeasonLegendContent(),
            if (entries.isNotEmpty || extra != null) const Divider(height: 32),
          ],
          if (extra != null) ...[
            Row(
              children: [
                if (extra!.leading != null) ...[extra!.leading!, const SizedBox(width: 12)],
                Expanded(child: Text(extra!.title, style: theme.textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: 8),
            Text(extra!.text, style: theme.textTheme.bodyMedium?.copyWith(height: 1.45)),
            if (entries.isNotEmpty) const Divider(height: 32),
          ],
          for (final (i, e) in entries.indexed) ...[
            if (i > 0) const Divider(height: 32),
            Text(e.term.of(lang), style: theme.textTheme.titleLarge),
            // for climate zones the subtitle is replaced by the map
            if (!e.short.isEmpty && e.id != 'eufic_zones') ...[
              const SizedBox(height: 4),
              Text(
                e.short.of(lang),
                style: theme.textTheme.titleSmall?.copyWith(color: cs.primary),
              ),
            ],
            const SizedBox(height: 8),
            // For climate zones: map of Europe with country borders
            if (e.id == 'eufic_zones') ...[
              const EuropeZonesMap(),
              const SizedBox(height: 12),
            ],
            Text(e.text.of(lang), style: theme.textTheme.bodyMedium?.copyWith(height: 1.45)),
            if (e.sources.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(s.sources, style: theme.textTheme.labelLarge),
              for (final src in e.sources)
                SourceLinkTile(
                  title: src.title.of(lang).isNotEmpty ? src.title.of(lang) : src.name,
                  subtitle: src.publisher.of(lang),
                  url: src.url,
                  sourceKey: src.key,
                  favicon: src.favicon,
                  badgeSize: 32,
                ),
            ],
            if (e.seeAlso.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(s.seeAlso, style: theme.textTheme.labelLarge),
                  for (final other in db.entries(e.seeAlso))
                    ActionChip(
                      visualDensity: VisualDensity.compact,
                      label: Text(other.term.of(lang)),
                      onPressed: () => HelpSheet.show(context, [other]),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
