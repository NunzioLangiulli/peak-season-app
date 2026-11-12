import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/food_repository.dart';
import '../l10n/strings.dart';
import '../models/app_enums.dart';
import '../models/food_item.dart';
import '../models/glossary.dart';
import '../models/nutrition_claims.dart';
import '../models/season_state.dart';
import '../providers/detail_layout_controller.dart';
import '../providers/home_controller.dart';
import '../providers/library_controller.dart';
import '../providers/settings_controller.dart';
import '../theme/season_palette.dart';
import '../widgets/calendar_view.dart';
import '../widgets/food_actions.dart';
import '../widgets/food_image.dart';
import '../widgets/help_button.dart';
import '../widgets/fullscreen_gallery.dart';
import '../widgets/seasonality_three_dots.dart';
import '../widgets/source_link_tile.dart';
import '../widgets/storage_summary.dart';
import 'family_screen.dart';
import '../theme/app_backdrop.dart';
import '../theme/icon_service.dart';

/// Scheda alimento, nell'ordine del wireframe: galleria, categoria, nome e
/// azioni, stato, nome scientifico, calendario, poi le sezioni del database.
/// Le ricette arrivano nella Fase 3.
class FoodDetailScreen extends StatefulWidget {
  const FoodDetailScreen({super.key, required this.itemId});
  final String itemId;

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  final _page = PageController();
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final db = context.read<FoodDatabase>();
    final item = db.byId[widget.itemId]!;
    final settings = context.watch<SettingsController>();
    final lang = settings.language;
    final month = context.select<HomeController, int>((h) => h.month);
    final calendar = settings.resolver.resolve(item);
    final lib = context.watch<LibraryController>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final gallery = item.gallery;
    final credit = gallery.isEmpty ? null : item.imageCredits[gallery[_index]];
    final state = calendar.at(month);
    final layout = context.watch<DetailLayoutController>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 300,
            backgroundColor: (theme.brightness == Brightness.dark ? Colors.black : const Color(0xFFF3F5EE)).withValues(
              alpha: 0.86,
            ),
            leading: Padding(
              padding: const EdgeInsets.all(6),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.35),
                child: const BackButton(color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (gallery.isEmpty)
                    Hero(
                      tag: 'food-${item.id}',
                      child: FoodImagePlaceholder(category: item.category),
                    )
                  else
                    PageView.builder(
                      controller: _page,
                      itemCount: gallery.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (_, i) {
                        final img = GestureDetector(
                          onTap: () => FullscreenGallery.show(context, item, initialIndex: i),
                          child: FoodImage(item: item, file: gallery[i], full: true),
                        );
                        return i == 0 ? Hero(tag: 'food-${item.id}', child: img) : img;
                      },
                    ),
                  if (gallery.length > 1)
                    Positioned(
                      bottom: 14,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < gallery.length; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: i == _index ? 18 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: i == _index ? 0.95 : 0.55),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (credit != null)
                    Positioned(
                      right: 8,
                      bottom: 30,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 240),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '© ${credit.author} · ${credit.license}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Intestazione --------------------------------------
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Chip(visualDensity: VisualDensity.compact, label: Text(s.category(item.category))),
                      Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: SeasonDot(state: state, size: 18, showIcon: true),
                        label: Text(
                          '${state == SeasonState.unknown ? s.unknownTitle : s.state(state)}'
                          '${calendar.isApproximate ? ' ≈' : ''}',
                        ),
                        backgroundColor: SeasonPalette.color(state, theme.brightness).withValues(alpha: 0.15),
                      ),
                      if (item.hasDopIgp) Chip(visualDensity: VisualDensity.compact, label: Text(s.dopOnlyChip)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.name.of(lang),
                          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      SeasonalityThreeDots(calendar: calendar, month: month, scale: 1.3),
                    ],
                  ),
                  if (item.scientificName != null)
                    Row(
                      children: [
                        Flexible(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                item.scientificName!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              if (item.family != null) ...[
                                Text(' · ', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                                // La famiglia apre l'elenco degli alimenti della stessa famiglia
                                InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () =>
                                      Navigator.of(context)
                                          .push(AppPageRoute(builder: (_) => FamilyScreen(family: item.family!))),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          db.familyName(item.family!).of(lang),
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: cs.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Icon(Icons.chevron_right_rounded, size: 18, color: cs.primary),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const HelpButton(field: 'botany.scientific_name', size: 16),
                      ],
                    ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: lib.isFavorite(item.id)
                              ? FoodActionStyle.favoriteActiveIcon
                              : FoodActionStyle.favoriteIcon,
                          color: lib.isFavorite(item.id) ? FoodActionStyle.favoriteColor : null,
                          label: s.favorite,
                          selected: lib.isFavorite(item.id),
                          onTap: () => lib.toggleFavorite(item.id),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionButton(
                          icon: lib.isDisliked(item.id)
                              ? FoodActionStyle.dislikeActiveIcon
                              : FoodActionStyle.dislikeIcon,
                          color: lib.isDisliked(item.id) ? _ActionButton.dangerColor : null,
                          danger: true,
                          label: s.dislike,
                          selected: lib.isDisliked(item.id),
                          onTap: () => lib.toggleDisliked(item.id),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionButton(
                          icon: lib.isInShoppingList(item.id)
                              ? FoodActionStyle.shoppingActiveIcon
                              : FoodActionStyle.shoppingIcon,
                          color: lib.isInShoppingList(item.id) ? FoodActionStyle.shoppingColor : null,
                          label: s.inList,
                          selected: lib.isInShoppingList(item.id),
                          onTap: () => lib.toggleShopping(item.id),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Blocchi nell'ordine e con la modalità scelti in Impostazioni.
                  for (final id in layout.visibleOrder)
                    switch (id) {
                      DetailSection.calendar => _Section(
                        id: DetailSection.calendar,
                        title: s.seasonCalendar,
                        helpLegend: true,
                        helpField:
                            settings.zone == ClimaticZone.mediterranean &&
                                settings.area != ItalyMacroArea.euficMediterranean
                            ? 'seasonality.italy_macro_areas'
                            : 'seasonality.eufic_climatic_zones',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _AreaLabel(
                              text: settings.zone == ClimaticZone.mediterranean
                                  ? s.area(settings.area)
                                  : s.zone(settings.zone),
                              area: settings.zone == ClimaticZone.mediterranean ? settings.area : null,
                            ),
                            const SizedBox(height: 8),
                            _HighlightedCalendar(calendar: calendar, month: month, height: 22),
                            // Prodotti a lunga conservazione: perché la stagione
                            // dura più della raccolta (seasonality.availability_note).
                            if (item.raw.text('seasonality.availability_note').of(lang).isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SlotIcon('detail.availability_note', size: 18, color: cs.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.raw.text('seasonality.availability_note').of(lang),
                                      style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (calendar.isApproximate) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '≈ ${db.vocab('seasonality.estimates', 'estimate').of(lang)}: '
                                      '${db.vocab('seasonality.estimates.from', calendar.sourceKey).of(lang)}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                  const HelpButton(ids: ['seasonality_estimate'], size: 16),
                                ],
                              ),
                            ],
                            if (!calendar.hasData) ...[
                              const SizedBox(height: 10),
                              _UnknownNotice(),
                              ?_referenceCalendar(
                                context,
                                settings.resolver.reference(item, order: db.referenceOrder),
                                month,
                              ),
                            ],
                          ],
                        ),
                      ),
                      DetailSection.varieties => _VarietiesSection(item: item),
                      DetailSection.buyStore => _BuyStoreSection(item: item),
                      DetailSection.nutrition => _NutritionSection(item: item),
                      DetailSection.sustainability => _SustainabilitySection(item: item),
                      DetailSection.garden => _GardenSection(item: item),
                      DetailSection.curiosities => _CuriositiesSection(item: item),
                      DetailSection.recipes => _Section(
                        id: DetailSection.recipes,
                        title: s.secRecipes,
                        child: Text(s.recipesSoon, style: theme.textTheme.bodyMedium),
                      ),
                      DetailSection.links => _LinksSection(item: item),
                    },
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Calendario di un'altra zona con dati veri, quando la zona scelta non ne ha.
Widget? _referenceCalendar(BuildContext context, SeasonCalendar? ref, int month) {
  if (ref == null) return null;
  final s = context.s;
  final db = context.read<FoodDatabase>();
  final lang = context.read<SettingsController>().language;
  final theme = Theme.of(context);
  final zone = ref.sourceKey == 'italy_national'
      ? s.italyNational
      : db.vocab('seasonality.eufic_climatic_zones', ref.sourceKey).of(lang);
  return Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.referenceCalendar(zone), style: theme.textTheme.titleSmall),
        Text(s.referenceNote, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Opacity(
          opacity: 0.85,
          child: _HighlightedCalendar(calendar: ref, month: month, height: 18),
        ),
      ],
    ),
  );
}

// =============================================================================
// Componenti comuni
// =============================================================================

/// Box di sezione richiudibile: titolo (tocca per aprire/chiudere), "?"
/// opzionale e contenuto. Lo stato iniziale viene dalle Impostazioni.
class _Section extends StatefulWidget {
  const _Section({
    required this.id,
    required this.title,
    required this.child,
    this.helpField,
    this.helpIds = const [],
    this.helpLegend = false,
  });

  /// Il "?" mostra anche la legenda dei colori (solo il calendario).
  final bool helpLegend;

  final DetailSection id;
  final String title;
  final Widget child;
  final String? helpField;
  final List<String> helpIds;

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  late bool _open = context.read<DetailLayoutController>().modeOf(widget.id) == SectionMode.open;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                child: Row(
                  children: [
                    SlotIcon(_sectionSlot(widget.id), size: 22, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(widget.title, style: theme.textTheme.titleMedium)),
                    if (widget.helpField != null || widget.helpIds.isNotEmpty || widget.helpLegend)
                      HelpButton(field: widget.helpField, ids: widget.helpIds, size: 20, showLegend: widget.helpLegend),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.expand_more_rounded, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _open
                  ? Padding(padding: const EdgeInsets.fromLTRB(16, 0, 12, 16), child: widget.child)
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

/// Slot dell'icona nel titolo di una sezione della scheda.
String _sectionSlot(DetailSection d) => switch (d) {
  DetailSection.calendar => 'detail.section.calendar',
  DetailSection.varieties => 'detail.section.varieties',
  DetailSection.buyStore => 'detail.section.buy_store',
  DetailSection.nutrition => 'detail.section.nutrition',
  DetailSection.sustainability => 'detail.section.sustainability',
  DetailSection.garden => 'detail.section.garden',
  DetailSection.curiosities => 'detail.section.curiosities',
  DetailSection.recipes => 'detail.section.recipes',
  DetailSection.links => 'detail.section.links',
};

/// Sottotitolo dentro una sezione, con "?" opzionale.
class _Sub extends StatelessWidget {
  const _Sub(this.text, {required this.icon, this.field, this.trailing});
  final String text;
  final String? field;

  /// Slot dell'icona davanti al sottotitolo: ogni titoletto ha la sua.
  final String icon;

  /// Tag accanto al titoletto ("Maturazione: Climaterico"); va a capo se
  /// non c'è spazio.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SlotIcon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  trailing == null ? text : '$text:',
                  style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              if (field != null) HelpButton(field: field, size: 16),
            ],
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// "Nord Italia" con la sagoma dell'Italia e la macro-area piena
/// (assets/icons/italy, da scripts/build_italy_area_icons.py).
class _AreaLabel extends StatelessWidget {
  const _AreaLabel({required this.text, this.area});
  final String text;
  final ItalyMacroArea? area;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final file = switch (area) {
      ItalyMacroArea.nord => 'nord',
      ItalyMacroArea.centro => 'centro',
      ItalyMacroArea.sudIsole => 'sud_isole',
      _ => null,
    };
    return Row(
      children: [
        if (file != null) ...[
          RefIcon('svg:italy/$file', size: 24, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
        ],
        Text(text, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _Para extends StatelessWidget {
  const _Para(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => text.isEmpty
      ? const SizedBox.shrink()
      : Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4));
}

/// Iniziali dei mesi e pallini da gennaio a dicembre, con la pillola
/// verticale dietro la colonna del mese selezionato (come nella vista 12 mesi).
class _HighlightedCalendar extends StatelessWidget {
  const _HighlightedCalendar({required this.calendar, required this.month, this.height = 22});
  final SeasonCalendar calendar;
  final int month;
  final double height;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final col = box.maxWidth / 12;
      return Stack(
        children: [
          Positioned(left: col * month + 1, width: col - 2, top: 0, bottom: 0, child: const MonthHighlightPill()),
          Column(
            children: [
              const SizedBox(height: 3),
              _MonthInitials(selected: month),
              const SizedBox(height: 4),
              MonthSquares(calendar: calendar, selected: month, height: height),
              const SizedBox(height: 2),
            ],
          ),
        ],
      );
    },
  );
}

class _MonthInitials extends StatelessWidget {
  const _MonthInitials({this.selected});
  final int? selected;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Row(
      children: [
        for (var m = 0; m < 12; m++)
          Expanded(
            child: Center(
              child: Text(
                s.monthInitial(m),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: m == selected ? FontWeight.w900 : FontWeight.w500,
                  color: m == selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _UnknownNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SeasonDot(state: SeasonState.unknown, size: 24, showIcon: true),
          const SizedBox(width: 10),
          Expanded(child: Text(s.unknownDescription, style: theme.textTheme.bodySmall?.copyWith(height: 1.4))),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.danger = false,
  });

  /// Rosso del tasto "Non lo Mangio" attivo.
  static const dangerColor = Color(0xFFE53935);

  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  /// Azione di esclusione: da attivo si colora di rosso invece che di verde
  /// (stesso alone degli altri pulsanti, cambia solo la tinta).
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tint = danger ? dangerColor : cs.primary;
    final selectedBg = danger
        ? Color.alphaBlend(dangerColor.withValues(alpha: 0.16), cs.surface)
        : cs.secondaryContainer;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: selected
            ? [BoxShadow(color: tint.withValues(alpha: danger ? 0.22 : 0.25), blurRadius: 14, spreadRadius: 0.5)]
            : null,
      ),
      child: Material(
        color: selected ? selectedBg : cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(
              children: [
                SlotIcon(icon, color: color ?? cs.onSurfaceVariant),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Sezioni
// =============================================================================

class _VarietiesSection extends StatelessWidget {
  const _VarietiesSection({required this.item});
  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final r = item.raw;
    final theme = Theme.of(context);
    final dop = r.list('italian_varieties_and_territories.dop_igp_labels').map((e) => '$e').toList();
    final varieties = r
        .list('italian_varieties_and_territories.notable_varieties')
        .map((e) => '$e')
        .where((v) => !dop.contains(v))
        .toList();
    final patCount = r.number('nutrition_and_sustainability.traditional_products_pat.count')?.toInt() ?? 0;
    final patRegions = r.list('nutrition_and_sustainability.traditional_products_pat.regions').length;
    if (dop.isEmpty && varieties.isEmpty && patCount == 0) return const SizedBox.shrink();

    return _Section(
      id: DetailSection.varieties,
      title: s.secVarieties,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dop.isNotEmpty) ...[
            _Sub(s.dopIgp, icon: 'detail.dop_igp', field: 'italian_varieties_and_territories.dop_igp_labels'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final d in dop)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: const SlotIcon('detail.dop_igp', size: 20),
                    label: Text(d, style: theme.textTheme.labelMedium),
                  ),
              ],
            ),
          ],
          if (varieties.isNotEmpty) ...[
            _Sub(s.notableVarieties, icon: 'detail.notable_varieties', field: 'italian_varieties_and_territories.notable_varieties'),
            _Para(varieties.join(' · ')),
          ],
          if (patCount > 0) ...[
            _Sub('PAT', icon: 'detail.pat', field: 'nutrition_and_sustainability.traditional_products_pat'),
            _Para(s.patCount(patCount, patRegions)),
          ],
        ],
      ),
    );
  }
}

class _BuyStoreSection extends StatelessWidget {
  const _BuyStoreSection({required this.item});
  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = context.watch<SettingsController>().language;
    final r = item.raw;
    const base = 'ripening_and_storage';
    final speedUp = r.text('$base.ripening_management.speed_up').of(lang);
    final slowDown = r.text('$base.ripening_management.slow_down').of(lang);
    final perish = r.text('$base.perishability.label').of(lang);
    // metadata.detail_display_rules.ripening.non_climacteric: un prodotto
    // non climaterico non matura dopo la raccolta, quindi niente "Per Farlo
    // Maturare"; il "Per Rallentare" diventa un consiglio di conservazione.
    final climacteric = item.ripeningType == 'climaterico';

    return _Section(
      id: DetailSection.buyStore,
      title: s.secBuyStore,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Sub(s.whatToLookFor, icon: 'detail.how_to_choose'),
          _Para(r.text('buying_guide.detailed_selection').of(lang)),
          const Divider(height: 28),
          // Il significato (es. "non matura dopo la raccolta") è nel "?" del tag.
          _Sub(s.ripening, icon: 'detail.ripening', trailing: RipeningTypeLabel(item: item)),
          if (climacteric) ...[
            if (speedUp.isNotEmpty) ...[_Sub(s.ripeningSpeedUp, icon: 'detail.speed_up', field: '$base.ethylene_compatibility'), _Para(speedUp)],
            if (slowDown.isNotEmpty) ...[_Sub(s.ripeningSlowDown, icon: 'detail.slow_down'), _Para(slowDown)],
          ],
          const Divider(height: 28),
          StorageSummary(item: item, keepLonger: climacteric ? '' : slowDown),
          if (perish.isNotEmpty) ...[
            _Sub(s.perishability, icon: 'detail.perishability', field: '$base.perishability'),
            _Para('$perish. ${r.text('$base.perishability.tip').of(lang)}'),
          ],
        ],
      ),
    );
  }
}

class _NutritionSection extends StatelessWidget {
  const _NutritionSection({required this.item});
  final FoodItem item;

  static String _n(num? v) {
    if (v == null) return '–';
    if (v >= 10) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1).replaceAll('.0', '');
  }

  /// Verde chiaro dei riquadri "impronta bassa" della Sostenibilità.
  static const _favorable = Color(0xFF2E7D32);
  static const _warning = Color(0xFFC62828);

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = context.watch<SettingsController>().language;
    final db = context.read<FoodDatabase>();
    final r = item.raw;
    const base = 'nutrition_and_sustainability';
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final kcal = r.number('$base.kcal_per_100g');
    if (kcal == null) return const SizedBox.shrink();

    // Indicazioni UE: testi del prodotto (IT e EN allineati) + regole del
    // database (gruppo, nutriente, tono).
    final claimsIt = r.list('$base.nutrition_claims_eu.it').map((e) => '$e').toList();
    final claimsLang = r.list('$base.nutrition_claims_eu.${lang.name}').map((e) => '$e').toList();
    final claims = [
      for (var i = 0; i < claimsIt.length; i++)
        (text: i < claimsLang.length ? claimsLang[i] : claimsIt[i], rule: db.claimRules.claims[claimsIt[i]]),
    ];
    // nutriente -> tono più "forte" (un avviso vince su una nota favorevole)
    final toneOf = <String, String>{};
    for (final c in claims) {
      final rule = c.rule;
      if (rule == null) continue;
      if (toneOf[rule.nutrient] != 'warning') toneOf[rule.nutrient] = rule.tone;
    }

    final micros =
        [...r.list('$base.vitamins'), ...r.list('$base.minerals')]
            .whereType<Map>()
            .where((m) => (m['percent_nrv'] as num? ?? 0) >= 7.5 || toneOf.containsKey(m['key']))
            .toList()
          ..sort((a, b) => (b['percent_nrv'] as num).compareTo(a['percent_nrv'] as num));

    // Riquadro di un valore per 100 g: grigio, verde se un'indicazione UE lo
    // segnala in positivo, rosso se lo segnala come da tenere d'occhio.
    Widget macro(String label, num? v, String unit, List<String> nutrients) {
      final tone = nutrients
          .map((n) => toneOf[n])
          .whereType<String>()
          .fold<String?>(null, (a, t) => a == 'warning' || t == 'warning' ? 'warning' : t);
      final color = switch (tone) {
        'favorable' => _favorable,
        'warning' => _warning,
        _ => null,
      };
      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
          decoration: BoxDecoration(
            color: color?.withValues(alpha: 0.13) ?? cs.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('${_n(v)}$unit', style: theme.textTheme.titleMedium?.copyWith(color: color)),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: theme.textTheme.labelSmall?.copyWith(color: color ?? cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget claimChip(String text, ClaimRule? rule) => Chip(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(color: (rule?.isWarning ?? false) ? _warning.withValues(alpha: 0.5) : cs.outlineVariant),
      label: Text(text, style: theme.textTheme.labelSmall),
    );

    // Raggruppamento per prefisso solo se il gruppo ha almeno 2 indicazioni
    // e in tutto ce ne sono abbastanza; le altre restano chip singoli.
    final byGroup = <String, List<({String text, ClaimRule? rule})>>{};
    for (final c in claims) {
      if (c.rule != null) (byGroup[c.rule!.group] ??= []).add(c);
    }
    final grouped = claims.length >= 4
        ? (byGroup.entries.where((e) => e.value.length >= 2).toList()..sort(
            (a, b) => (db.claimRules.groups[a.key]?.order ?? 99).compareTo(db.claimRules.groups[b.key]?.order ?? 99),
          ))
        : <MapEntry<String, List<({String text, ClaimRule? rule})>>>[];
    final groupedClaims = {for (final g in grouped) ...g.value.map((c) => c.text)};
    final loose = claims.where((c) => !groupedClaims.contains(c.text)).toList()
      ..sort((a, b) => a.text.length.compareTo(b.text.length));

    final peakGreen = SeasonPalette.color(SeasonState.peakSeason, theme.brightness);

    return _Section(
      id: DetailSection.nutrition,
      title: s.secNutrition,
      helpIds: const ['edible_portion'],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.per100g, style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          Row(
            children: [
              macro('kcal', kcal, '', const ['kcal']),
              macro(s.carbs, r.number('$base.macros_per_100g.carbs_g'), ' g', const ['sugars']),
              macro(s.proteins, r.number('$base.macros_per_100g.proteins_g'), ' g', const ['proteins']),
              macro(s.fats, r.number('$base.macros_per_100g.fats_g'), ' g', const ['fats']),
              macro(s.fiber, r.number('$base.macros_per_100g.fiber_g'), ' g', const ['fiber']),
            ],
          ),
          if (claims.isNotEmpty) ...[
            _Sub(s.nutritionClaims, icon: 'detail.nutrition_claims', field: '$base.nutrition_claims_eu'),
            if (loose.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(spacing: 6, runSpacing: 6, children: [for (final c in loose) claimChip(c.text, c.rule)]),
              ),
            for (final g in grouped)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                // "A Basso Contenuto di:  [Calorie] [Zuccheri]" sulla stessa riga
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '${db.claimRules.groups[g.key]?.label.of(lang) ?? g.key}:',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    for (final c in g.value) claimChip(c.rule!.nutrientLabel.of(lang), c.rule),
                  ],
                ),
              ),
          ],
          if (micros.isNotEmpty) ...[
            _Sub(s.vitaminsMinerals, icon: 'detail.vitamins_minerals', field: '$base.vitamins'),
            for (final m in micros.take(8))
              Builder(
                builder: (context) {
                  // Il nutriente citato da un'indicazione UE risalta (verde del Picco).
                  final claimed = toneOf.containsKey(m['key']);
                  final key = m['key'] as String?;
                  // nome breve uniforme dal database ("Vitamina A", non "Vitamina A (Retinolo…)")
                  final name = db.claimRules.nutrientNames[key]?.of(lang) ??
                      '${lang == AppLanguage.en ? (m['name_en'] ?? m['name']) : m['name']}'
                          .replaceAll(RegExp(r'\s*\([^)]*\)'), '');
                  final pct = (m['percent_nrv'] as num).round();
                  final weight = claimed ? FontWeight.w800 : FontWeight.w600;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: weight),
                          ),
                        ),
                        SizedBox(
                          width: 92,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (pct / 100).clamp(0.0, 1.0).toDouble(),
                              minHeight: 7,
                              color: claimed ? peakGreen : cs.primary.withValues(alpha: 0.45),
                              backgroundColor: cs.surfaceContainerHighest,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 104,
                          child: Text.rich(
                            TextSpan(children: [
                              // quantità vera per 100 g, poi la % dei valori di riferimento
                              TextSpan(text: '${_n(m['amount'] as num?)} ${m['unit'] ?? ''} '),
                              TextSpan(
                                text: '($pct%)',
                                style: TextStyle(fontWeight: weight, color: claimed ? peakGreen : null),
                              ),
                            ]),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}

class _SustainabilitySection extends StatelessWidget {
  const _SustainabilitySection({required this.item});
  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = context.watch<SettingsController>().language;
    final r = item.raw;
    const base = 'nutrition_and_sustainability.environmental_footprint';
    final theme = Theme.of(context);
    final carbon = r.number('$base.carbon_kg_co2eq_per_kg');
    final water = r.number('$base.water_l_per_kg');
    if (carbon == null && water == null) return const SizedBox.shrink();
    final beefC = r.number('$base.sustainability_rating.times_lower_than_beef_carbon')?.toInt();
    final tips = r.text('$base.sustainability_rating.tips').of(lang);

    // Stessa altezza per i due riquadri (IntrinsicHeight + stretch): il
    // contenuto resta in alto, lo spazio in più va in fondo.
    Widget tile(String icon, String title, String value, String label, Color color) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SlotIcon(icon, color: color),
            const SizedBox(height: 6),
            Text(value, style: theme.textTheme.titleMedium, semanticsLabel: '$title: $value'),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(color: Color.lerp(color, theme.colorScheme.onSurface, 0.25)),
            ),
          ],
        ),
      ),
    );

    final db = context.read<FoodDatabase>();
    // environmental_footprint_method.levels.*.color_hex
    Color level(String? l) => Color(db.footprintColor(l));

    return _Section(
      id: DetailSection.sustainability,
      title: s.secSustainability,
      helpField: 'nutrition_and_sustainability.environmental_footprint',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (carbon != null)
                  tile(
                    'detail.carbon_footprint',
                    s.carbonFootprint,
                    '${carbon.toStringAsFixed(2)} kg CO₂e/kg',
                    r.text('$base.sustainability_rating.carbon_label').of(lang),
                    level(r.at('$base.sustainability_rating.carbon_level') as String?),
                  ),
                if (carbon != null && water != null) const SizedBox(width: 8),
                if (water != null)
                  tile(
                    'detail.water_footprint',
                    s.waterFootprint,
                    '${water.round()} L/kg',
                    r.text('$base.sustainability_rating.water_label').of(lang),
                    level(r.at('$base.sustainability_rating.water_level') as String?),
                  ),
              ],
            ),
          ),
          if (beefC != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                SlotIcon('detail.beef_comparison', size: 22, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(s.timesLowerBeef(beefC), style: theme.textTheme.bodyMedium)),
              ],
            ),
          ],
          if (tips.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _Para(tips)),
                const HelpButton(ids: ['greenhouse'], size: 16),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GardenSection extends StatelessWidget {
  const _GardenSection({required this.item});
  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final settings = context.watch<SettingsController>();
    final lang = settings.language;
    final theme = Theme.of(context);
    final areaKey = settings.area.dbKey ?? 'nord';
    final area = item.raw.obj('agricultural_calendar_italy.$areaKey');
    if (area.isEmpty) return const SizedBox.shrink();
    Set<int> months(String k) => {...((area[k] as List?) ?? const []).whereType<num>().map((e) => e.toInt() - 1)};
    final sowing = months('sowing_or_transplant_months');
    final harvest = months('harvest_months');
    if (sowing.isEmpty && harvest.isEmpty) return const SizedBox.shrink();
    final notes = LocalizedText.fromJson(area['cultivation_notes']).of(lang);

    Widget bar(String label, Set<int> on, Color color) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: theme.textTheme.labelMedium)),
          Expanded(
            child: Row(
              children: [
                for (var m = 0; m < 12; m++)
                  Expanded(
                    child: Container(
                      height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: on.contains(m) ? color : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    return _Section(
      id: DetailSection.garden,
      title: s.secGarden,
      helpField: 'agricultural_calendar_italy',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AreaLabel(
            text: s.area(settings.area.dbKey == null ? ItalyMacroArea.nord : settings.area),
            area: settings.area.dbKey == null ? ItalyMacroArea.nord : settings.area,
          ),
          const SizedBox(height: 6),
          const Row(
            children: [
              SizedBox(width: 110),
              Expanded(child: _MonthInitials()),
            ],
          ),
          bar(s.sowing, sowing, const Color(0xFF8D6E63)),
          bar(s.harvest, harvest, const Color(0xFF43A047)),
          if (notes.isNotEmpty) ...[const SizedBox(height: 10), _Para(notes)],
        ],
      ),
    );
  }
}

class _CuriositiesSection extends StatelessWidget {
  const _CuriositiesSection({required this.item});
  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = context.watch<SettingsController>().language;
    final r = item.raw;
    final benefits = r.text('nutrition_and_sustainability.health_benefits_and_curiosities').of(lang);
    final waste = r.text('nutrition_and_sustainability.culinary_waste_reduction').of(lang);
    if (benefits.isEmpty && waste.isEmpty) return const SizedBox.shrink();
    return _Section(
      id: DetailSection.curiosities,
      title: s.secCuriosities,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (benefits.isNotEmpty) ...[_Sub(s.curiosities, icon: 'detail.curiosities'), _Para(benefits)],
          if (waste.isNotEmpty) ...[_Sub(s.antiWaste, icon: 'detail.zero_waste'), _Para(waste)],
        ],
      ),
    );
  }
}

class _LinksSection extends StatelessWidget {
  const _LinksSection({required this.item});
  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = context.watch<SettingsController>().language;
    final theme = Theme.of(context);
    final links = item.raw.list('sources_by_topic.useful_links').whereType<Map>().toList();
    // Provenienza tecnica della curva stagionale: solo qui, tra le fonti.
    final curveBasis = item.raw.text('seasonality.curve_basis').of(lang);
    if (links.isEmpty && curveBasis.isEmpty) return const SizedBox.shrink();
    return _Section(
      id: DetailSection.links,
      title: s.secLinks,
      helpIds: const ['data_quality'],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final l in links) _SourceTile(link: l, lang: lang),
          if (curveBasis.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              s.curveBasisTitle,
              style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            Text(curveBasis, style: theme.textTheme.bodySmall?.copyWith(height: 1.35)),
          ],
        ],
      ),
    );
  }
}

/// Riga di un link utile ("Argomento - Fonte"): l'argomento in grassetto,
/// la fonte sotto in grigio.
class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.link, required this.lang});
  final Map link;
  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    final full = LocalizedText.fromJson(link['title']).of(lang);
    final cut = full.lastIndexOf(' - ');
    return SourceLinkTile(
      title: cut > 0 ? full.substring(0, cut) : full,
      subtitle: cut > 0 ? full.substring(cut + 3) : '',
      url: link['url'] as String?,
      sourceKey: link['source_key'] as String?,
      favicon: link['favicon'] as String?,
    );
  }
}
