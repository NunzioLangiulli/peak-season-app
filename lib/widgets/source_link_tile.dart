import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'source_badge.dart';

/// Riga di un link a una fonte, uguale in tutta l'app: logo della fonte,
/// titolo in grassetto, editore in grigio sotto, icona "apri" a destra.
/// Usata in "Fonti e Link Utili" della scheda e nelle spiegazioni "?".
class SourceLinkTile extends StatelessWidget {
  const SourceLinkTile({
    super.key,
    required this.title,
    this.subtitle = '',
    this.url,
    this.sourceKey,
    this.favicon,
    this.badgeSize = 36,
  });

  final String title;
  final String subtitle;
  final String? url;

  /// Chiave della fonte (`official_sources[].key`).
  final String? sourceKey;

  /// File del logo in `assets/sources/` indicato dal database (può essere
  /// quello di un'altra fonte della stessa organizzazione).
  final String? favicon;
  final double badgeSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: url == null ? null : () => launchUrl(Uri.parse(url!), mode: LaunchMode.externalApplication),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SourceBadge(sourceKey: sourceKey, favicon: favicon, size: badgeSize),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            if (url != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.open_in_new_rounded, size: 18, color: cs.onSurfaceVariant),
            ],
          ],
        ),
      ),
    );
  }
}
