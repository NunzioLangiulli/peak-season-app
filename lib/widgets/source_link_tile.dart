import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'source_badge.dart';

/// Row of a link to a source, the same throughout the app: source logo,
/// title in bold, publisher in grey underneath, "open" icon on the right.
/// Used in the product page's "Sources and Useful Links" and in the "?" explanations.
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

  /// Source key (`official_sources[].key`).
  final String? sourceKey;

  /// Logo file in `assets/sources/` given by the database (it may be
  /// that of another source from the same organisation).
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
