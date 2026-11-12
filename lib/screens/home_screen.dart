import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/food_repository.dart';
import '../l10n/strings.dart';
import '../models/app_enums.dart';
import '../models/season_state.dart';
import '../providers/home_controller.dart';
import '../providers/library_controller.dart';
import '../providers/notification_controller.dart';
import '../providers/settings_controller.dart';
import '../widgets/calendar_view.dart';
import '../widgets/filter_bar.dart';
import '../widgets/food_cards.dart';
import '../widgets/month_selector.dart';
import '../widgets/no_data_section.dart';
import '../widgets/pill_nav_bar.dart';
import '../widgets/season_legend_sheet.dart';
import '../theme/icon_service.dart';

/// TAB 1 — "Peak Season".
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.read<FoodDatabase>();
    final home = context.watch<HomeController>();
    final lib = context.watch<LibraryController>();
    final settings = context.watch<SettingsController>();
    final lists = home.computeLists(
      db: db,
      library: lib,
      resolver: settings.resolver,
      language: settings.language,
    );
    final entries = lists.main;
    final bottom = PillNavBar.overlap(context);
    // Con una ricerca attiva la sezione "Senza Dati" si apre da sola, così
    // l'alimento cercato si vede sempre.
    final noData = NoDataSection(
      key: ValueKey('nodata-${home.viewMode.name}'),
      entries: lists.noData,
      viewMode: home.viewMode,
      initiallyExpanded: home.query.isNotEmpty || entries.isEmpty,
    );

    final Widget body;
    if (entries.isEmpty && lists.noData.isEmpty) {
      body = _EmptyState(bottomPadding: bottom);
    } else {
      body = switch (home.viewMode) {
        HomeViewMode.grid => CustomScrollView(
            key: const PageStorageKey('grid'),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                sliver: SliverGrid.builder(
                  gridDelegate: homeGridDelegate,
                  itemCount: entries.length,
                  itemBuilder: (_, i) => FoodGridCard(key: ValueKey(entries[i].item.id), entry: entries[i]),
                ),
              ),
              SliverToBoxAdapter(child: noData),
              SliverToBoxAdapter(child: SizedBox(height: bottom)),
            ],
          ),
        HomeViewMode.list => CustomScrollView(
            key: const PageStorageKey('list'),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                sliver: SliverList.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => FoodListCard(key: ValueKey(entries[i].item.id), entry: entries[i]),
                ),
              ),
              SliverToBoxAdapter(child: noData),
              SliverToBoxAdapter(child: SizedBox(height: bottom)),
            ],
          ),
        HomeViewMode.calendar => CalendarView(entries: entries, bottomPadding: bottom, footer: noData),
      };
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _Header(),
            const MonthSelector(),
            _SeasonPulse(entries: entries, month: home.month),
            const FilterBar(),
            const _ActiveFilterChips(),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(key: ValueKey(home.viewMode), child: body),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final home = context.read<HomeController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 12, 8),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              // Toccare il titolo riporta al mese corrente.
              onTap: () => home.setMonth(home.currentMonth),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.appTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Interruttore "Sono a fare la spesa": carrello con campanella + switch.
/// Acceso = notifica fissa con i prodotti di stagione. Sta accanto al cuore
/// nella Home e in alto nella Lista della Spesa.
class ShoppingModeToggle extends StatelessWidget {
  const ShoppingModeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final notif = context.watch<NotificationController>();
    final active = notif.shoppingActive;
    final cs = Theme.of(context).colorScheme;

    Future<void> toggle(bool on) async {
      final messenger = ScaffoldMessenger.of(context);
      final ok = await notif.setShoppingMode(on);
      final msg = !ok
          ? s.notifPermissionDenied
          : (!notif.isSupported ? s.notifUnsupported : (on ? s.shoppingModeActivated : null));
      if (msg != null) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(msg)));
      }
    }

    return Tooltip(
      message: active ? s.shoppingModeOn : s.shoppingModeOff,
      child: Semantics(
        toggled: active,
        label: s.shoppingModeOff,
        child: Material(
          color: active ? cs.primaryContainer : Colors.transparent,
          shape: StadiumBorder(side: BorderSide(color: active ? cs.primaryContainer : cs.outlineVariant)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => toggle(!active),
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 2),
              child: SizedBox(
                height: 36,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SlotIcon(
                      'home.shopping_mode',
                      size: 22,
                      color: active ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                    ),
                    Transform.scale(
                      scale: 0.72,
                      child: Switch(
                        value: active,
                        onChanged: toggle,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "12 al picco della stagione · 40 di stagione" — riassunto del mese (il
/// mese è già nello slider), apre la legenda.
class _SeasonPulse extends StatelessWidget {
  const _SeasonPulse({required this.entries, required this.month});

  final List<FoodEntry> entries;
  final int month;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final cs = Theme.of(context).colorScheme;
    var peak = 0, inSeason = 0;
    for (final e in entries) {
      final st = e.calendar.at(month);
      if (st == SeasonState.peakSeason) peak++;
      if (st.isAvailable) inSeason++;
    }
    return InkWell(
      onTap: () => SeasonLegendSheet.show(context),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              s.pulse(peak, inSeason),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(width: 4),
            Icon(Icons.info_outline_rounded, size: 14, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// Chip rimovibili per i filtri avanzati attivi, così l'utente vede sempre
/// perché mancano alcuni alimenti.
class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final home = context.watch<HomeController>();
    final db = context.read<FoodDatabase>();
    final lang = context.watch<SettingsController>().language;
    final chips = <Widget>[];
    // Frutta e Verdura si vedono già accese nella barra: niente tag. Delle
    // sottocategorie di "Altro" si mostra quale è filtrata.
    for (final c in home.otherCategoryTags) {
      chips.add(InputChip(label: Text(s.category(c)), onDeleted: () => home.toggleCategory(c)));
    }
    for (final st in home.states) {
      chips.add(InputChip(label: Text(s.state(st)), onDeleted: () => home.toggleState(st)));
    }
    for (final r in home.ripening) {
      chips.add(InputChip(
        label: Text(db.vocab('ripening_and_storage.ripening_type', r).of(lang)),
        onDeleted: () => home.toggleRipening(r),
      ));
    }
    for (final l in home.storage) {
      chips.add(InputChip(
        avatar: SlotIcon(storageSlot(l), size: 16),
        label: Text(db.vocab('ripening_and_storage.primary_location', l).of(lang)),
        onDeleted: () => home.toggleStorage(l),
      ));
    }
    for (final l in home.carbon) {
      chips.add(InputChip(
        avatar: const SlotIcon('detail.carbon_footprint', size: 16),
        label: Text(s.carbonTag(db.vocab('sustainability_level', l).of(lang))),
        onDeleted: () => home.toggleCarbon(l),
      ));
    }
    for (final l in home.water) {
      chips.add(InputChip(
        avatar: const SlotIcon('detail.water_footprint', size: 16),
        label: Text(s.waterTag(db.vocab('sustainability_level', l).of(lang))),
        onDeleted: () => home.toggleWater(l),
      ));
    }
    if (home.dopOnly) {
      chips.add(InputChip(label: Text(s.dopOnlyChip), onDeleted: () => home.setDopOnly(false)));
    }
    if (home.includeNoData) {
      chips.add(InputChip(
        avatar: const SlotIcon('seasonality.estimates.unknown', size: 16),
        label: Text(s.noDataChip),
        onDeleted: () => home.setIncludeNoData(false),
      ));
    }
    if (home.showHidden) {
      chips.add(InputChip(
        avatar: const SlotIcon('home.hidden_visible', size: 16),
        label: Text(s.hiddenVisible),
        onDeleted: () => home.setShowHidden(false),
      ));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) => Theme(
          data: Theme.of(context).copyWith(visualDensity: VisualDensity.compact),
          child: chips[i],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.bottomPadding});
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(32, 24, 32, bottomPadding),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SlotIcon('home.no_results', size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(s.noResults, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(s.noResultsHint, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: context.read<HomeController>().resetAll,
              child: Text(s.clearFilters),
            ),
          ],
        ),
      ),
    );
  }
}
