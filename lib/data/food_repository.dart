import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/app_enums.dart';
import '../models/food_item.dart';
import '../models/glossary.dart';
import '../models/nutrition_claims.dart';
import '../models/season_state.dart';

/// Percorsi degli asset generati da `scripts/build_app_assets.py`.
class AssetPaths {
  static const database = 'assets/data/database.json';

  static String _webp(String jpg) =>
      '${jpg.substring(0, jpg.lastIndexOf('.'))}.webp';

  /// Miniatura (600 px) per card e righe.
  static String thumb(String jpg) => 'assets/images/thumb/${_webp(jpg)}';

  /// Immagine della galleria (1080 px) per la scheda alimento.
  static String full(String jpg) => 'assets/images/full/${_webp(jpg)}';
}

/// Voce di legenda degli stati (`metadata.seasonality_states_legend`).
class SeasonLegendEntry {
  const SeasonLegendEntry({required this.label, required this.description});
  final LocalizedText label;
  final LocalizedText description;
}

/// Testo della pagina "More Sustainable Diet" (`metadata.sustainable_diet_summary`).
class SustainableDietSummary {
  const SustainableDietSummary({
    required this.text,
    required this.keyPoints,
    this.sourceUrl,
  });

  final LocalizedText text;
  final Map<AppLanguage, List<String>> keyPoints;
  final String? sourceUrl;
}

/// Database caricato in memoria, in sola lettura.
class FoodDatabase {
  FoodDatabase({
    required this.items,
    required this.seasonLegend,
    required this.zoneCountries,
    required this.sustainableDiet,
    required this.version,
    required this.glossary,
    required this.vocabulary,
    required this.fieldHelp,
    required this.estimatesMethod,
    this.referenceOrder = const [],
    this.zoneColors = const {},
    this.zoneIcons = const {},
    this.footprintLevels = const {},
    this.claimRules = NutritionClaimRules.empty,
  }) : byId = {for (final i in items) i.id: i};

  /// Livelli dell'impronta di carbonio e idrica (`environmental_footprint_method.levels`):
  /// codice (`low`/`medium`/`high`) -> colore ARGB.
  final Map<String, int> footprintLevels;

  /// Colore del livello d'impronta (grigio se sconosciuto).
  int footprintColor(String? level) => footprintLevels[level] ?? 0xFF9E9E9E;

  /// `metadata.nutrition_claims_eu_rules`.
  final NutritionClaimRules claimRules;

  final List<FoodItem> items;
  final Map<String, FoodItem> byId;
  final Map<SeasonState, SeasonLegendEntry> seasonLegend;

  /// zona EUFIC -> Paesi principali (per la scelta nelle impostazioni).
  final Map<ClimaticZone, List<String>> zoneCountries;
  final SustainableDietSummary sustainableDiet;
  final String version;

  /// `metadata.glossary`: id -> voce, per i pulsanti "?".
  final Map<String, GlossaryEntry> glossary;

  /// `metadata.vocabulary`: campo -> codice -> {it, en}.
  final Map<String, Map<String, LocalizedText>> vocabulary;

  /// `metadata.field_help`: percorso del campo -> id del glossario.
  final Map<String, List<String>> fieldHelp;

  /// Colore di ogni zona per la mappa (`eufic_climatic_zones_legend.*.color_hex`).
  final Map<ClimaticZone, int> zoneColors;

  /// Simbolo di ogni zona (`eufic_climatic_zones_legend.*.icon`, es. `water_drop`),
  /// disegnato in `assets/icons/zones/<icon>.svg`.
  final Map<ClimaticZone, String> zoneIcons;

  /// `metadata.seasonality_reference_order`: da dove prendere il calendario
  /// di riferimento quando la zona non ha dati.
  final List<String> referenceOrder;

  /// Nome della famiglia botanica nella lingua attiva (`vocabulary["botany.family"]`),
  /// es. Solanaceae → Solanacee; se manca, il nome latino.
  LocalizedText familyName(String latin) =>
      vocabulary['botany.family']?[latin] ?? LocalizedText(it: latin, en: latin);

  /// `metadata.seasonality_estimates_method`.
  final LocalizedText estimatesMethod;

  /// Etichetta tradotta di un valore codificato (es. `climaterico`).
  LocalizedText vocab(String field, String? code) =>
      vocabulary[field]?[code] ?? LocalizedText(it: code ?? '', en: code ?? '');

  /// Voci del glossario collegate a un campo (vuoto se nessuna).
  List<GlossaryEntry> helpFor(String fieldPath) => [
        for (final id in fieldHelp[fieldPath] ?? const <String>[])
          if (glossary[id] != null) glossary[id]!,
      ];

  List<GlossaryEntry> entries(List<String> ids) => [
        for (final id in ids)
          if (glossary[id] != null) glossary[id]!,
      ];
}

class FoodRepository {
  /// Legge `assets/data/database.json` (4-5 MB) e lo decodifica in un
  /// isolate separato, così il primo frame non si blocca.
  static Future<FoodDatabase> load() async {
    final raw = await rootBundle.loadString(AssetPaths.database, cache: false);
    return compute(parseDatabase, raw);
  }

  /// Sostituisce, ovunque tranne nel corpus stesso, i riferimenti al corpus
  /// condiviso (`shared_descriptions_corpus`) con il testo completo {it, en}:
  ///   {"corpus_ref": k}                         → corpus[k]
  ///   {"corpus_ref": k, "specific_addition": a} → corpus[k] + " " + a
  /// Così il resto dell'app legge sempre {it, en}. Chiave sconosciuta → testo
  /// vuoto (e un avviso in debug). Riferimento Python: scripts/corpus.py.
  @visibleForTesting
  static void resolveCorpusRefs(Map<String, dynamic> json) {
    final corpus = (json['shared_descriptions_corpus'] as Map?) ?? const {};
    Object? resolve(Map ref) {
      final key = '${ref['corpus_ref']}';
      final base = corpus[key];
      if (base is! Map) {
        if (kDebugMode) debugPrint('corpus_ref sconosciuto: $key');
      }
      final add = ref['specific_addition'];
      String join(String l) {
        final b = base is Map ? '${base[l] ?? ''}' : '';
        final a = add is Map ? '${add[l] ?? ''}' : '';
        return '$b $a'.trim();
      }
      return <String, dynamic>{'it': join('it'), 'en': join('en')};
    }

    void walk(Object? o) {
      if (o is Map) {
        for (final k in o.keys.toList()) {
          final v = o[k];
          if (v is Map && v.containsKey('corpus_ref')) {
            o[k] = resolve(v);
          } else {
            walk(v);
          }
        }
      } else if (o is List) {
        for (var i = 0; i < o.length; i++) {
          final v = o[i];
          if (v is Map && v.containsKey('corpus_ref')) {
            o[i] = resolve(v);
          } else {
            walk(v);
          }
        }
      }
    }

    for (final k in json.keys) {
      if (k != 'shared_descriptions_corpus') walk(json[k]);
    }
  }

  @visibleForTesting
  static FoodDatabase parseDatabase(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    resolveCorpusRefs(json);
    final meta = (json['metadata'] as Map?) ?? const {};

    final items = <FoodItem>[];
    for (final it in (json['items'] as List? ?? const [])) {
      if (it is Map<String, dynamic> && it['id'] != null) {
        items.add(FoodItem.fromJson(it));
      }
    }

    final legend = <SeasonState, SeasonLegendEntry>{};
    final legendJson = (meta['seasonality_states_legend'] as Map?) ?? const {};
    legendJson.forEach((code, v) {
      final state = SeasonState.fromCode(code);
      if (state != SeasonState.unknown && v is Map) {
        legend[state] = SeasonLegendEntry(
          label: LocalizedText.fromJson(v['ui_label']),
          description: LocalizedText.fromJson(v),
        );
      }
    });

    final zoneColors = <ClimaticZone, int>{};
    final zoneIcons = <ClimaticZone, String>{};
    final zones = <ClimaticZone, List<String>>{};
    final zonesJson = (meta['eufic_climatic_zones_legend'] as Map?) ?? const {};
    for (final z in ClimaticZone.values) {
      final v = zonesJson[z.code];
      if (v is Map && v['color_hex'] is String) {
        zoneColors[z] = int.parse('FF${(v['color_hex'] as String).substring(1)}', radix: 16);
        // accetta anche la forma "svg:zones/<nome>" scritta dall'Admin Studio
        if (v['icon'] is String) zoneIcons[z] = (v['icon'] as String).replaceFirst(RegExp(r'^svg:zones/'), '');
      }
      if (v is Map) {
        zones[z] = [
          ...((v['countries_primary'] as List?) ?? const []).map((e) => e.toString()),
        ];
      }
    }

    final diet = (meta['sustainable_diet_summary'] as Map?) ?? const {};
    final kp = (diet['key_points'] as Map?) ?? const {};
    List<String> points(Object? v) =>
        v is List ? v.map((e) => e.toString()).toList() : const [];

    final glossary = <String, GlossaryEntry>{};
    ((meta['glossary'] as Map?) ?? const {}).forEach((k, v) {
      if (v is Map) glossary[k.toString()] = GlossaryEntry.fromJson(k.toString(), v);
    });
    final vocabulary = <String, Map<String, LocalizedText>>{};
    ((meta['vocabulary'] as Map?) ?? const {}).forEach((field, values) {
      if (values is Map) {
        final m = <String, LocalizedText>{};
        values.forEach((code, v) {
          if (v is Map && !code.toString().startsWith('_')) m[code.toString()] = LocalizedText.fromJson(v);
        });
        vocabulary[field.toString()] = m;
      }
    });
    final fieldHelp = <String, List<String>>{};
    ((meta['field_help'] as Map?) ?? const {}).forEach((k, v) {
      if (v is List) fieldHelp[k.toString()] = [...v.map((e) => e.toString())];
    });

    final footprintLevels = <String, int>{};
    (((meta['environmental_footprint_method'] as Map?)?['levels'] as Map?) ?? const {}).forEach((k, v) {
      final hex = v is Map ? v['color_hex'] as String? : null;
      if (hex != null) footprintLevels['$k'] = int.parse('FF${hex.replaceFirst('#', '')}', radix: 16);
    });

    return FoodDatabase(
      footprintLevels: footprintLevels,
      claimRules: NutritionClaimRules.fromJson(meta['nutrition_claims_eu_rules']),
      glossary: glossary,
      vocabulary: vocabulary,
      fieldHelp: fieldHelp,
      estimatesMethod: LocalizedText.fromJson(meta['seasonality_estimates_method']),
      zoneColors: zoneColors,
      zoneIcons: zoneIcons,
      referenceOrder: [...((meta['seasonality_reference_order'] as List?) ?? const []).map((e) => '$e')],
      items: List.unmodifiable(items),
      seasonLegend: legend,
      zoneCountries: zones,
      sustainableDiet: SustainableDietSummary(
        text: LocalizedText.fromJson(diet),
        keyPoints: {
          AppLanguage.it: points(kp['it']),
          AppLanguage.en: points(kp['en']),
        },
        sourceUrl: diet['source_url'] as String?,
      ),
      version: (meta['version'] ?? '').toString(),
    );
  }
}
