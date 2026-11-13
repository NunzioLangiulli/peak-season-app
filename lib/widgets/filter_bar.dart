import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/app_enums.dart';
import '../providers/home_controller.dart';
import '../screens/home_screen.dart' show ShoppingModeToggle;
import 'advanced_filters_sheet.dart';
import 'food_actions.dart';
import '../theme/icon_service.dart';

/// Command bar under the month slider.
/// Row 1: ❤️ favourites | filters · view · 🔍 (or the search field).
/// Row 2: All / Fruit / Vegetables / Other (they can be combined).
class FilterBar extends StatelessWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: home.searchOpen ? const _SearchField() : const _CommandRow(),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: const _CategoryToggle(),
          ),
        ],
      ),
    );
  }
}

class _CommandRow extends StatelessWidget {
  const _CommandRow();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final home = context.watch<HomeController>();
    final cs = Theme.of(context).colorScheme;
    final viewIcon = switch (home.viewMode) {
      HomeViewMode.grid => 'home.view.grid',
      HomeViewMode.list => 'home.view.list',
      HomeViewMode.calendar => 'home.view.calendar',
    };
    final advCount = home.advancedFilterCount;

    return Row(
      children: [
        _QuickChip(
          selected: home.quickFilter == QuickFilter.favorites,
          label: SlotIcon(
            home.quickFilter == QuickFilter.favorites
                ? FoodActionStyle.favoriteActiveIcon
                : FoodActionStyle.favoriteIcon,
            size: 20,
            color: home.quickFilter == QuickFilter.favorites
                ? FoodActionStyle.favoriteColor
                : null,
          ),
          tooltip: s.favoritesFilter,
          onTap: () => home.setQuickFilter(QuickFilter.favorites),
        ),
        const SizedBox(width: 6),
        const ShoppingModeToggle(),
        const Spacer(),
        IconButton(
          tooltip: s.advancedFilters,
          onPressed: () => AdvancedFiltersSheet.show(context),
          icon: Badge(
            isLabelVisible: advCount > 0,
            label: Text('$advCount'),
            child: const SlotIcon('home.advanced_filters'),
          ),
        ),
        IconButton(
          tooltip: '${s.changeView}: ${s.viewModeLabel(home.viewMode.next)}',
          onPressed: home.cycleViewMode,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (c, a) => RotationTransition(
              turns: Tween(begin: 0.75, end: 1.0).animate(a),
              child: FadeTransition(opacity: a, child: c),
            ),
            child: SlotIcon(viewIcon, key: ValueKey(home.viewMode)),
          ),
        ),
        IconButton(
          tooltip: s.search,
          onPressed: () => home.setSearchOpen(true),
          icon: SlotIcon('home.search', color: cs.onSurface),
        ),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.selected,
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  final bool selected;
  final Widget label;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: selected,
        label: tooltip,
        child: Material(
          color: selected ? cs.primaryContainer : Colors.transparent,
          shape: StadiumBorder(
            side: BorderSide(color: selected ? cs.primaryContainer : cs.outlineVariant),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Container(
              height: 36,
              constraints: const BoxConstraints(minWidth: 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              child: IconTheme.merge(
                data: IconThemeData(color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant),
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                    fontSize: 13,
                  ),
                  child: label,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField();

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _c =
      TextEditingController(text: context.read<HomeController>().query);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final home = context.read<HomeController>();
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: TextField(
        controller: _c,
        autofocus: true,
        textInputAction: TextInputAction.search,
        onChanged: home.setQuery,
        decoration: InputDecoration(
          hintText: s.searchHint,
          isDense: true,
          filled: true,
          prefixIcon: const SlotIcon('home.search'),
          suffixIcon: IconButton(
            tooltip: s.close,
            icon: const Icon(Icons.close_rounded),
            onPressed: () => home.setSearchOpen(false),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _CategoryToggle extends StatelessWidget {
  const _CategoryToggle();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final home = context.watch<HomeController>();
    final selected = home.quickCategories;
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<QuickCategory>(
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          // same size for all labels (4 segments on narrow screens)
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          iconSize: 14,
        ),
        showSelectedIcon: false,
        multiSelectionEnabled: true,
        emptySelectionAllowed: true,
        segments: [
          ButtonSegment(value: QuickCategory.all, label: _SegLabel(s.filterAll)),
          ButtonSegment(
            value: QuickCategory.fruit,
            label: _SegLabel(s.fruit),
            icon: const SlotIcon('category.frutta', size: 14),
          ),
          ButtonSegment(
            value: QuickCategory.vegetables,
            label: _SegLabel(s.vegetables),
            icon: const SlotIcon('category.verdura', size: 14),
          ),
          ButtonSegment(
            value: QuickCategory.other,
            label: _SegLabel(s.otherCategories),
            icon: const SlotIcon('home.category_other', size: 14),
          ),
        ],
        selected: selected,
        // A tap changes a single button: that one is applied.
        onSelectionChanged: (sel) {
          final changed = sel.difference(selected).union(selected.difference(sel));
          if (changed.isNotEmpty) home.toggleQuickCategory(changed.first);
        },
      ),
    );
  }
}

/// Label of a segment: on a single line, it shrinks if
/// there is not enough space (4 segments on narrow screens).
class _SegLabel extends StatelessWidget {
  const _SegLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(text, maxLines: 1, softWrap: false),
      );
}
