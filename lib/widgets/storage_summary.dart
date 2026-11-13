import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/food_repository.dart';
import '../l10n/strings.dart';
import '../models/app_enums.dart';
import '../models/food_item.dart';
import '../models/glossary.dart';
import '../providers/settings_controller.dart';
import 'detail_parts.dart';
import 'help_button.dart';
import '../theme/icon_service.dart';

/// Where to store it, for how long, what to keep away from it: used on the
/// "How to store them" page and on the product page.
class StorageSummary extends StatelessWidget {
  const StorageSummary({super.key, required this.item, this.showInstructions = true, this.showWhere = true});

  final FoodItem item;
  final bool showInstructions;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showWhere) ...[
          SubHeading(
            s.whereToStore,
            padding: EdgeInsets.zero,
            field: '$base.home_storage',
            icon: 'detail.where_to_store',
            trailing: r.text('$base.home_storage.label').isEmpty
                ? null
                : _Callout(icon: storageSlot(item.primaryLocation), text: r.text('$base.home_storage.label').of(lang)),
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
        if (keepAway.isNotEmpty) ...[
          const SizedBox(height: 12),
          SubHeading(
            s.keepAwayFrom,
            padding: EdgeInsets.zero,
            field: '$base.ethylene_compatibility.keep_away_from',
            icon: 'detail.keep_away_from',
          ),
          Text(keepAway.join(', '), style: theme.textTheme.bodyMedium),
        ],
        if (room.isNotEmpty || fridge.isNotEmpty || freezer.isNotEmpty || mode == 'until_ripe') ...[
          const SizedBox(height: 12),
          SubHeading(
            s.howLong,
            padding: EdgeInsets.zero,
            field: '$base.postharvest_physiology.estimated_shelf_life_days',
            icon: 'detail.how_long',
          ),
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

/// Ripening + storage block, the same on the product page and on the
/// "How to Store Them" page: Ripening: tag, (climacteric only) how to ripen
/// it and how to slow it down, where to store it, keep away from, how long
/// it keeps, perishability.
class RipeningStorageBlock extends StatelessWidget {
  const RipeningStorageBlock({
    super.key,
    required this.item,
    this.showWhere = true,
    this.storageFirst = false,
    this.callout,
  });
  final FoodItem item;

  /// "How to Store Them" page: storage (where, how long, perishability) comes
  /// first, then ripening, separated by a divider as on the product page.
  final bool storageFirst;

  /// Optional warning box shown right after the storage part (e.g. the
  /// chilling-injury callout).
  final Widget? callout;

  /// false in the after-shopping guide, where the group already says where to put it.
  final bool showWhere;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = context.watch<SettingsController>().language;
    final r = item.raw;
    const base = 'ripening_and_storage';
    final speedUp = r.text('$base.ripening_management.speed_up').of(lang);
    final slowDown = r.text('$base.ripening_management.slow_down').of(lang);
    // metadata.detail_display_rules.ripening.non_climacteric: a
    // non-climacteric product does not ripen after harvest, so neither "To
    // Ripen It" nor "To Slow It Down" is shown (storage_instructions covers it).
    final climacteric = item.ripeningType == 'climaterico';
    final ripening = <Widget>[
      // The meaning (e.g. "does not ripen after harvest") is in the tag's "?".
      SubHeading(
        s.ripening,
        icon: 'detail.ripening',
        trailing: RipeningTypeLabel(item: item),
      ),
      if (climacteric) ...[
        if (speedUp.isNotEmpty) ...[
          SubHeading(s.ripeningSpeedUp, icon: 'detail.speed_up', field: '$base.ethylene_compatibility'),
          Para(speedUp),
        ],
        if (slowDown.isNotEmpty) ...[SubHeading(s.ripeningSlowDown, icon: 'detail.slow_down'), Para(slowDown)],
      ],
    ];
    final storage = <Widget>[
      StorageSummary(item: item, showWhere: showWhere),
      if (callout != null) ...[const SizedBox(height: 10), callout!],
      const SizedBox(height: 4),
      PerishabilityBox(item: item),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: storageFirst
          ? [...storage, const Divider(height: 28), ...ripening]
          : [...ripening, const Divider(height: 28), ...storage],
    );
  }
}

/// Perishability as a coloured box (like the footprint tiles): colour of the
/// level from metadata.perishability_legend.levels[].color_hex, a stepped
/// meter, the label and the tip.
class PerishabilityBox extends StatelessWidget {
  const PerishabilityBox({super.key, required this.item});
  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = context.watch<SettingsController>().language;
    final db = context.read<FoodDatabase>();
    final theme = Theme.of(context);
    final r = item.raw;
    const base = 'ripening_and_storage.perishability';
    final label = r.text('$base.label').of(lang);
    if (label.isEmpty) return const SizedBox.shrink();
    final levels = db.perishabilityLevelCount;
    final level = (r.number('$base.level') ?? 3).toInt().clamp(1, levels);
    final color = Color(db.perishabilityColor(level));
    final textColor = Color.lerp(color, theme.colorScheme.onSurface, 0.2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SubHeading(s.perishability, icon: 'detail.perishability', field: 'ripening_and_storage.perishability'),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(label, style: theme.textTheme.titleSmall?.copyWith(color: textColor)),
                  ),
                  // 1 = keeps for a long time … last = extremely perishable
                  for (var i = 1; i <= levels; i++)
                    Container(
                      width: 16,
                      height: 6,
                      margin: const EdgeInsets.only(left: 3),
                      decoration: BoxDecoration(
                        color: i <= level
                            ? Color(db.perishabilityColor(i))
                            : theme.colorScheme.onSurface.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
              if (r.text('$base.tip').of(lang).isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(r.text('$base.tip').of(lang), style: theme.textTheme.bodyMedium?.copyWith(height: 1.35)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
