import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/food_repository.dart';
import '../l10n/strings.dart';
import '../providers/home_controller.dart';
import '../providers/settings_controller.dart';
import '../widgets/food_cards.dart';
import '../widgets/help_button.dart';

/// Tutti gli alimenti della stessa famiglia botanica (es. Solanaceae),
/// ordinati per stagionalità nel mese selezionato.
class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key, required this.family});
  final String family;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final db = context.read<FoodDatabase>();
    final settings = context.watch<SettingsController>();
    final month = context.select<HomeController, int>((h) => h.month);
    final resolver = settings.resolver;
    final entries = [
      for (final i in db.items)
        if (i.family == family) FoodEntry(i, resolver.resolve(i)),
    ];
    HomeController.sortBySeason(entries, month, settings.language);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          children: [
            Text(db.familyName(family).of(settings.language)),
            // nome scientifico sotto, in corsivo
            Text(family,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                )),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    s.familyCount(entries.length, s.monthName(month)),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                const HelpButton(ids: ['scientific_name'], size: 16),
              ],
            ),
          ),
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FoodListCard(key: ValueKey(e.item.id), entry: e),
            ),
        ],
      ),
    );
  }
}
