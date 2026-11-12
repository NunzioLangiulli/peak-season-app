import 'food_item.dart';

/// Gruppo di indicazioni nutrizionali UE ("A Basso Contenuto di", "Fonte di"…).
class ClaimGroup {
  const ClaimGroup({required this.code, required this.label, required this.order});
  final String code;
  final LocalizedText label;
  final int order;
}

/// Regola di un'indicazione: gruppo, nutriente a cui si riferisce e tono.
class ClaimRule {
  const ClaimRule({required this.group, required this.nutrient, required this.nutrientLabel, required this.tone});
  final String group;

  /// Chiave del nutriente: `kcal`, `fats`, `sugars`, `salt`, `fiber`,
  /// `proteins` oppure la `key` di una voce di vitamins/minerals.
  final String nutrient;
  final LocalizedText nutrientLabel;

  /// `favorable` o `warning`.
  final String tone;
  bool get isWarning => tone == 'warning';
}

/// `metadata.nutrition_claims_eu_rules`: le indicazioni dei prodotti sono
/// testi; le regole (chiave = testo italiano) dicono a cosa si riferiscono.
class NutritionClaimRules {
  const NutritionClaimRules({this.groups = const {}, this.claims = const {}, this.nutrientNames = const {}});

  static const empty = NutritionClaimRules();

  final Map<String, ClaimGroup> groups;
  final Map<String, ClaimRule> claims;

  /// Nome breve di ogni micronutriente (`nutrient_keys`): "Vitamina A", "Folati"…
  final Map<String, LocalizedText> nutrientNames;

  factory NutritionClaimRules.fromJson(Object? json) {
    if (json is! Map) return empty;
    final groups = <String, ClaimGroup>{};
    ((json['groups'] as Map?) ?? const {}).forEach((k, v) {
      if (v is Map) {
        groups['$k'] = ClaimGroup(
          code: '$k',
          label: LocalizedText.fromJson(v['label']),
          order: (v['order'] as num?)?.toInt() ?? 99,
        );
      }
    });
    final claims = <String, ClaimRule>{};
    ((json['claims'] as Map?) ?? const {}).forEach((k, v) {
      if (v is Map) {
        claims['$k'] = ClaimRule(
          group: '${v['group']}',
          nutrient: '${v['nutrient']}',
          nutrientLabel: LocalizedText.fromJson(v['nutrient_label']),
          tone: '${v['tone'] ?? 'favorable'}',
        );
      }
    });
    final names = <String, LocalizedText>{};
    ((json['nutrient_keys'] as Map?) ?? const {}).forEach((k, v) => names['$k'] = LocalizedText.fromJson(v));
    return NutritionClaimRules(groups: groups, claims: claims, nutrientNames: names);
  }
}
