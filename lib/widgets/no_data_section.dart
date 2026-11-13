import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/app_enums.dart';
import '../models/season_state.dart';
import '../providers/home_controller.dart';
import 'calendar_view.dart';
import 'food_cards.dart';
import 'seasonality_three_dots.dart';

/// Collapsed section at the bottom of the month list: "No Data for This Zone (n)".
/// Products without data must not be mixed with in-season ones; here
/// they remain reachable anyway. It does not appear if the list is empty.
class NoDataSection extends StatefulWidget {
  const NoDataSection({
    super.key,
    required this.entries,
    required this.viewMode,
    this.initiallyExpanded = false,
  });

  final List<FoodEntry> entries;
  final HomeViewMode viewMode;
  final bool initiallyExpanded;

  @override
  State<NoDataSection> createState() => _NoDataSectionState();
}

class _NoDataSectionState extends State<NoDataSection> {
  late bool _open = widget.initiallyExpanded;

  @override
  void didUpdateWidget(NoDataSection old) {
    super.didUpdateWidget(old);
    if (widget.initiallyExpanded && !old.initiallyExpanded) _open = true;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) return const SizedBox.shrink();
    final s = context.s;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final entries = widget.entries;

    final Widget content = switch (widget.viewMode) {
      HomeViewMode.grid => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: homeGridDelegate,
            itemCount: entries.length,
            itemBuilder: (_, i) => FoodGridCard(key: ValueKey('nd-${entries[i].item.id}'), entry: entries[i]),
          ),
        ),
      HomeViewMode.list => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (final e in entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FoodListCard(key: ValueKey('nd-${e.item.id}'), entry: e),
                ),
            ],
          ),
        ),
      HomeViewMode.calendar => Column(
          children: [
            for (final e in entries) SizedBox(height: 46, child: CalendarRow(entry: e)),
          ],
        ),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Material(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _open = !_open),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                  child: Row(
                    children: [
                      const SeasonDot(state: SeasonState.unknown, size: 22, showIcon: true),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(s.noDataSection(entries.length), style: theme.textTheme.titleSmall),
                      ),
                      AnimatedRotation(
                        turns: _open ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.expand_more_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !_open
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                        child: Text(
                          s.noDataSectionHint,
                          style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ),
                      content,
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
