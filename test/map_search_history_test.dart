import 'package:ability_link/models/map_search_history.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseRecentMapSearches trims, dedupes, and caps', () {
    final parsed = parseRecentMapSearches({
      'recentSearches': [
        ' City Hospital ',
        'city hospital',
        'Central Library',
        '',
        42,
        'Green Cafe',
        'Grand Mall',
        'Pharmacy',
        'Station',
        'Extra',
      ],
    });
    expect(parsed, [
      'City Hospital',
      'Central Library',
      'Green Cafe',
      'Grand Mall',
      'Pharmacy',
      'Station',
      'Extra',
    ]);
    expect(parsed.length, lessThanOrEqualTo(mapSearchHistoryMaxItems));
  });

  test('pushRecentMapSearch moves duplicate to front', () {
    final next = pushRecentMapSearch(
      ['Central Library', 'City Hospital'],
      'city hospital',
    );
    expect(next, ['city hospital', 'Central Library']);
  });

  test('pushRecentMapSearch ignores blank query', () {
    expect(pushRecentMapSearch(['A'], '   '), ['A']);
  });
}
