import 'package:ability_link/models/user_activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('inferSearchCategory maps common venue queries', () {
    expect(inferSearchCategory('City Hospital'), 'hospital');
    expect(inferSearchCategory('quiet cafe nearby'), 'cafe');
    expect(inferSearchCategory('metro station'), 'transit');
    expect(inferSearchCategory('wheelchair ramp'), 'accessibility');
    expect(inferSearchCategory('random place'), 'other');
  });

  test('UserActivityStats distance label formats meters and km', () {
    expect(const UserActivityStats(totalMeters: 420).distanceLabel, '420 m');
    expect(
      const UserActivityStats(totalMeters: 2500).distanceLabel,
      '2.5 km',
    );
  });
}
