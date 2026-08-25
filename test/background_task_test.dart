import 'package:ability_link/services/background_task.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FlutterExceptionHandler? previous;
  late List<FlutterErrorDetails> reported;

  setUp(() {
    reported = <FlutterErrorDetails>[];
    previous = FlutterError.onError;
    FlutterError.onError = reported.add;
  });

  tearDown(() => FlutterError.onError = previous);

  test('reports a failed task instead of swallowing it', () async {
    runInBackground(Future<void>.error(StateError('boom')), 'seed widgets');
    await Future<void>.delayed(Duration.zero);

    expect(reported, hasLength(1));
    expect(reported.single.exception, isA<StateError>());
    expect(reported.single.context.toString(), contains('seed widgets'));
  });

  test('a failure does not propagate to the caller', () async {
    // initState callers cannot await this, so it must never throw at them.
    expect(
      () => runInBackground(Future<void>.error('nope'), 'seed things'),
      returnsNormally,
    );
    await Future<void>.delayed(Duration.zero);
    expect(reported, hasLength(1));
  });

  test('stays quiet when the task succeeds', () async {
    runInBackground(Future<void>.value(), 'seed things');
    await Future<void>.delayed(Duration.zero);

    expect(reported, isEmpty);
  });
}
