import 'package:flutter/material.dart';

import '../theme/icon_service.dart';
import 'help_button.dart';

/// Subheading of a detail block: icon, text, optional "?" and optional tag.
///
/// Everything is one rich text, so when the text wraps the "?" stays right
/// after the last word (not floating in the middle of the row), and the tag
/// ("Ripening: Climacteric") follows on the same line when it fits.
class SubHeading extends StatelessWidget {
  const SubHeading(
    this.text, {
    super.key,
    required this.icon,
    this.field,
    this.helpIds = const [],
    this.trailing,
    this.padding = const EdgeInsets.only(top: 10, bottom: 2),
  });

  final String text;

  /// Icon slot in front of the text (IconService).
  final String icon;
  final String? field;
  final List<String> helpIds;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: padding,
      child: Text.rich(
        TextSpan(children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: SlotIcon(icon, size: 18, color: cs.primary),
            ),
          ),
          TextSpan(text: trailing == null ? text : '$text:'),
          if (field != null || helpIds.isNotEmpty)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: HelpButton(field: field, ids: helpIds, size: 16),
            ),
          if (trailing != null)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(padding: const EdgeInsets.only(left: 6, top: 2, bottom: 2), child: trailing),
            ),
        ]),
        style: theme.textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}

/// Text followed by the "?" right after its last word, also when it wraps.
class TextWithHelp extends StatelessWidget {
  const TextWithHelp(this.text, {super.key, this.style, this.field, this.helpIds = const [], this.helpSize = 16});

  final String text;
  final TextStyle? style;
  final String? field;
  final List<String> helpIds;
  final double helpSize;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(children: [
          TextSpan(text: text),
          if (field != null || helpIds.isNotEmpty)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: HelpButton(field: field, ids: helpIds, size: helpSize),
            ),
        ]),
        style: style,
      );
}

/// Body paragraph of a detail block (empty text = nothing).
class Para extends StatelessWidget {
  const Para(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => text.isEmpty
      ? const SizedBox.shrink()
      : Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4));
}
