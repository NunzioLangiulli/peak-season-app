import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/settings_controller.dart';
import '../theme/icon_service.dart';

class PillNavItem {
  const PillNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount = 0,
  });

  /// IconService slot (the same icon, selected or not).
  final String icon;
  final String selectedIcon;
  final String label;
  final int badgeCount;
}

/// Floating pill navigation bar, with a blurred background.
class PillNavBar extends StatelessWidget {
  const PillNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const height = 64.0;
  static const bottomMargin = 12.0;

  /// Space to leave at the bottom of lists so the bar does not cover
  /// the last item.
  static double overlap(BuildContext context) =>
      height + bottomMargin + MediaQuery.paddingOf(context).bottom + 12;

  final List<PillNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final frost = context.select<SettingsController, double>((s) => s.frost);
    return SafeArea(
      minimum: const EdgeInsets.only(bottom: bottomMargin),
      child: Center(
        heightFactor: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6 + 22 * frost, sigmaY: 6 + 22 * frost),
            child: Container(
              height: height,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: dark
                    ? Colors.white.withValues(alpha: 0.13 - 0.07 * frost)
                    : Colors.white.withValues(alpha: 0.9 - 0.4 * frost),
                borderRadius: BorderRadius.circular(height / 2),
                border: Border.all(color: dark ? Colors.white.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.9)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < items.length; i++)
                    _PillItem(
                      item: items[i],
                      selected: i == selectedIndex,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onSelected(i);
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillItem extends StatelessWidget {
  const _PillItem({required this.item, required this.selected, required this.onTap});

  final PillNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = selected ? cs.onPrimary : cs.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          height: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: selected ? 18 : 16),
          decoration: BoxDecoration(
            color: selected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                isLabelVisible: item.badgeCount > 0,
                label: Text('${item.badgeCount}'),
                child: SlotIcon(selected ? item.selectedIcon : item.icon, color: fg, size: 22),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          item.label,
                          style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
