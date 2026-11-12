import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'material_icon_names.dart';

/// Mappa delle icone dell'app: `assets/data/ui_config.json` (copia di
/// `data/ui_config.json`, che l'utente modifica con l'Admin Studio, scheda
/// Icone). Ogni "slot" (es. `nav.home`, `storage.frigorifero`) indica quale
/// icona usare:
///   `svg:<cartella>/<nome>` → `assets/icons/<cartella>/<nome>.svg`
///   `material:<nome>`       → icona Material Rounded (vedi [materialIconNames])
/// I nomi degli slot sono un'API stabile come le chiavi di ui_copy.json.
/// Se uno slot manca nel file vale il default qui sotto; se l'icona scelta
/// non esiste si vede quella di riserva (punto interrogativo).
class IconService {
  IconService._();

  static const asset = 'assets/data/ui_config.json';

  static Map<String, String> _slots = const {};
  static bool get isLoaded => _slots.isNotEmpty;

  static Future<void> load({AssetBundle? bundle}) async {
    if (isLoaded) return;
    try {
      loadFromString(await (bundle ?? rootBundle).loadString(asset));
    } catch (e) {
      if (kDebugMode) debugPrint('IconService: $e (uso le icone predefinite)');
    }
  }

  static void loadFromString(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _slots = {
      for (final e in (json['icon_slots'] as List? ?? const []))
        if (e is Map && e['slot'] is String && e['icon'] is String) e['slot'] as String: e['icon'] as String,
    };
  }

  /// Riferimento dell'icona di uno slot (`svg:...` / `material:...`).
  static String ref(String slot) => _slots[slot] ?? defaults[slot] ?? 'material:help';

  /// Slot letti dal file (per i test).
  static Map<String, String> get loaded => _slots;

  /// Icona predefinita di ogni slot usato dall'app: le stesse in
  /// data/ui_config.json al momento della creazione.
  static const defaults = <String, String>{
    // --- Database (scritte anche nel database da build_app_support_metadata.py)
    'seasonality.state.primizie': 'svg:season/primizie',
    'seasonality.state.in_season': 'svg:season/in_season',
    'seasonality.state.peak_season': 'svg:season/peak_season',
    'seasonality.state.end_of_season': 'svg:season/end_of_season',
    'seasonality.state.out_of_season': 'material:remove',
    'seasonality.state.not_applicable': 'material:public',
    'seasonality.estimates.not_grown': 'material:public',
    'seasonality.estimates.unknown': 'material:question_mark',
    'category.verdura': 'material:grass',
    'category.frutta': 'svg:season/apple',
    'category.erbe_spezie': 'material:local_florist',
    'category.funghi': 'material:forest',
    'category.cereali': 'material:grain',
    'zone.mediterranean': 'svg:zones/palm_tree',
    'zone.continental': 'svg:zones/leaf',
    'zone.atlantic': 'svg:zones/water_drop',
    'zone.boreal': 'svg:zones/fir_tree',
    'zone.mountain': 'svg:zones/mountain',
    'zone.pannonian': 'svg:zones/wheat',
    // --- App
    'nav.home': 'material:eco',
    'nav.shopping': 'material:checklist',
    'nav.settings': 'material:settings',
    'storage.frigorifero': 'svg:ui/fridge',
    'storage.temperatura_ambiente': 'svg:ui/room_temp',
    'storage.dispensa': 'svg:ui/pantry',
    'storage.freezer': 'svg:ui/chilling',
    'storage.ripening_type': 'svg:ui/ripening',
    'storage.ethylene_alert': 'svg:ui/ethylene',
    'storage.chilling_injury': 'svg:ui/chilling',
    'storage.ideal_temperature': 'material:thermostat',
    'home.shopping_mode': 'svg:ui/shopping_mode',
    'home.advanced_filters': 'material:tune',
    'home.search': 'material:search',
    'home.no_results': 'material:search_off',
    'home.hidden_visible': 'material:visibility',
    'home.view.grid': 'material:grid_view',
    'home.view.list': 'material:view_agenda',
    'home.view.calendar': 'material:calendar_view_month',
    'action.shopping_list.add': 'material:playlist_add',
    'action.shopping_list.active': 'material:playlist_add_check',
    'action.favorite.add': 'material:favorite_border',
    'action.favorite.active': 'material:favorite',
    'action.dislike.add': 'material:do_not_disturb_on',
    'action.dislike.active': 'material:do_not_disturb_on',
    'action.open_detail': 'material:open_in_full',
    'filters.dop_only': 'svg:ui/dop_igp',
    'filters.show_hidden': 'material:visibility',
    'detail.section.calendar': 'svg:ui/calendar',
    'detail.section.varieties': 'svg:ui/varieties',
    'detail.section.buy_store': 'material:shopping_basket',
    'detail.section.nutrition': 'svg:ui/nutrition',
    'detail.section.sustainability': 'svg:ui/sustainability',
    'detail.section.garden': 'svg:ui/garden',
    'detail.section.curiosities': 'svg:ui/info',
    'detail.section.recipes': 'svg:ui/recipes',
    'detail.section.links': 'material:link',
    'detail.availability_note': 'material:info',
    'detail.dop_igp': 'svg:ui/dop_igp',
    'detail.carbon_footprint': 'svg:ui/carbon',
    'detail.water_footprint': 'svg:ui/water',
    'detail.beef_comparison': 'svg:ui/cow',
    'detail.zero_waste': 'svg:ui/zero_waste',
    'shopping.done_shopping': 'svg:ui/fridge',
    'shopping.how_to_choose': 'svg:ui/choose',
    'shopping.weight_calculator': 'svg:ui/scale',
    'shopping.add_item': 'material:add_circle',
    'shopping.in_cart': 'material:shopping_cart_checkout',
    'shopping.clear_completed': 'material:playlist_remove',
    'shopping.clear_list': 'material:delete_sweep',
    'settings.notifications': 'svg:ui/notifications',
    'settings.shopping_mode': 'svg:ui/shopping_mode',
    'settings.theme.light': 'material:light_mode',
    'settings.theme.dark': 'material:dark_mode',
    'settings.theme.system': 'material:brightness_auto',
    'settings.detail_sections': 'material:view_agenda',
    'settings.sustainable_diet': 'material:eco',
    'settings.database': 'material:storage',
    'home.category_other': 'material:local_florist',
    'home.list_card_how_to_choose': 'svg:ui/choose',
    'detail.how_to_choose': 'svg:ui/choose',
    'detail.keep_longer': 'material:timer',
    'sources.law': 'material:gavel',
    'sources.generic': 'material:link',
    'detail.ripening': 'svg:ui/ripening',
    'detail.speed_up': 'svg:ui/speed_up',
    'detail.slow_down': 'material:timer',
    'detail.perishability': 'svg:ui/perishability',
    'detail.where_to_store': 'material:inventory_2',
    'detail.how_long': 'material:schedule',
    'detail.keep_away_from': 'svg:ui/ethylene',
    'detail.notable_varieties': 'material:label',
    'detail.pat': 'svg:ui/pat',
    'detail.nutrition_claims': 'material:verified',
    'detail.vitamins_minerals': 'material:science',
    'detail.curiosities': 'material:tips_and_updates',
  };
}

/// Slot dell'icona di dove conservare un prodotto
/// (`ripening_and_storage.primary_location`).
String storageSlot(String? location) => switch (location) {
      'frigorifero' => 'storage.frigorifero',
      'temperatura_ambiente' => 'storage.temperatura_ambiente',
      _ => 'storage.dispensa',
    };

/// Icona di uno slot di [IconService].
class SlotIcon extends StatelessWidget {
  const SlotIcon(this.slot, {super.key, this.size, this.color});

  final String slot;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) => RefIcon(IconService.ref(slot), size: size, color: color);
}

/// Disegna un riferimento `svg:<cartella>/<nome>` o `material:<nome>`.
///
/// Le icone di `ui/` usano `currentColor` (restano le due tonalità di verde e
/// il logo DOP/IGP mantiene i suoi colori); quelle di `season/` e `zones/`
/// sono monocromatiche e vengono ricolorate con un filtro.
class RefIcon extends StatelessWidget {
  const RefIcon(this.ref, {super.key, this.size, this.color});

  final String ref;
  final double? size;
  final Color? color;

  static Widget _fallback(double size, Color? color) =>
      Icon(Icons.help_outline_rounded, size: size, color: color);

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;
    final size = this.size ?? IconTheme.of(context).size ?? 24;
    if (ref.startsWith('material:')) {
      final data = materialIconNames[ref.substring(9)];
      if (data == null) {
        if (kDebugMode) debugPrint('IconService: icona Material sconosciuta "$ref"');
        return _fallback(size, c);
      }
      return Icon(data, size: size, color: c);
    }
    if (ref.startsWith('svg:')) {
      final path = ref.substring(4);
      final recolor = !path.startsWith('ui/');
      return SvgPicture.asset(
        'assets/icons/$path.svg',
        width: size,
        height: size,
        theme: SvgTheme(currentColor: c),
        colorFilter: recolor ? ColorFilter.mode(c, BlendMode.srcIn) : null,
        errorBuilder: (_, _, _) => _fallback(size, c),
      );
    }
    return _fallback(size, c);
  }
}
