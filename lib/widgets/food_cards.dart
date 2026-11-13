import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/app_enums.dart';
import '../models/food_item.dart';
import '../providers/home_controller.dart';
import '../providers/library_controller.dart';
import '../providers/settings_controller.dart';
import 'food_actions.dart';
import 'food_image.dart';
import 'seasonality_three_dots.dart';
import 'storage_summary.dart';
import '../theme/icon_service.dart';

/// 2-column Home grid (shared with the "No Data" section).
const homeGridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 260,
  mainAxisSpacing: 12,
  crossAxisSpacing: 12,
  childAspectRatio: 0.74,
);


/// Piccoli badge sovrapposti in alto a sinistra: DOP/IGP e "nascosto".
class _TopLeftBadges extends StatelessWidget {
  const _TopLeftBadges({required this.item});
  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final disliked = context.select<LibraryController, bool>((l) => l.isDisliked(item.id));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (disliked)
          const _Badge(
            child: SlotIcon(FoodActionStyle.dislikeActiveIcon, size: 14, color: Colors.white),
          ),
        if (disliked && item.hasDopIgp) const SizedBox(width: 4),
        if (item.hasDopIgp)
          const _Badge(
            child: Text(
              'DOP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(20),
        ),
        child: child,
      );
}

/// MODE 1 — 2-column grid card.
class FoodGridCard extends StatelessWidget {
  const FoodGridCard({super.key, required this.entry});
  final FoodEntry entry;

  @override
  Widget build(BuildContext context) {
    final lang = context.select<SettingsController, AppLanguage>((s) => s.language);
    final month = context.select<HomeController, int>((h) => h.month);
    final item = entry.item;
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () => FoodNavigation.openDetail(context, item),
        onLongPress: () => FoodNavigation.showQuickActions(context, item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(tag: 'food-${item.id}', child: FoodImage(item: item)),
                  Positioned(top: 8, right: 8, child: ShoppingFavoriteButtons(item: item, size: 32)),
                  Positioned(top: 10, left: 8, child: _TopLeftBadges(item: item)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name.of(lang),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(fontSize: 15, height: 1.15),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SeasonalityThreeDots(calendar: entry.calendar, month: month),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _StorageLine(item: item, maxLines: 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorageLine extends StatelessWidget {
  const _StorageLine({required this.item, this.maxLines = 1});
  final FoodItem item;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final lang = context.select<SettingsController, AppLanguage>((s) => s.language);
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: SlotIcon(storageSlot(item.primaryLocation), size: 15, color: color),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            item.cardShortStorage.of(lang),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: color, height: 1.25),
          ),
        ),
      ],
    );
  }
}

/// MODE 2 — full-width horizontal card.
class FoodListCard extends StatelessWidget {
  const FoodListCard({super.key, required this.entry});
  final FoodEntry entry;

  @override
  Widget build(BuildContext context) {
    final lang = context.select<SettingsController, AppLanguage>((s) => s.language);
    final month = context.select<HomeController, int>((h) => h.month);
    final item = entry.item;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: InkWell(
        onTap: () => FoodNavigation.openDetail(context, item),
        onLongPress: () => FoodNavigation.showQuickActions(context, item),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(tag: 'food-${item.id}', child: FoodImage(item: item)),
                      Positioned(top: 5, left: 5, child: _TopLeftBadges(item: item)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name.of(lang),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(height: 1.15),
                          ),
                        ),
                        SeasonalityThreeDots(calendar: entry.calendar, month: month),
                        const SizedBox(width: 6),
                        _CompactToggles(item: item),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _InfoPill(
                          icon: storageSlot(item.primaryLocation),
                          text: item.cardShortStorage.of(lang),
                          color: cs.secondaryContainer,
                          onColor: cs.onSecondaryContainer,
                        ),
                        RipeningTypeLabel(item: item, compact: true),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // "How to Choose the Best": the icon says what the text refers to.
                    Text.rich(
                      TextSpan(children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: SlotIcon('home.list_card_how_to_choose', size: 15, color: cs.primary),
                          ),
                        ),
                        TextSpan(text: item.shoppingListPreview.of(lang)),
                      ]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 📋 and ❤️ as small icons without background (list cards and rows).
class _CompactToggles extends StatelessWidget {
  const _CompactToggles({required this.item});
  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lib = context.watch<LibraryController>();
    final inList = lib.isInShoppingList(item.id);
    final fav = lib.isFavorite(item.id);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    Widget btn(String i, Color c, String tip, VoidCallback onTap) => IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          iconSize: 20,
          tooltip: tip,
          onPressed: onTap,
          icon: SlotIcon(i, color: c),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(
          inList ? FoodActionStyle.shoppingActiveIcon : FoodActionStyle.shoppingIcon,
          inList ? FoodActionStyle.shoppingColor : muted,
          inList ? s.removeFromList : s.addToList,
          () => lib.toggleShopping(item.id),
        ),
        btn(
          fav ? FoodActionStyle.favoriteActiveIcon : FoodActionStyle.favoriteIcon,
          fav ? FoodActionStyle.favoriteColor : muted,
          fav ? s.removeFavorite : s.addFavorite,
          () => lib.toggleFavorite(item.id),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.text,
    required this.color,
    required this.onColor,
  });

  final String icon;
  final String text;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SlotIcon(icon, size: 13, color: onColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: onColor),
            ),
          ),
        ],
      ),
    );
  }
}
