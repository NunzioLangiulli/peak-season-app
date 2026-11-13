import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/food_repository.dart';
import '../l10n/strings.dart';
import '../models/food_item.dart';
import '../models/glossary.dart';
import '../providers/home_controller.dart';
import '../providers/library_controller.dart';
import '../providers/settings_controller.dart';
import '../widgets/food_actions.dart';
import '../widgets/food_image.dart';
import '../widgets/help_button.dart';
import '../widgets/pill_nav_bar.dart';
import '../widgets/seasonality_three_dots.dart';
import 'home_screen.dart' show ShoppingModeToggle;
import 'storage_tips_screen.dart';
import '../theme/app_backdrop.dart';
import '../theme/icon_service.dart';

/// TAB 2 — Shopping List, designed for use at the counter/in the supermarket:
/// "in the cart" tick, what to check, weight to buy, and at the end the
/// storage tips.
class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final db = context.read<FoodDatabase>();
    final lib = context.watch<LibraryController>();
    final ids = lib.shoppingListIds.where(db.byId.containsKey).toList();
    // still to buy first, already in the cart at the bottom
    final toBuy = [for (final id in ids) if (!lib.isInCart(id)) id];
    final inCart = [for (final id in ids) if (lib.isInCart(id)) id];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.shoppingTitle),
        centerTitle: true,
        actions: [
          const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: ShoppingModeToggle()),
          if (ids.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: s.clearList,
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (v) async {
                if (v == 'done') {
                  lib.clearCompleted();
                } else if (await _confirmClear(context, s)) {
                  lib.clearShopping();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'done',
                  enabled: inCart.isNotEmpty,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const SlotIcon('shopping.clear_completed'),
                    title: Text(s.clearCompleted),
                  ),
                ),
                PopupMenuItem(
                  value: 'all',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const SlotIcon('shopping.clear_list'),
                    title: Text(s.clearList),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 0, 16, PillNavBar.overlap(context)),
        children: [
          Text(
            s.shoppingCounter(toBuy.length, inCart.length),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          const _AddFoodField(),
          if (ids.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _StorageBanner(),
          ],
          const SizedBox(height: 12),
          if (ids.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
              child: Column(
                children: [
                  Text(s.shoppingEmpty, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  // The icon in the text is the same as on the cards ("add to list").
                  Text.rich(
                    TextSpan(children: [
                      for (final (i, part) in s.shoppingEmptyHint.split('{icon}').indexed) ...[
                        if (i > 0)
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: SlotIcon(FoodActionStyle.shoppingIcon, size: 18, color: theme.colorScheme.primary),
                          ),
                        TextSpan(text: part),
                      ],
                    ]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          for (final id in toBuy) _ShoppingCard(key: ValueKey('shop-$id'), item: db.byId[id]!),
          if (inCart.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              child: Row(
                children: [
                  SlotIcon('shopping.in_cart', size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(s.inCartHeader(inCart.length), style: theme.textTheme.titleSmall),
                ],
              ),
            ),
            for (final id in inCart) _ShoppingCard(key: ValueKey('shop-$id'), item: db.byId[id]!),
          ],
        ],
      ),
    );
  }

  Future<bool> _confirmClear(BuildContext context, S s) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(s.clearListConfirm),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.clearList)),
          ],
        ),
      ) ??
      false;
}

/// "+ Add Product": searches the database and adds without leaving the list.
class _AddFoodField extends StatefulWidget {
  const _AddFoodField();

  @override
  State<_AddFoodField> createState() => _AddFoodFieldState();
}

class _AddFoodFieldState extends State<_AddFoodField> {
  final _c = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final db = context.read<FoodDatabase>();
    final lib = context.watch<LibraryController>();
    final settings = context.watch<SettingsController>();
    final lang = settings.language;
    final month = context.select<HomeController, int>((h) => h.currentMonth);
    final q = normalizeForSearch(_q);
    final results = q.isEmpty
        ? const <FoodItem>[]
        : [for (final i in db.items) if (!lib.isInShoppingList(i.id) && i.matches(q)) i].take(6).toList();
    return Column(
      children: [
        TextField(
          controller: _c,
          onChanged: (v) => setState(() => _q = v),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: s.addFoodHint,
            prefixIcon: const Icon(Icons.add_rounded),
            suffixIcon: _q.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(() {
                      _c.clear();
                      _q = '';
                    }),
                  ),
            filled: true,
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
          ),
        ),
        for (final item in results)
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(width: 36, height: 36, child: FoodImage(item: item)),
            ),
            title: Text(item.name.of(lang)),
            subtitle: Text(s.category(item.category)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SeasonalityThreeDots(calendar: settings.resolver.resolve(item), month: month),
                IconButton(
                  tooltip: s.addToList,
                  icon: const SlotIcon('shopping.add_item'),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    lib.toggleShopping(item.id);
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// "Done shopping?" banner → storage guide.
class _StorageBanner extends StatelessWidget {
  const _StorageBanner();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.primaryContainer.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(AppPageRoute(builder: (_) => const StorageTipsScreen())),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(
            children: [
              SlotIcon('shopping.done_shopping', color: cs.onPrimaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.doneShoppingTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: cs.onPrimaryContainer)),
                    Text(s.doneShoppingSub,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onPrimaryContainer)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card of a product on the list: tick, what to check, weight to buy.
class _ShoppingCard extends StatefulWidget {
  const _ShoppingCard({super.key, required this.item});
  final FoodItem item;

  @override
  State<_ShoppingCard> createState() => _ShoppingCardState();
}

class _ShoppingCardState extends State<_ShoppingCard> {
  bool _calcOpen = false;
  final _grams = TextEditingController(text: '500');

  @override
  void dispose() {
    _grams.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final item = widget.item;
    final lib = context.watch<LibraryController>();
    final settings = context.watch<SettingsController>();
    final lang = settings.language;
    final month = context.select<HomeController, int>((h) => h.currentMonth);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final done = lib.isInCart(item.id);
    final edible = item.raw.number('nutrition_and_sustainability.edible_portion_percentage');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey('dismiss-${item.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(color: cs.errorContainer, borderRadius: BorderRadius.circular(20)),
          child: Icon(Icons.delete_outline_rounded, color: cs.onErrorContainer),
        ),
        onDismissed: (_) {
          final index = lib.shoppingListIds.indexOf(item.id);
          lib.removeFromShopping(item.id);
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(s.removedFromList),
              action: SnackBarAction(label: s.undo, onPressed: () => lib.insertInShopping(index, item.id)),
            ));
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: done ? 0.6 : 1,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: done,
                        shape: const CircleBorder(),
                        onChanged: (_) {
                          HapticFeedback.selectionClick();
                          lib.toggleInCart(item.id);
                        },
                      ),
                      GestureDetector(
                        onTap: () => FoodNavigation.openDetail(context, item),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(width: 52, height: 52, child: FoodImage(item: item)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => FoodNavigation.openDetail(context, item),
                          child: Text(
                            item.name.of(lang),
                            style: theme.textTheme.titleMedium?.copyWith(
                              decoration: done ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      ),
                      SeasonalityThreeDots(calendar: settings.resolver.resolve(item), month: month),
                    ],
                  ),
                  if (!done && !item.shoppingListPreview.isEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(6, 8, 0, 0),
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SlotIcon('shopping.how_to_choose', size: 17, color: cs.onSecondaryContainer),
                              const SizedBox(width: 6),
                              Text(s.whatToLookFor,
                                  style: theme.textTheme.labelLarge?.copyWith(color: cs.onSecondaryContainer)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(item.shoppingListPreview.of(lang),
                              style:
                                  theme.textTheme.bodyMedium?.copyWith(color: cs.onSecondaryContainer, height: 1.35)),
                        ],
                      ),
                    ),
                  if (!done && edible != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 6, top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => setState(() => _calcOpen = !_calcOpen),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                              child: Row(
                                children: [
                                  SlotIcon('shopping.weight_calculator', size: 19, color: cs.primary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(s.grossWeightCalc,
                                        style: theme.textTheme.labelLarge?.copyWith(color: cs.primary)),
                                  ),
                                  const HelpButton(ids: ['edible_portion'], size: 16),
                                  AnimatedRotation(
                                    turns: _calcOpen ? 0.5 : 0,
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(Icons.expand_more_rounded, color: cs.primary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            alignment: Alignment.topCenter,
                            child: !_calcOpen
                                ? const SizedBox(width: double.infinity)
                                : _GrossCalculator(controller: _grams, ediblePercent: edible.toDouble()),
                          ),
                        ],
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

/// Desired net weight → gross weight to buy, with the edible yield
/// (`nutrition_and_sustainability.edible_portion_percentage`).
class _GrossCalculator extends StatefulWidget {
  const _GrossCalculator({required this.controller, required this.ediblePercent});
  final TextEditingController controller;
  final double ediblePercent;

  @override
  State<_GrossCalculator> createState() => _GrossCalculatorState();
}

class _GrossCalculatorState extends State<_GrossCalculator> {
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final net = double.tryParse(widget.controller.text.replaceAll(',', '.')) ?? 0;
    final pct = widget.ediblePercent.clamp(1, 100);
    final gross = grossWeight(net, pct.toDouble());
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: TextField(
              controller: widget.controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: s.netWeight,
                suffixText: 'g',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: '${s.grossToBuy} '),
                TextSpan(text: '~$gross g', style: const TextStyle(fontWeight: FontWeight.w800)),
                TextSpan(text: '\n${s.edibleYield(pct.round())}'),
              ]),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gross weight to buy (rounded up to 10 g, "counter style").
int grossWeight(double netGrams, double ediblePercent) {
  if (netGrams <= 0 || ediblePercent <= 0) return 0;
  return ((netGrams * 100 / ediblePercent) / 10).ceil() * 10;
}
