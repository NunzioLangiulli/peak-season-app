import 'app_enums.dart';
import 'glossary.dart';
import 'season_state.dart';

/// Bilingual `{it, en}` text from the database.
class LocalizedText {
  const LocalizedText({this.it = '', this.en = ''});

  static const empty = LocalizedText();

  final String it;
  final String en;

  /// Accepts `{it, en}`, a plain string or null.
  factory LocalizedText.fromJson(Object? json) {
    if (json is Map) {
      return LocalizedText(
        it: (json['it'] ?? '').toString(),
        en: (json['en'] ?? json['it'] ?? '').toString(),
      );
    }
    if (json is String) return LocalizedText(it: json, en: json);
    return empty;
  }

  /// Text in the requested language; if missing, uses the other one.
  String of(AppLanguage lang) {
    final v = lang == AppLanguage.en ? en : it;
    return v.isNotEmpty ? v : (lang == AppLanguage.en ? it : en);
  }

  bool get isEmpty => it.isEmpty && en.isEmpty;
}

/// Credits of an image (`images.image_details[]`).
class ImageCredit {
  const ImageCredit({required this.author, required this.license, this.sourceUrl});

  final String author;
  final String license;
  final String? sourceUrl;

  factory ImageCredit.fromJson(Map json) => ImageCredit(
        author: (json['author'] ?? '').toString(),
        license: (json['license'] ?? '').toString(),
        sourceUrl: json['source_url'] as String?,
      );
}

/// Estimated series (`seasonality.estimates.*.<zone>`): copy of the most
/// similar neighbouring zone, with the source zone in [from].
class EstimatedSeries {
  const EstimatedSeries(this.months, this.from);
  final List<SeasonState> months;
  final String? from;
}

/// The product's seasonal series as stored in the database; choosing the
/// series for the user's zone happens in `SeasonalityResolver`.
class FoodSeasonality {
  const FoodSeasonality({
    required this.euficZones,
    required this.italyMacroAreas,
    required this.italyNational,
    this.estimatedZones = const {},
    this.estimatedAreas = const {},
    this.notGrownZones = const {},
  });

  /// zona EUFIC -> 12 stati (dati veri).
  final Map<String, List<SeasonState>> euficZones;

  /// `nord` / `centro` / `sud_isole` -> 12 stati (dati veri).
  final Map<String, List<SeasonState>> italyMacroAreas;

  /// Italian national series (may be missing).
  final List<SeasonState>? italyNational;

  /// Database estimates (`seasonality.estimates.eufic_climatic_zones`).
  final Map<String, EstimatedSeries> estimatedZones;

  /// Database estimates (`seasonality.estimates.italy_macro_areas`).
  final Map<String, EstimatedSeries> estimatedAreas;

  /// Zones where an exotic fruit is not grown (`estimates.not_grown`).
  final Set<String> notGrownZones;

  static List<SeasonState>? _parseMonths(Object? json) {
    if (json is! List || json.length != 12) return null;
    return List.unmodifiable(json.map(SeasonState.fromCode));
  }

  static Map<String, List<SeasonState>> _parseMap(Object? json) {
    final out = <String, List<SeasonState>>{};
    if (json is Map) {
      json.forEach((k, v) {
        final months = _parseMonths(v);
        if (months != null) out[k.toString()] = months;
      });
    }
    return out;
  }

  static Map<String, EstimatedSeries> _parseEstimates(Object? json) {
    final out = <String, EstimatedSeries>{};
    if (json is Map) {
      json.forEach((k, v) {
        if (v is Map) {
          final months = _parseMonths(v['months']);
          if (months != null) out[k.toString()] = EstimatedSeries(months, v['from']?.toString());
        }
      });
    }
    return out;
  }

  factory FoodSeasonality.fromJson(Map? json) {
    final est = (json?['estimates'] as Map?) ?? const {};
    return FoodSeasonality(
      euficZones: _parseMap(json?['eufic_climatic_zones']),
      italyMacroAreas: _parseMap(json?['italy_macro_areas']),
      italyNational: _parseMonths(json?['italy_national']),
      estimatedZones: _parseEstimates(est['eufic_climatic_zones']),
      estimatedAreas: _parseEstimates(est['italy_macro_areas']),
      notGrownZones: {
        ...((est['not_grown'] as List?) ?? const []).map((e) => e.toString()),
      },
    );
  }
}

/// Product: only the fields used in Phase 2 (cards, filters, basic page).
/// The full scientific fields will be added in Phase 3.
class FoodItem {
  FoodItem({
    required this.id,
    required this.name,
    required this.synonyms,
    required this.category,
    required this.scientificName,
    required this.family,
    required this.primaryImage,
    required this.gallery,
    required this.imageCredits,
    required this.hasDopIgp,
    required this.dopIgpLabels,
    required this.notableVarieties,
    required this.cardShortStorage,
    required this.ripeningBadge,
    required this.primaryLocation,
    required this.shoppingListPreview,
    required this.seasonality,
    required this.ripeningType,
    required this.raw,
  }) : _searchIndex = _buildSearchIndex(
          name,
          synonyms,
          notableVarieties,
          scientificName,
          family,
        );

  final String id;
  final LocalizedText name;

  /// Synonyms by language (`names.synonyms.it/en`).
  final Map<AppLanguage, List<String>> synonyms;
  final FoodCategory category;
  final String? scientificName;
  final String? family;

  /// Original JPEG file name (e.g. `aglio_garlic_02.jpg`), null if missing.
  final String? primaryImage;
  final List<String> gallery;
  final Map<String, ImageCredit> imageCredits;

  final bool hasDopIgp;
  final List<String> dopIgpLabels;
  final List<String> notableVarieties;

  final LocalizedText cardShortStorage;
  final LocalizedText ripeningBadge;

  /// `frigorifero` / `temperatura_ambiente` / `luogo_fresco_buio`.
  final String? primaryLocation;
  final LocalizedText shoppingListPreview;
  final FoodSeasonality seasonality;

  /// `climaterico` / `non_climaterico`.
  final String? ripeningType;

  /// Full JSON of the product, read by the product page with `JsonPath`
  /// (the detail sections do not have a typed model yet).
  final Map<String, dynamic> raw;

  final String _searchIndex;

  static const _rating = 'nutrition_and_sustainability.environmental_footprint.sustainability_rating';

  /// Carbon / water footprint level: `low` / `medium` / `high`.
  String? get carbonLevel => _str(raw.at('$_rating.carbon_level'));
  String? get waterLevel => _str(raw.at('$_rating.water_level'));

  static String? _str(Object? v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  static List<String> _strList(Object? v) =>
      v is List ? v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList() : const [];

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    final names = (json['names'] as Map?) ?? const {};
    final syn = (names['synonyms'] as Map?) ?? const {};
    final botany = (json['botany'] as Map?) ?? const {};
    final images = (json['images'] as Map?) ?? const {};
    final varieties = (json['italian_varieties_and_territories'] as Map?) ?? const {};
    final storage = (json['ripening_and_storage'] as Map?) ?? const {};
    final buying = (json['buying_guide'] as Map?) ?? const {};

    final credits = <String, ImageCredit>{};
    for (final d in (images['image_details'] as List?) ?? const []) {
      if (d is Map && d['filename'] != null) {
        credits[d['filename'].toString()] = ImageCredit.fromJson(d);
      }
    }
    final primary = _str(images['primary']);
    final gallery = _strList(images['gallery']);
    if (primary != null && !gallery.contains(primary)) gallery.insert(0, primary);

    return FoodItem(
      id: json['id'].toString(),
      name: LocalizedText.fromJson(names),
      synonyms: {
        AppLanguage.it: _strList(syn['it']),
        AppLanguage.en: _strList(syn['en']),
      },
      category: FoodCategory.fromCode(json['category']),
      scientificName: _str(botany['scientific_name']),
      family: _str(botany['family']),
      primaryImage: primary,
      gallery: List.unmodifiable(gallery),
      imageCredits: credits,
      hasDopIgp: varieties['has_dop_igp'] == true,
      dopIgpLabels: _strList(varieties['dop_igp_labels']),
      notableVarieties: _strList(varieties['notable_varieties']),
      cardShortStorage: LocalizedText.fromJson(storage['card_short_storage']),
      ripeningBadge: LocalizedText.fromJson(storage['ripening_badge_label']),
      primaryLocation: _str(storage['primary_location']),
      shoppingListPreview: LocalizedText.fromJson(buying['shopping_list_preview']),
      seasonality: FoodSeasonality.fromJson(json['seasonality'] as Map?),
      ripeningType: _str(storage['ripening_type']),
      raw: json,
    );
  }

  /// Search by IT/EN name, synonyms, varieties, scientific name and family.
  /// Singular and plural are equivalent ("zucchine" finds "zucchina",
  /// "tomatoes" finds "tomato"): every search word also works as a stem.
  bool matches(String normalizedQuery) {
    if (normalizedQuery.isEmpty || _searchIndex.contains(normalizedQuery)) return true;
    final words = normalizedQuery.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return words.isNotEmpty && words.every((w) => _searchIndex.contains(searchStem(w)));
  }

  /// Word stem for search: strips the plural or singular ending
  /// (it: -a/-e/-i/-o, -che/-ghi → -c/-g; en: -s, -es, -ies).
  static String searchStem(String w) {
    if (w.length < 4) return w;
    if (w.endsWith('ies') && w.length > 4) return w.substring(0, w.length - 3);
    if (w.endsWith('oes') || w.endsWith('ches') || w.endsWith('shes')) return w.substring(0, w.length - 2);
    var s = w;
    if ('aeios'.contains(s[s.length - 1])) s = s.substring(0, s.length - 1);
    // pesche → pesc (like pesca), funghi → fung (like fungo)
    if (s.length > 3 && (s.endsWith('ch') || s.endsWith('gh'))) s = s.substring(0, s.length - 1);
    return s;
  }

  static String _buildSearchIndex(
    LocalizedText name,
    Map<AppLanguage, List<String>> synonyms,
    List<String> varieties,
    String? scientificName,
    String? family,
  ) {
    return normalizeForSearch([
      name.it,
      name.en,
      ...synonyms.values.expand((e) => e),
      ...varieties,
      scientificName ?? '',
      family ?? '',
    ].join(' | '));
  }
}

/// Lowercase and without accents, for tolerant search ("perche" = "perché").
String normalizeForSearch(String input) {
  const from = 'àáâäãåèéêëìíîïòóôöõùúûüçñ';
  const to = 'aaaaaaeeeeiiiiooooouuuucn';
  final lower = input.toLowerCase();
  final buf = StringBuffer();
  for (final ch in lower.split('')) {
    final i = from.indexOf(ch);
    buf.write(i >= 0 ? to[i] : ch);
  }
  return buf.toString().trim();
}
