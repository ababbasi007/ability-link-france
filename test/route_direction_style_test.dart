import 'package:ability_link/models/route_direction_style.dart';
import 'package:ability_link/models/route_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  const loc = LatLng(0, 0);

  RouteStep step({
    String instruction = '',
    String type = '',
    String modifier = '',
  }) {
    return RouteStep(
      instruction: instruction,
      location: loc,
      distanceMeters: 10,
      durationSeconds: 5,
      maneuverType: type,
      maneuverModifier: modifier,
    );
  }

  test('left / right / arrive get distinct colors and icons', () {
    final left = RouteDirectionStyle.forStep(
      step(modifier: 'left', instruction: 'Turn left'),
    );
    final right = RouteDirectionStyle.forStep(
      step(modifier: 'right', instruction: 'Turn right'),
    );
    final arrive = RouteDirectionStyle.forStep(
      step(type: 'arrive', instruction: 'You have arrived'),
    );

    expect(left.kind, RouteDirectionKind.left);
    expect(right.kind, RouteDirectionKind.right);
    expect(arrive.kind, RouteDirectionKind.arrive);
    expect(left.color, isNot(equals(right.color)));
    expect(left.icon, Icons.turn_left_rounded);
    expect(right.icon, Icons.turn_right_rounded);
    expect(arrive.icon, Icons.flag_rounded);
  });

  test('elevator and stairs inferred from instruction text', () {
    final elev = RouteDirectionStyle.forInstruction(
      'Take elevator from Ground to Floor 2',
    );
    final stairs = RouteDirectionStyle.forInstruction('Use stairs to Floor 1');
    expect(elev.kind, RouteDirectionKind.elevator);
    expect(stairs.kind, RouteDirectionKind.stairs);
  });
}
