import 'dart:convert';
import 'dart:io';

import '../app_info.dart';

/// Latest app release published on GitHub.
class LatestRelease {
  const LatestRelease({required this.version, required this.url});

  /// Version without the leading "v" (tag "v1.2.0" → "1.2.0").
  final String version;

  /// Page of that release on GitHub (with the APK and the .ipa).
  final String url;

  bool get isNewer => compareVersions(version, appVersion) > 0;
}

/// Asks GitHub for the latest release of the app (public API, no account,
/// nothing about the user is sent). Throws if offline or GitHub does not answer.
Future<LatestRelease> fetchLatestRelease() async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final req = await client.getUrl(Uri.parse('https://api.github.com/repos/$appRepoSlug/releases/latest'));
    req.headers
      ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
      ..set(HttpHeaders.userAgentHeader, 'PeakSeason-App');
    final res = await req.close().timeout(const Duration(seconds: 15));
    final body = await res.transform(utf8.decoder).join();
    if (res.statusCode != 200) throw HttpException('GitHub answered ${res.statusCode}');
    final json = jsonDecode(body) as Map<String, dynamic>;
    final tag = (json['tag_name'] as String?) ?? '';
    return LatestRelease(
      version: tag.startsWith('v') ? tag.substring(1) : tag,
      url: (json['html_url'] as String?) ?? '$appRepoUrl/releases/latest',
    );
  } finally {
    client.close(force: true);
  }
}

/// Compares two MAJOR.MINOR.PATCH versions (a pre-release suffix such as
/// "-beta.1" is ignored): > 0 if [a] is newer than [b].
int compareVersions(String a, String b) {
  List<int> parts(String v) =>
      v.split('-').first.split('.').map((p) => int.tryParse(p) ?? 0).toList()..addAll(const [0, 0, 0]);
  final pa = parts(a), pb = parts(b);
  for (var i = 0; i < 3; i++) {
    if (pa[i] != pb[i]) return pa[i].compareTo(pb[i]);
  }
  return 0;
}
