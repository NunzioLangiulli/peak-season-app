import 'food_item.dart';

/// Source cited by a glossary entry.
class GlossarySource {
  const GlossarySource({
    required this.name,
    this.url,
    this.key,
    this.publisher = LocalizedText.empty,
    this.title = LocalizedText.empty,
    this.favicon,
  });
  final String name;
  final String? url;

  /// Source key (e.g. `uc_davis`): used to show its logo.
  final String? key;

  /// Publisher (e.g. "UC Davis") and document title, kept separate by the database.
  final LocalizedText publisher;
  final LocalizedText title;

  /// Logo file in `assets/sources/` (possibly of another source from the
  /// same organisation), null if there is none.
  final String? favicon;
}

/// Entry of `metadata.glossary`: feeds the grey "?" buttons.
class GlossaryEntry {
  const GlossaryEntry({
    required this.id,
    required this.term,
    required this.short,
    required this.text,
    required this.sources,
    required this.seeAlso,
  });

  final String id;
  final LocalizedText term;
  final LocalizedText short;
  final LocalizedText text;
  final List<GlossarySource> sources;
  final List<String> seeAlso;

  factory GlossaryEntry.fromJson(String id, Map json) => GlossaryEntry(
        id: id,
        term: LocalizedText.fromJson(json['term']),
        short: LocalizedText.fromJson(json['short']),
        text: LocalizedText.fromJson(json['text']),
        sources: [
          for (final s in (json['sources'] as List?) ?? const [])
            if (s is Map)
              GlossarySource(
                name: (s['name'] ?? '').toString(),
                url: s['url'] as String?,
                key: s['key'] as String?,
                publisher: LocalizedText.fromJson(s['publisher']),
                title: LocalizedText.fromJson(s['title']),
                favicon: s['favicon'] as String?,
              ),
        ],
        seeAlso: [...((json['see_also'] as List?) ?? const []).map((e) => e.toString())],
      );
}

/// Safe reading of nested paths in the raw JSON
/// (e.g. `item.raw.at('ripening_and_storage.home_storage.tip')`).
extension JsonPath on Map<String, dynamic> {
  Object? at(String path) {
    Object? cur = this;
    for (final key in path.split('.')) {
      if (cur is Map) {
        cur = cur[key];
      } else {
        return null;
      }
    }
    return cur;
  }

  LocalizedText text(String path) => LocalizedText.fromJson(at(path));

  List<dynamic> list(String path) {
    final v = at(path);
    return v is List ? v : const [];
  }

  Map<String, dynamic> obj(String path) {
    final v = at(path);
    return v is Map<String, dynamic> ? v : const {};
  }

  num? number(String path) {
    final v = at(path);
    return v is num ? v : null;
  }
}
