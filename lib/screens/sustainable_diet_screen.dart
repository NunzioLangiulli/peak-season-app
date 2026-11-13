import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/food_repository.dart';
import '../l10n/strings.dart';
import '../providers/settings_controller.dart';
import '../theme/screen_edges.dart';

/// Pagina informativa "More Sustainable Diet" (testo EUFIC dal database).
class SustainableDietScreen extends StatelessWidget {
  const SustainableDietScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lang = context.watch<SettingsController>().language;
    final diet = context.read<FoodDatabase>().sustainableDiet;
    final theme = Theme.of(context);
    final points = diet.keyPoints[lang] ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(s.sustainableDiet)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 8, 20, safeBottomPadding(context)),
        children: [
          Text(diet.text.of(lang), style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
          if (points.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(s.keyPoints, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final p in points)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(Icons.eco_rounded, size: 18, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(p, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
          ],
          if (diet.sourceUrl != null) ...[
            const SizedBox(height: 24),
            SelectableText(
              '${s.source}: ${diet.sourceUrl}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
