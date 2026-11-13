import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/food_repository.dart';
import '../l10n/strings.dart';
import '../models/app_enums.dart';
import '../models/season_state.dart';
import '../providers/home_controller.dart';
import '../providers/library_controller.dart';
import '../providers/settings_controller.dart';
import '../theme/icon_service.dart';
import 'seasonality_three_dots.dart';

/// BottomSheet of the advanced filters. Filters apply live; the
/// button at the bottom shows how many products will remain.
///
/// Each group is a grid of equal-width options (2 or 3 per
/// row), so the panel stays compact and symmetrical.
class AdvancedFiltersSheet extends StatelessWidget {
  const AdvancedFiltersSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => const AdvancedFiltersSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final home = context.watch<HomeController>();
    final lib = context.watch<LibraryController>();
    final settings = context.watch<SettingsController>();
    final db = context.read<FoodDatabase>();
    final lang = settings.language;
    final theme = Theme.of(context);
    final count = home
        .visibleEntries(
          db: db,
          library: lib,
          resolver: settings.resolver,
          language: settings.language,
        )
        .length;

    Widget section(String title, {String? trailing}) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Text(title, style: theme.textTheme.titleSmall),
        );

    Widget levelDot(String level) => Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: Color(db.footprintColor(level)), shape: BoxShape.circle),
        );

    const levels = ['low', 'medium', 'high'];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
            child: Row(
              children: [
                Expanded(child: Text(s.advancedFilters, style: theme.textTheme.titleLarge)),
                TextButton(onPressed: home.resetAdvanced, child: Text(s.reset)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scroll,
              children: [
                section(s.categoriesTitle),
                _OptionGrid(columns: 3, children: [
                  for (final c in FoodCategory.values)
                    _Option(
                      icon: SlotIcon('category.${c.code}', size: 16),
                      label: s.category(c),
                      selected: home.categories.contains(c),
                      onTap: () => home.toggleCategory(c),
                    ),
                ]),
                section(s.seasonStatesTitle(s.monthName(home.month))),
                _OptionGrid(columns: 2, children: [
                  for (final st in SeasonState.filterable)
                    _Option(
                      icon: SeasonDot(state: st, size: 18, showIcon: true),
                      label: s.state(st),
                      selected: home.states.contains(st),
                      onTap: () => home.toggleState(st),
                    ),
                ]),
                _CompactSwitch(
                  icon: const SeasonDot(state: SeasonState.unknown, size: 22, showIcon: true),
                  title: s.includeNoData,
                  subtitle: s.includeNoDataSub,
                  value: home.includeNoData,
                  onChanged: home.setIncludeNoData,
                ),
                section(s.ripening),
                _OptionGrid(columns: 2, children: [
                  for (final r in const ['climaterico', 'non_climaterico'])
                    _Option(
                      icon: const SlotIcon('storage.ripening_type', size: 16),
                      label: db.vocab('ripening_and_storage.ripening_type', r).of(lang),
                      selected: home.ripening.contains(r),
                      onTap: () => home.toggleRipening(r),
                    ),
                ]),
                section(s.storage),
                _OptionGrid(columns: 3, children: [
                  for (final l in const ['frigorifero', 'temperatura_ambiente', 'luogo_fresco_buio'])
                    _Option(
                      icon: SlotIcon(storageSlot(l), size: 16),
                      label: db.vocab('ripening_and_storage.primary_location', l).of(lang),
                      selected: home.storage.contains(l),
                      onTap: () => home.toggleStorage(l),
                    ),
                ]),
                section(s.carbonFootprint),
                _OptionGrid(columns: 3, children: [
                  for (final l in levels)
                    _Option(
                      icon: levelDot(l),
                      label: db.vocab('sustainability_level', l).of(lang),
                      selected: home.carbon.contains(l),
                      tint: Color(db.footprintColor(l)),
                      onTap: () => home.toggleCarbon(l),
                    ),
                ]),
                section(s.waterFootprint),
                _OptionGrid(columns: 3, children: [
                  for (final l in levels)
                    _Option(
                      icon: levelDot(l),
                      label: db.vocab('sustainability_level', l).of(lang),
                      selected: home.water.contains(l),
                      tint: Color(db.footprintColor(l)),
                      onTap: () => home.toggleWater(l),
                    ),
                ]),
                section(s.qualityTitle),
                _CompactSwitch(
                  icon: const SlotIcon('filters.dop_only', size: 26),
                  title: s.dopOnly,
                  subtitle: s.dopOnlySub,
                  value: home.dopOnly,
                  onChanged: home.setDopOnly,
                ),
                section(s.hiddenTitle),
                _CompactSwitch(
                  icon: const SlotIcon('filters.show_hidden'),
                  title: s.showHidden,
                  subtitle: s.showHiddenSub(lib.dislikedIds.length),
                  value: home.showHidden,
                  onChanged: home.setShowHidden,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(s.resultsCount(count)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid of equal-width options, [columns] per row.
class _OptionGrid extends StatelessWidget {
  const _OptionGrid({required this.columns, required this.children});
  final int columns;
  final List<Widget> children;

  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: LayoutBuilder(builder: (context, box) {
          final w = (box.maxWidth - _gap * (columns - 1)) / columns;
          return Wrap(
            spacing: _gap,
            runSpacing: _gap,
            children: [for (final c in children) SizedBox(width: w, child: c)],
          );
        }),
      );
}

/// Selectable option: icon + label, thin border; when selected it
/// takes the theme colour (or [tint], e.g. the footprint level colour).
class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.tint,
  });

  final Widget icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = tint ?? cs.primary;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? accent.withValues(alpha: 0.16) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: selected ? accent.withValues(alpha: 0.7) : cs.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IconTheme.merge(
                    data: IconThemeData(color: selected ? accent : cs.onSurfaceVariant),
                    child: icon,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact switch with icon, title and short explanation.
class _CompactSwitch extends StatelessWidget {
  const _CompactSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final Widget icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        secondary: SizedBox(width: 28, child: Center(child: icon)),
        title: Text(title, style: Theme.of(context).textTheme.bodyMedium),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      );
}
