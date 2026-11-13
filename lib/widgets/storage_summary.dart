import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/food_repository.dart';
import '../l10n/strings.dart';
import '../models/app_enums.dart';
import '../models/food_item.dart';
import '../models/glossary.dart';
import '../providers/settings_controller.dart';
import 'help_button.dart';
import '../theme/icon_service.dart';

/// Where to store it, for how long, what to keep away from it: used on the
/// "How to store them" page and on the product page.
class StorageSummary extends StatelessWidget {
  const StorageSummary({
    super.key,
    required this.item,
    this.showInstructions = true,
    this.showWhere = true,
    this.keepLonger = '',
  });

  final FoodItem item;
  final bool showInstructions;

  /// "To Keep It Longer": the "to slow down" of non-climacteric
  /// products (metadata.detail_display_rules), empty if not needed.
  final String keepLonger;

  /// false in the after-shopping guide, where the group already says where to put it.
  final bool showWhere;

  static String _range(Object? v) {
    if (v is List && v.length == 2) {
      final a = (v[0] as num).round(), b = (v[1] as num).round();
      return a == b ? '$a' : '$a-$b';
    }
    if (v is num) return v % 1 == 0 ? '${v.round()}' : '$v';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = context.watch<SettingsController>().language;
    final db = context.read<FoodDatabase>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final r = item.raw;
    const base = 'ripening_and_storage';
    final shelf = r.obj('$base.postharvest_physiology.estimated_shelf_life_days');
    final mode = shelf['room_temp_mode'];
    final room = _range(shelf['room_temp_days']);
    final fridge = _range(shelf['refrigerated_days']);
    final freezer = _range(shelf['in_freezer_months']);
    final keepAway = [
      for (final id in r.list('$base.ethylene_compatibility.keep_away_from'))
        if (db.byId[id] != null) db.byId[id]!.name.of(lang),
    ];

    // Subheading with icon; [trailing] (e.g. the location tag) sits on the same
    // line after the colon if there is room, otherwise it wraps.
    Widget label(String text, {String? field, required String icon, Widget? trailing}) => Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SlotIcon(icon, size: 18, color: cs.primary),
            const SizedBox(width: 6),
            Text(trailing == null ? text : '$text:', style: theme.textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
            if (field != null) HelpButton(field: field, size: 16),
          ],
        ),
        ?trailing,
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showWhere) ...[
          label(
            s.whereToStore,
            field: '$base.home_storage',
            icon: 'detail.where_to_store',
            trailing: r.text('$base.home_storage.label').isEmpty
                ? null
                : _Callout(
                    icon: storageSlot(item.primaryLocation),
                    text: r.text('$base.home_storage.label').of(lang),
                  ),
          ),
        ],
        // metadata.detail_display_rules.storage_order
        if (showInstructions && !r.text('$base.storage_instructions').isEmpty) ...[
          const SizedBox(height: 6),
          Text(r.text('$base.storage_instructions').of(lang), style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
        ],
        if (!r.text('$base.home_storage.tip').isEmpty) ...[
          const SizedBox(height: 6),
          Text(r.text('$base.home_storage.tip').of(lang), style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
        ],
        if (keepLonger.isNotEmpty) ...[
          const SizedBox(height: 12),
          label(s.keepLonger, icon: 'detail.keep_longer'),
          const SizedBox(height: 2),
          Text(keepLonger, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
        ],
        if (keepAway.isNotEmpty) ...[
          const SizedBox(height: 12),
          label(s.keepAwayFrom, field: '$base.ethylene_compatibility.keep_away_from', icon: 'detail.keep_away_from'),
          Text(keepAway.join(', '), style: theme.textTheme.bodyMedium),
        ],
        if (room.isNotEmpty || fridge.isNotEmpty || freezer.isNotEmpty || mode == 'until_ripe') ...[
          const SizedBox(height: 12),
          label(s.howLong, field: '$base.postharvest_physiology.estimated_shelf_life_days', icon: 'detail.how_long'),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (mode == 'until_ripe')
                _ShelfChip(
                  icon: 'storage.temperatura_ambiente',
                  title: s.roomTemp,
                  value: room.isEmpty ? s.untilRipe : '${s.untilRipe} + ${s.days(room)}',
                )
              else if (room.isNotEmpty)
                _ShelfChip(icon: 'storage.temperatura_ambiente', title: s.roomTemp, value: s.days(room)),
              if (fridge.isNotEmpty) _ShelfChip(icon: 'storage.frigorifero', title: s.fridge, value: s.days(fridge)),
              if (freezer.isNotEmpty) _ShelfChip(icon: 'storage.freezer', title: s.freezer, value: s.months(freezer)),
            ],
          ),
        ],
      ],
    );
  }
}

/// Callout tag (like "How Long It Keeps at Home"), for the storage location.
class _Callout extends StatelessWidget {
  const _Callout({required this.icon, required this.text});
  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SlotIcon(icon, size: 16, color: cs.onSecondaryContainer),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShelfChip extends StatelessWidget {
  const _ShelfChip({required this.icon, required this.title, required this.value});
  final String icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SlotIcon(icon, size: 16, color: cs.onSecondaryContainer),
          const SizedBox(width: 6),
          Text('$title · ', style: TextStyle(fontSize: 12, color: cs.onSecondaryContainer)),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.onSecondaryContainer),
          ),
        ],
      ),
    );
  }
}

/// "Climacteric / Non-climacteric" label with the glossary "?".
class RipeningTypeLabel extends StatelessWidget {
  const RipeningTypeLabel({super.key, required this.item, this.compact = false});
  final FoodItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final db = context.read<FoodDatabase>();
    final lang = context.select<SettingsController, AppLanguage>((s) => s.language);
    if (item.ripeningType == null) return const SizedBox.shrink();
    final label = db.vocab('ripening_and_storage.ripening_type', item.ripeningType).of(lang);
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.only(left: compact ? 8 : 10, right: 0),
      decoration: BoxDecoration(color: cs.tertiaryContainer, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SlotIcon('storage.ripening_type', size: compact ? 13 : 15, color: cs.onTertiaryContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: (compact ? Theme.of(context).textTheme.labelSmall : Theme.of(context).textTheme.labelMedium)
                ?.copyWith(color: cs.onTertiaryContainer),
          ),
          HelpButton(
            ids: [item.ripeningType == 'climaterico' ? 'climacteric' : 'non_climacteric'],
            size: compact ? 14 : 16,
          ),
        ],
      ),
    );
  }
}
