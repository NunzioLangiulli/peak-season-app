import 'package:flutter/material.dart';

import '../models/season_state.dart';
import 'seasonality_three_dots.dart';

/// "o ⭐ o" logo: the season rising (early), the peak, the decline.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 26});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SeasonDot(state: SeasonState.primizie, size: size * 0.42),
          SizedBox(width: size * 0.12),
          SeasonDot(state: SeasonState.peakSeason, size: size, showIcon: true),
          SizedBox(width: size * 0.12),
          SeasonDot(state: SeasonState.endOfSeason, size: size * 0.42),
        ],
      ),
    );
  }
}
