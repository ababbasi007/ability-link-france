import 'package:ability_link/services/geocode_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('searchOne returns null on blank query', () async {
    final service = GeocodeService();
    final hit = await service.searchOne('   ');
    expect(hit, isNull);
  });
}
