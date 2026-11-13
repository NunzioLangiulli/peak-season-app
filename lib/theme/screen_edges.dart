import 'package:flutter/material.dart';

/// Space to leave at the bottom of a scrolling page so the last card is
/// never cut by the rounded corners of the phone screen: the system inset
/// (gesture bar / buttons) plus a margin larger than typical corner radii.
double safeBottomPadding(BuildContext context, {double extra = 48}) =>
    MediaQuery.viewPaddingOf(context).bottom + extra;

/// Soft fade of the content at the bottom edge of the screen: whatever
/// scrolls under the rounded screen corners fades out instead of being
/// visibly clipped. Works on any screen shape.
class BottomEdgeFade extends StatelessWidget {
  const BottomEdgeFade({super.key, required this.child, this.height = 36});
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) => ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) {
          final stop = rect.height <= 0 ? 1.0 : (1 - height / rect.height).clamp(0.0, 1.0);
          return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [Colors.black, Colors.black, Colors.transparent],
            stops: [0, stop, 1],
          ).createShader(rect);
        },
        child: child,
      );
}
