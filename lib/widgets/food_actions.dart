import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/food_repository.dart';
import '../l10n/strings.dart';
import '../models/food_item.dart';
import '../providers/library_controller.dart';
import '../providers/settings_controller.dart';
import '../screens/food_detail_screen.dart';
import '../theme/app_backdrop.dart';
import '../theme/icon_service.dart';

/// Pulsante circolare semitrasparente sovrapposto all'immagine (📋 / ❤️).
class OverlayActionButton extends StatelessWidget {
  const OverlayActionButton({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.active,
    required this.activeColor,
    required this.tooltip,
    required this.onPressed,
    this.size = 34,
  });

  /// IconService slot.
  final String icon;
  final String activeIcon;
  final bool active;
  final Color activeColor;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: active,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: active ? Colors.white.withValues(alpha: 0.95) : Colors.black.withValues(alpha: 0.32),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              HapticFeedback.selectionClick();
              onPressed();
            },
            child: SizedBox(
              width: size,
              height: size,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: SlotIcon(
                  active ? activeIcon : icon,
                  key: ValueKey(active),
                  size: size * 0.55,
                  color: active ? activeColor : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared icons/colours of the three actions.
class FoodActionStyle {
  static const shoppingIcon = 'action.shopping_list.add';
  static const shoppingActiveIcon = 'action.shopping_list.active';
  static const favoriteIcon = 'action.favorite.add';
  static const favoriteActiveIcon = 'action.favorite.active';
  static const dislikeIcon = 'action.dislike.add';
  static const dislikeActiveIcon = 'action.dislike.active';
  static const favoriteColor = Color(0xFFE53950);
  static const shoppingColor = Color(0xFF2E7D32);
}

/// 📋 + ❤️ pair for grid and list cards.
class ShoppingFavoriteButtons extends StatelessWidget {
  const ShoppingFavoriteButtons({super.key, required this.item, this.size = 34});

  final FoodItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lib = context.watch<LibraryController>();
    final inList = lib.isInShoppingList(item.id);
    final fav = lib.isFavorite(item.id);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OverlayActionButton(
          icon: FoodActionStyle.shoppingIcon,
          activeIcon: FoodActionStyle.shoppingActiveIcon,
          active: inList,
          activeColor: FoodActionStyle.shoppingColor,
          tooltip: inList ? s.removeFromList : s.addToList,
          size: size,
          onPressed: () => lib.toggleShopping(item.id),
        ),
        SizedBox(width: size * 0.18),
        OverlayActionButton(
          icon: FoodActionStyle.favoriteIcon,
          activeIcon: FoodActionStyle.favoriteActiveIcon,
          active: fav,
          activeColor: FoodActionStyle.favoriteColor,
          tooltip: fav ? s.removeFavorite : s.addFavorite,
          size: size,
          onPressed: () => lib.toggleFavorite(item.id),
        ),
      ],
    );
  }
}

/// Apertura scheda alimento e menu rapido (pressione prolungata).
class FoodNavigation {
  static void openDetail(BuildContext context, FoodItem item) {
    Navigator.of(context).push(
      AppPageRoute(builder: (_) => FoodDetailScreen(itemId: item.id)),
    );
  }

  /// Quick menu with the three actions, including "I don't eat it", which on the card
  /// has no button of its own so as not to crowd it.
  static void showQuickActions(BuildContext context, FoodItem item) {
    HapticFeedback.mediumImpact();
    final lang = context.read<SettingsController>().language;
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final s = ctx.s;
        final lib = ctx.watch<LibraryController>();
        final db = ctx.read<FoodDatabase>();
        final current = db.byId[item.id]!;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(current.name.of(lang), style: Theme.of(ctx).textTheme.titleLarge),
              ),
              ListTile(
                leading: SlotIcon(lib.isInShoppingList(item.id)
                    ? FoodActionStyle.shoppingActiveIcon
                    : FoodActionStyle.shoppingIcon),
                title: Text(lib.isInShoppingList(item.id) ? s.removeFromList : s.addToList),
                onTap: () => lib.toggleShopping(item.id),
              ),
              ListTile(
                leading: SlotIcon(
                  lib.isFavorite(item.id)
                      ? FoodActionStyle.favoriteActiveIcon
                      : FoodActionStyle.favoriteIcon,
                  color: FoodActionStyle.favoriteColor,
                ),
                title: Text(lib.isFavorite(item.id) ? s.removeFavorite : s.addFavorite),
                onTap: () => lib.toggleFavorite(item.id),
              ),
              ListTile(
                leading: SlotIcon(lib.isDisliked(item.id)
                    ? FoodActionStyle.dislikeActiveIcon
                    : FoodActionStyle.dislikeIcon),
                title: Text(lib.isDisliked(item.id) ? s.undislike : s.dislike),
                onTap: () {
                  final wasDisliked = lib.isDisliked(item.id);
                  lib.toggleDisliked(item.id);
                  if (!wasDisliked) {
                    Navigator.pop(ctx);
                    messenger.showSnackBar(SnackBar(
                      content: Text(s.hiddenSnack(current.name.of(lang))),
                      action: SnackBarAction(
                        label: s.undo,
                        onPressed: () => lib.toggleDisliked(item.id),
                      ),
                    ));
                  }
                },
              ),
              ListTile(
                leading: const SlotIcon('action.open_detail'),
                title: Text(current.name.of(lang)),
                onTap: () {
                  Navigator.pop(ctx);
                  openDetail(context, current);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
