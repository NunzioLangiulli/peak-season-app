import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:peak_season/app_info.dart';

void main() {
  test('appVersion matches the pubspec version', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final v = RegExp(r'^version:\s*([\d.]+)\+', multiLine: true).firstMatch(pubspec)![1];
    expect(appVersion, v);
  });
}
