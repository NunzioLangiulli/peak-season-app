import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:peak_season/notifications/live_activity.dart';

void main() {
  test('<b> tags become bold runs, one list per line', () {
    final runs = LiveActivity.toRuns(['<b>Lista della Spesa:</b> <b>Mela</b>, <b>Latte</b>', '<b>Di Stagione:</b> Pera, Uva +3']);
    expect(runs, [
      [
        {'t': 'Lista della Spesa:', 'b': true},
        {'t': ' ', 'b': false},
        {'t': 'Mela', 'b': true},
        {'t': ', ', 'b': false},
        {'t': 'Latte', 'b': true},
      ],
      [
        {'t': 'Di Stagione:', 'b': true},
        {'t': ' Pera, Uva +3', 'b': false},
      ],
    ]);
  });

  test('stays under the ActivityKit size limit', () {
    final long = List.filled(40, '<b>Di Stagione:</b> ${List.filled(30, 'Fagiolino').join(', ')}');
    final runs = LiveActivity.toRuns(long);
    expect(runs.length, lessThan(40));
    expect(utf8.encode(jsonEncode(runs)).length, lessThan(4096));
  });
}
