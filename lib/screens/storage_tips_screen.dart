import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/food_repository.dart';
import '../l10n/strings.dart';
import '../models/food_item.dart';
import '../models/glossary.dart';
import '../providers/library_controller.dart';
import '../providers/settings_controller.dart';
import '../widgets/food_actions.dart';
import '../widgets/food_image.dart';
import '../widgets/help_button.dart';
import '../widgets/storage_summary.dart';
import '../theme/icon_service.dart';

/// Conflitti di etilene tra gli alimenti dati: per ogni alimento che fa
/// danni (produttore), quelli della spesa da tenergli lontani. Regola del
/// database (`metadata.ethylene_rules`): coppia A-B solo se B è in
/// `keep_away_from` di A (produttori forti), non da `produces_ethylene` da solo.
/// Ordinato per numero di alimenti coinvolti.
List<({FoodItem producer, List<FoodItem> sensitive})> ethyleneConflicts(List<FoodItem> items) {
  const base = 'ripening_and_storage.ethylene_compatibility';
  final map = <String, Set<FoodItem>>{};
  final byId = {for (final i in items) i.id: i};
  for (final a in items) {
    final away = a.raw.list('$base.keep_away_from').map((e) => '$e').toSet();
    for (final b in items) {
      if (a.id == b.id) continue;
      if (away.contains(b.id)) {
        (map[b.id] ??= {}).add(a);
      }
    }
  }
  final out = [
    for (final e in map.entries) (producer: byId[e.key]!, sensitive: e.value.toList()),
  ]..sort((x, y) => y.sensitive.length.compareTo(x.sensitive.length));
  return out;
}

/// "Come Conservarli" — sono tornato a casa con le buste: dove metto ogni
/// cosa? Si apre dalla Lista della Spesa o dalla notifica dopo la spesa.
class StorageTipsScreen extends StatefulWidget {
  const StorageTipsScreen({super.key});

  @override
  State<StorageTipsScreen> createState() => _StorageTipsScreenState();
}

class _StorageTipsScreenState extends State<StorageTipsScreen> {
  String _query = '';

  static const _groups = ['frigorifero', 'temperatura_ambiente', 'luogo_fresco_buio'];

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final db = context.read<FoodDatabase>();
    final lang = context.watch<SettingsController>().language;
    final listIds = context.watch<LibraryController>().shoppingListIds.where(db.byId.containsKey).toList();
    final listItems = [for (final id in listIds) db.byId[id]!];
    final theme = Theme.of(context);
    final q = normalizeForSearch(_query);
    final others = q.isEmpty
        ? const <FoodItem>[]
        : (db.items.where((i) => !listIds.contains(i.id) && i.matches(q)).toList()
          ..sort((a, b) => a.name.of(lang).compareTo(b.name.of(lang))));
    final conflicts = ethyleneConflicts(listItems);

    return Scaffold(
      appBar: AppBar(title: Text(s.storageTipsTitle), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Text(s.storageGuideIntro, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          if (listItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(s.storageTipsEmptyList, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            ),
          // --- 1. Incompatibilità di etilene nella spesa ---------------------
          if (conflicts.isNotEmpty) ...[
            const SizedBox(height: 14),
            _EthyleneAlert(conflicts: conflicts),
          ],
          // --- 2. Smistamento per luogo ----------------------------------------
          for (final loc in _groups)
            if (listItems.any((i) => i.primaryLocation == loc)) ...[
              _GroupHeader(location: loc, count: listItems.where((i) => i.primaryLocation == loc).length),
              for (final item in listItems.where((i) => i.primaryLocation == loc))
                _TipCard(item: item, initiallyExpanded: true),
            ],
          // --- 3. Tutto il database ----------------------------------------------
          const SizedBox(height: 20),
          Text(s.storageSearchAll, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(s.storageSearchAllSub, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 10),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: s.storageTipsSearch,
              prefixIcon: const SlotIcon('home.search'),
              filled: true,
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          for (final item in others.take(20)) _TipCard(item: item, initiallyExpanded: others.length == 1, showGroup: true),
        ],
      ),
    );
  }
}

class _EthyleneAlert extends StatelessWidget {
  const _EthyleneAlert({required this.conflicts});
  final List<({FoodItem producer, List<FoodItem> sensitive})> conflicts;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = context.watch<SettingsController>().language;
    final theme = Theme.of(context);
    const amber = Color(0xFFFFB300);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 14),
      decoration: BoxDecoration(
        color: amber.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: amber.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SlotIcon('storage.ethylene_alert', color: Color(0xFFB27C00)),
              const SizedBox(width: 8),
              Expanded(child: Text(s.ethyleneAlertTitle, style: theme.textTheme.titleSmall)),
              const HelpButton(ids: ['ethylene', 'keep_away_from'], size: 18),
            ],
          ),
          const SizedBox(height: 4),
          Text(s.ethyleneAlertIntro, style: theme.textTheme.bodySmall),
          for (final c in conflicts)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: c.producer.name.of(lang), style: const TextStyle(fontWeight: FontWeight.w800)),
                  TextSpan(text: ' ${s.ethyleneReleases} '),
                  TextSpan(
                    text: c.sensitive.map((i) => i.name.of(lang)).join(', '),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ]),
                style: theme.textTheme.bodyMedium,
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.location, required this.count});
  final String location;
  final int count;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
      child: Row(
        children: [
          SlotIcon(storageSlot(location), color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text('${s.storageGroup(location)} ($count)', style: theme.textTheme.titleMedium)),
          const HelpButton(field: 'ripening_and_storage.home_storage', size: 18),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.item, this.initiallyExpanded = false, this.showGroup = false});
  final FoodItem item;
  final bool initiallyExpanded;
  final bool showGroup;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = context.watch<SettingsController>().language;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final r = item.raw;
    const base = 'ripening_and_storage';
    final loc = item.primaryLocation;
    final tMin = r.number('$base.postharvest_physiology.optimal_temperature_c.min');
    final tMax = r.number('$base.postharvest_physiology.optimal_temperature_c.max');
    final chill = r.at('$base.postharvest_physiology.chilling_injury.susceptible') == true;
    final chillTemp = r.number('$base.postharvest_physiology.chilling_injury.critical_temperature_c');
    final speedUp = r.text('$base.ripening_management.speed_up').of(lang);
    final slowDown = r.text('$base.ripening_management.slow_down').of(lang);

    String fmt(num v) => v % 1 == 0 ? '${v.round()}' : '$v';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.fromLTRB(10, 4, 12, 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(width: 48, height: 48, child: FoodImage(item: item)),
          ),
          title: Text(item.name.of(lang), style: theme.textTheme.titleMedium),
          subtitle: Text(
            showGroup ? '${s.storageGroup(loc)} · ${item.cardShortStorage.of(lang)}' : item.cardShortStorage.of(lang),
            style: theme.textTheme.bodySmall,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (loc == 'frigorifero' && tMin != null && tMax != null)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: SlotIcon('storage.ideal_temperature', size: 16, color: cs.primary),
                    label: Text(s.idealTemp('${fmt(tMin)}-${fmt(tMax)}')),
                  ),
                RipeningTypeLabel(item: item, compact: true),
              ],
            ),
            if (loc == 'temperatura_ambiente' && chill) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SlotIcon('storage.chilling_injury', size: 18, color: Color(0xFF1E88E5)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${s.chillingAlert(chillTemp == null ? null : fmt(chillTemp))} '
                        '${r.text('$base.postharvest_physiology.chilling_injury.symptoms').of(lang)}',
                        style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                      ),
                    ),
                    const HelpButton(ids: ['chilling_injury'], size: 16),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            StorageSummary(item: item, showWhere: showGroup),
            if (loc != 'luogo_fresco_buio') ...[
              if (loc == 'temperatura_ambiente' && speedUp.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(s.ripeningSpeedUp, style: theme.textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
                Text(speedUp, style: theme.textTheme.bodyMedium),
              ],
              if (slowDown.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(s.ripeningSlowDown, style: theme.textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
                Text(slowDown, style: theme.textTheme.bodyMedium),
              ],
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => FoodNavigation.openDetail(context, item),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text(s.openFullSheet),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
