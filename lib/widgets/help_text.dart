import 'package:material_ui/material_ui.dart';

/// Text of a help entry: blank lines separate paragraphs, and lines that
/// start with "• ", "- " or "– " are drawn as bullet rows with a hanging
/// indent, so lists in the "?" explanations are easy to read.
class HelpText extends StatelessWidget {
  const HelpText(this.text, {super.key});
  final String text;

  static final _bullet = RegExp(r'^\s*[•\-–]\s+');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(height: 1.45);
    final rows = <Widget>[];
    var afterBullet = false;
    for (final raw in text.split('\n')) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        rows.add(const SizedBox(height: 8));
        afterBullet = false;
        continue;
      }
      final m = _bullet.firstMatch(line);
      if (m == null) {
        // a paragraph right after a list gets a little air
        if (afterBullet) rows.add(const SizedBox(height: 6));
        afterBullet = false;
        rows.add(Text(line, style: style));
        continue;
      }
      afterBullet = true;
      rows.add(Padding(
        padding: const EdgeInsets.only(top: 3, left: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 10),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
              ),
            ),
            Expanded(child: Text(line.substring(m.end), style: style)),
          ],
        ),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}
