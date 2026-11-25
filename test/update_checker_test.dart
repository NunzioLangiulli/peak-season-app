import 'package:flutter_test/flutter_test.dart';
import 'package:peak_season/data/update_checker.dart';

void main() {
  test('version comparison', () {
    expect(compareVersions('1.2.1', '1.2.0'), greaterThan(0));
    expect(compareVersions('1.10.0', '1.9.9'), greaterThan(0)); // numeric, not alphabetical
    expect(compareVersions('2.0.0', '1.99.0'), greaterThan(0));
    expect(compareVersions('1.2.0', '1.2.0'), 0);
    expect(compareVersions('1.2', '1.2.0'), 0);
    expect(compareVersions('1.0.0-beta.1', '1.0.0'), 0);
    expect(compareVersions('1.1.7', '1.2.0'), lessThan(0));
  });
}
