import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../providers/detail_layout_controller.dart';
import '../theme/screen_edges.dart';

/// Settings → Product Page Sections: order (by dragging) and
/// mode of each block (Open / Collapsed / Hidden).
class DetailSectionsScreen extends StatelessWidget {
  const DetailSectionsScreen({super.key});

  static IconData _modeIcon(SectionMode m) => switch (m) {
        SectionMode.open => Icons.unfold_more_rounded,
        SectionMode.collapsed => Icons.unfold_less_rounded,
        SectionMode.hidden => Icons.visibility_off_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final layout = context.watch<DetailLayoutController>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.detailSections),
        actions: [TextButton(onPressed: layout.reset, child: Text(s.restoreDefaults))],
      ),
      body: ReorderableListView.builder(
        padding: EdgeInsets.fromLTRB(16, 0, 16, safeBottomPadding(context)),
        header: Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Text('${s.detailSectionsSub}\n${s.detailSectionsHint}',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ),
        itemCount: layout.order.length,
        onReorderItem: layout.moveItem,
        // the drag handle is already on the left of each row
        buildDefaultDragHandles: false,
        itemBuilder: (context, i) {
          final section = layout.order[i];
          final mode = layout.modeOf(section);
          return Padding(
            key: ValueKey(section),
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 16, 12),
                child: Row(
                  children: [
                    ReorderableDragStartListener(
                      index: i,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.drag_indicator_rounded),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            s.sectionTitle(section),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: mode == SectionMode.hidden ? cs.onSurfaceVariant : null,
                              decoration: mode == SectionMode.hidden ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<SectionMode>(
                            expandedInsets: EdgeInsets.zero,
                            showSelectedIcon: false,
                            style: SegmentedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: theme.textTheme.labelMedium,
                            ),
                            segments: [
                              for (final m in SectionMode.values)
                                ButtonSegment(
                                  value: m,
                                  tooltip: s.sectionMode(m),
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_modeIcon(m), size: 14),
                                      const SizedBox(width: 4),
                                      Text(s.sectionMode(m), maxLines: 1, softWrap: false),
                                    ],
                                  ),
                                ),
                            ],
                            selected: {mode},
                            onSelectionChanged: (v) => layout.setMode(section, v.first),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
