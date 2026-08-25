import 'package:flutter/material.dart';

import 'route_step.dart';

/// Cognitive-friendly turn style: color + icon + short label (never color alone).
enum RouteDirectionKind {
  depart,
  straight,
  slightLeft,
  left,
  sharpLeft,
  slightRight,
  right,
  sharpRight,
  uTurn,
  roundabout,
  arrive,
  elevator,
  stairs,
  other,
}

class RouteDirectionStyle {
  const RouteDirectionStyle({
    required this.kind,
    required this.icon,
    required this.color,
    required this.shortLabel,
  });

  final RouteDirectionKind kind;
  final IconData icon;
  final Color color;
  final String shortLabel;

  static RouteDirectionStyle forStep(RouteStep step) {
    return forManeuver(
      type: step.maneuverType,
      modifier: step.maneuverModifier,
      instruction: step.instruction,
    );
  }

  static RouteDirectionStyle forInstruction(String instruction) {
    return forManeuver(type: '', modifier: '', instruction: instruction);
  }

  static RouteDirectionStyle forManeuver({
    required String type,
    required String modifier,
    required String instruction,
  }) {
    final t = type.toLowerCase().trim();
    final m = modifier.toLowerCase().trim();
    final text = instruction.toLowerCase();

    if (t == 'arrive' || text.contains('arriv') || text.contains('destination')) {
      return const RouteDirectionStyle(
        kind: RouteDirectionKind.arrive,
        icon: Icons.flag_rounded,
        color: Color(0xFF006D44),
        shortLabel: 'Arrive',
      );
    }
    if (t == 'depart' || text.startsWith('head ') || text.contains('start')) {
      return const RouteDirectionStyle(
        kind: RouteDirectionKind.depart,
        icon: Icons.navigation_rounded,
        color: Color(0xFF0F766E),
        shortLabel: 'Start',
      );
    }
    if (text.contains('elevator') || text.contains('lift')) {
      return const RouteDirectionStyle(
        kind: RouteDirectionKind.elevator,
        icon: Icons.elevator_rounded,
        color: Color(0xFF2563EB),
        shortLabel: 'Elevator',
      );
    }
    if (text.contains('stair') || m.contains('stairs')) {
      return const RouteDirectionStyle(
        kind: RouteDirectionKind.stairs,
        icon: Icons.stairs_rounded,
        color: Color(0xFFB45309),
        shortLabel: 'Stairs',
      );
    }
    if (t.contains('roundabout') ||
        t.contains('rotary') ||
        text.contains('roundabout')) {
      return const RouteDirectionStyle(
        kind: RouteDirectionKind.roundabout,
        icon: Icons.roundabout_left_rounded,
        color: Color(0xFF7C3AED),
        shortLabel: 'Roundabout',
      );
    }
    if (m.contains('uturn') ||
        m.contains('u-turn') ||
        text.contains('u-turn') ||
        text.contains('uturn')) {
      return const RouteDirectionStyle(
        kind: RouteDirectionKind.uTurn,
        icon: Icons.u_turn_left_rounded,
        color: Color(0xFFDB2777),
        shortLabel: 'U-turn',
      );
    }

    final isLeft = m.contains('left') ||
        text.contains(' left') ||
        text.startsWith('left') ||
        t == '4' ||
        t == '5' ||
        t == '6';
    final isRight = m.contains('right') ||
        text.contains(' right') ||
        text.startsWith('right') ||
        t == '1' ||
        t == '2' ||
        t == '3';
    final slight = m.contains('slight') || text.contains('slight');
    final sharp = m.contains('sharp') || text.contains('sharp');

    if (isLeft) {
      if (slight) {
        return const RouteDirectionStyle(
          kind: RouteDirectionKind.slightLeft,
          icon: Icons.turn_slight_left_rounded,
          color: Color(0xFF0891B2),
          shortLabel: 'Bear left',
        );
      }
      if (sharp) {
        return const RouteDirectionStyle(
          kind: RouteDirectionKind.sharpLeft,
          icon: Icons.turn_sharp_left_rounded,
          color: Color(0xFF0369A1),
          shortLabel: 'Sharp left',
        );
      }
      return const RouteDirectionStyle(
        kind: RouteDirectionKind.left,
        icon: Icons.turn_left_rounded,
        color: Color(0xFF0284C7),
        shortLabel: 'Left',
      );
    }
    if (isRight) {
      if (slight) {
        return const RouteDirectionStyle(
          kind: RouteDirectionKind.slightRight,
          icon: Icons.turn_slight_right_rounded,
          color: Color(0xFFEA580C),
          shortLabel: 'Bear right',
        );
      }
      if (sharp) {
        return const RouteDirectionStyle(
          kind: RouteDirectionKind.sharpRight,
          icon: Icons.turn_sharp_right_rounded,
          color: Color(0xFFC2410C),
          shortLabel: 'Sharp right',
        );
      }
      return const RouteDirectionStyle(
        kind: RouteDirectionKind.right,
        icon: Icons.turn_right_rounded,
        color: Color(0xFFF97316),
        shortLabel: 'Right',
      );
    }
    if (t == 'continue' ||
        m.contains('straight') ||
        text.contains('continue') ||
        text.contains('straight')) {
      return const RouteDirectionStyle(
        kind: RouteDirectionKind.straight,
        icon: Icons.straight_rounded,
        color: Color(0xFF4F46E5),
        shortLabel: 'Straight',
      );
    }

    return const RouteDirectionStyle(
      kind: RouteDirectionKind.other,
      icon: Icons.directions_rounded,
      color: Color(0xFF64748B),
      shortLabel: 'Go',
    );
  }
}

/// Compact colored direction chip used in lists and map banners.
class RouteDirectionChip extends StatelessWidget {
  const RouteDirectionChip({
    super.key,
    required this.style,
    this.label,
    this.compact = false,
  });

  final RouteDirectionStyle style;
  final String? label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = label ?? style.shortLabel;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: compact ? 14 : 16, color: style.color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: style.color,
            ),
          ),
        ],
      ),
    );
  }
}
