import 'package:flutter/material.dart';

import '../theme/icon_service.dart';

/// Coloured tag used across the product information ("In Frigorifero",
/// "Climaterico", "Frigo · 7-14 gg", ethylene classes…): every tag of the
/// same [compact] size has the same height and the same padding between the
/// pill edge and the text; only the width follows the text.
class TagPill extends StatelessWidget {
  const TagPill({
    super.key,
    required this.text,
    this.icon,
    this.prefix,
    this.background,
    this.foreground,
    this.trailing,
    this.compact = false,
  });

  final String text;

  /// Icon slot (IconService) in front of the text.
  final String? icon;

  /// Lighter text before [text] ("Frigo · ").
  final String? prefix;
  final Color? background;
  final Color? foreground;

  /// Widget after the text, inside the pill (e.g. a "?").
  final Widget? trailing;

  /// Smaller version for the product cards.
  final bool compact;

  static const double height = 30;
  static const double compactHeight = 22;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = background ?? cs.secondaryContainer.withValues(alpha: 0.7);
    final fg = foreground ?? cs.onSecondaryContainer;
    final fontSize = compact ? 11.0 : 12.0;
    return Container(
      height: compact ? compactHeight : height,
      padding: EdgeInsets.only(left: compact ? 8 : 10, right: trailing == null ? (compact ? 8 : 10) : 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            SlotIcon(icon!, size: compact ? 13 : 16, color: fg),
            SizedBox(width: compact ? 4 : 6),
          ],
          Flexible(
            child: Text.rich(
              TextSpan(children: [
                if (prefix != null) TextSpan(text: prefix, style: const TextStyle(fontWeight: FontWeight.w400)),
                TextSpan(text: text),
              ]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, color: fg, height: 1.1),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
