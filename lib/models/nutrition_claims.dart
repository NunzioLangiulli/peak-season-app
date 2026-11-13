import 'food_item.dart';

/// Group of EU nutrition claims ("Low in", "Source of"…).
class ClaimGroup {
  const ClaimGroup({required this.code, required this.label, required this.order});
  final String code;
  final LocalizedText label;
  final int order;
}

/// Rule of a claim: group, nutrient it refers to and tone.
class ClaimRule {
  const ClaimRule({required this.group, required this.nutrient, required this.nutrientLabel, required this.tone});
  final String group;

  /// Nutrient key: `kcal`, `fats`, `sugars`, `salt`, `fiber`,
  /// `proteins` or the `key` of a vitamins/minerals entry.
  final String nutrient;
  final LocalizedText nutrientLabel;

  /// `favorable` o `warning`.
  final String tone;
  bool get isWarning => tone == 'warning';
}

/// `metadata.nutrition_claims_eu_rules`: product claims are
/// texts; the rules (key = Italian text) say what they refer to.
class NutritionClaimRules {
  const NutritionClaimRules({this.groups = const {}, this.claims = const {}, this.nutrientNames = const {}});

  static const empty = NutritionClaimRules();

  final Map<String, ClaimGroup> groups;
  final Map<String, ClaimRule> claims;

  /// Short name of each micronutrient (`nutrient_keys`): "Vitamin A", "Folate"…
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
