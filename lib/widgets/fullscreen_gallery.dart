import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/food_item.dart';
import 'food_image.dart';

/// Galleria a schermo intero della scheda prodotto: pinch-to-zoom su ogni
/// foto e scorrimento circolare (dopo l'ultima torna la prima, e viceversa).
class FullscreenGallery extends StatefulWidget {
  const FullscreenGallery({super.key, required this.item, this.initialIndex = 0});

  final FoodItem item;
  final int initialIndex;

  static Future<void> show(BuildContext context, FoodItem item, {int initialIndex = 0}) =>
      Navigator.of(context).push(PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, _, _) => FullscreenGallery(item: item, initialIndex: initialIndex),
        transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      ));

  @override
  State<FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<FullscreenGallery> {
  /// Pagina di partenza lontana dagli estremi: lo scorrimento è "infinito".
  static const _loops = 1000;
  late final int _n = widget.item.gallery.length;
  late final PageController _page = PageController(initialPage: _n * (_loops ~/ 2) + widget.initialIndex);
  late int _index = widget.initialIndex;
  final _zoom = TransformationController();
  bool _zoomed = false;

  @override
  void dispose() {
    _page.dispose();
    _zoom.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _zoom.value = Matrix4.identity();
    if (_zoomed) setState(() => _zoomed = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final gallery = widget.item.gallery;
    final credit = widget.item.imageCredits[gallery[_index]];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _page,
            // con la foto ingrandita il dito sposta la foto, non la pagina
            physics: _zoomed ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
            itemCount: _n == 1 ? 1 : null,
            onPageChanged: (p) {
              _resetZoom();
              setState(() => _index = p % _n);
            },
            itemBuilder: (_, p) {
              final i = p % _n;
              return InteractiveViewer(
                transformationController: i == _index ? _zoom : null,
                minScale: 1,
                maxScale: 5,
                onInteractionEnd: (_) {
                  final z = _zoom.value.getMaxScaleOnAxis() > 1.02;
                  if (z != _zoomed) setState(() => _zoomed = z);
                },
                child: GestureDetector(
                  // doppio tocco: torna alla foto intera
                  onDoubleTap: _resetZoom,
                  child: Center(
                    child: FoodImage(item: widget.item, file: gallery[i], full: true, fit: BoxFit.contain),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                child: IconButton(
                  tooltip: s.close,
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_n > 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < _n; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: i == _index ? 18 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: i == _index ? 0.95 : 0.45),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                        ],
                      ),
                    if (credit != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '© ${credit.author} · ${credit.license}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
