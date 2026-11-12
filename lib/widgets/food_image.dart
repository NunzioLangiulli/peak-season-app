import 'package:flutter/material.dart';

import '../data/food_repository.dart';
import '../models/app_enums.dart';
import '../models/food_item.dart';
import '../theme/icon_service.dart';

/// Immagine dell'alimento da asset offline, con segnaposto per i 13 alimenti
/// ancora senza foto (e per eventuali file mancanti).
class FoodImage extends StatelessWidget {
  const FoodImage({
    super.key,
    required this.item,
    this.file,
    this.full = false,
    this.fit = BoxFit.cover,
  });

  final FoodItem item;

  /// File specifico della galleria; default = immagine principale.
  final String? file;

  /// true = versione 1080 px (galleria), false = miniatura 600 px.
  final bool full;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final f = file ?? item.primaryImage;
    if (f == null) return FoodImagePlaceholder(category: item.category);
    return Image.asset(
      full ? AssetPaths.full(f) : AssetPaths.thumb(f),
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => FoodImagePlaceholder(category: item.category),
      frameBuilder: (context, child, frame, sync) {
        if (sync) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 250),
          child: child,
        );
      },
    );
  }
}

class FoodImagePlaceholder extends StatelessWidget {
  const FoodImagePlaceholder({super.key, required this.category});
  final FoodCategory category;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.secondaryContainer.withValues(alpha: 0.6),
      alignment: Alignment.center,
      child: SlotIcon('category.${category.code}', size: 40, color: cs.onSecondaryContainer.withValues(alpha: 0.5)),
    );
  }
}
