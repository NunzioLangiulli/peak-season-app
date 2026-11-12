import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../providers/home_controller.dart';

/// Barra dei mesi a scorrimento circolare (dopo dicembre torna gennaio).
///
/// - Il mese selezionato è sempre al centro, dentro la pillola.
/// - Si vede un numero dispari di mesi interi (5 sul telefono, 7 sugli
///   schermi larghi): lo scorrimento si ferma sempre su un mese, quindi i
///   mesi agli estremi non risultano mai tagliati.
/// - Scorrendo si cambia mese; toccando un mese laterale ci si sposta lì.
/// - Il mese reale ha un puntino sotto.
class MonthSelector extends StatefulWidget {
  const MonthSelector({super.key});

  @override
  State<MonthSelector> createState() => _MonthSelectorState();
}

class _MonthSelectorState extends State<MonthSelector> {
  /// Pagina di partenza lontana dagli estremi: lo scorrimento è "infinito".
  static const _loops = 1000;
  PageController? _controller;
  int _visible = 5;
  bool _programmatic = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  int _pageFor(int month, {int? near}) {
    final base = near ?? (_loops ~/ 2) * 12;
    final start = base - base % 12;
    var best = start + month;
    for (final p in [start + month - 12, start + month + 12]) {
      if ((p - base).abs() < (best - base).abs()) best = p;
    }
    return best;
  }

  void _ensureController(int visible, int month) {
    if (_controller != null && visible == _visible) return;
    _visible = visible;
    final old = _controller;
    _controller = PageController(
      viewportFraction: 1 / visible,
      initialPage: _pageFor(month),
    );
    if (old != null) WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  Future<void> _goTo(int month) async {
    final c = _controller;
    if (c == null || !c.hasClients) return;
    final current = c.page?.round() ?? c.initialPage;
    if (current % 12 == month) return;
    _programmatic = true;
    await c.animateToPage(
      _pageFor(month, near: current),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
    _programmatic = false;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final home = context.watch<HomeController>();
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(builder: (context, box) {
        final visible = box.maxWidth >= 560 ? 7 : 5;
        _ensureController(visible, home.month);
        // Il mese può cambiare da fuori (titolo, calendario, notifica).
        WidgetsBinding.instance.addPostFrameCallback((_) => _goTo(home.month));
        final itemWidth = box.maxWidth / visible;

        return Container(
          height: 46,
          decoration: BoxDecoration(
            color: dark ? Colors.white.withValues(alpha: 0.08) : cs.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(23),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pillola fissa al centro: i mesi le scorrono sotto.
                Container(
                  width: itemWidth - 6,
                  height: 36,
                  decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(18)),
                ),
                PageView.builder(
                  controller: _controller,
                  padEnds: true,
                  onPageChanged: (p) {
                    if (_programmatic) return;
                    HapticFeedback.selectionClick();
                    home.setMonth(p % 12);
                  },
                  itemBuilder: (context, page) {
                    final m = page % 12;
                    final selected = m == home.month;
                    final isNow = m == home.currentMonth;
                    return Semantics(
                      button: true,
                      selected: selected,
                      label: s.monthName(m),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _programmatic = true;
                          home.setMonth(m);
                          _controller!
                              .animateToPage(page,
                                  duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic)
                              .whenComplete(() => _programmatic = false);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: 13,
                                letterSpacing: 0.6,
                                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                                color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                              ),
                              child: Text(s.monthShort(m)),
                            ),
                            if (isNow)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: selected ? cs.onPrimary : cs.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
