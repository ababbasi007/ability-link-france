import 'package:ability_link/services/push_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('token doc ids are stable and hide the raw token', () {
    const token = 'fcm-token-example';
    final id = fcmTokenDocId(token);
    expect(id, fcmTokenDocId(token));
    expect(id, isNot(contains(token)));
    expect(id, hasLength(64));
  });

  test('different tokens do not collide', () {
    expect(fcmTokenDocId('a'), isNot(fcmTokenDocId('b')));
  });
}
