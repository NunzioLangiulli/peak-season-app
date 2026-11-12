import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Link esterno: apre il browser del telefono (l'app resta offline, i link
/// servono solo a chi vuole approfondire sulle fonti).
class LinkText extends StatelessWidget {
  const LinkText({super.key, required this.label, this.url, this.style});

  final String label;
  final String? url;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = style ?? Theme.of(context).textTheme.bodySmall;
    if (url == null) return Text(label, style: base);
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url!), mode: LaunchMode.externalApplication),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: base?.copyWith(color: cs.primary, decoration: TextDecoration.underline),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.open_in_new_rounded, size: 14, color: cs.primary),
        ],
      ),
    );
  }
}
