import 'dart:async';

import 'package:flutter/foundation.dart';

/// Runs a fire-and-forget task without hiding its failures.
///
/// Seeding and sync run in `initState` and must not block the screen. Failures
/// are reported to [FlutterError.onError] so they reach the console and any
/// crash reporter while the screen carries on.
///
/// Accepts any [Future] (including `Future<int>` seed counters). Using
/// `catchError` on a non-void future previously crashed with:
/// "The error handler of Future.catchError must return a value of the
/// future's type".
void runInBackground(Future<Object?> task, String label) {
  unawaited(() async {
    try {
      await task;
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'ability_link',
          context: ErrorDescription('background task "$label" failed'),
        ),
      );
    }
  }());
}
