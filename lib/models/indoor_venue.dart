import 'package:flutter/material.dart';

/// Point of interest kinds on an indoor floor plan.
enum IndoorPoiKind {
  room,
  elevator,
  restroom,
  exit,
  reception,
  help,
  stairs,
  entrance,
}

extension IndoorPoiKindX on IndoorPoiKind {
  String get label => switch (this) {
    IndoorPoiKind.room => 'Room',
    IndoorPoiKind.elevator => 'Elevator / lift',
    IndoorPoiKind.restroom => 'Accessible restroom',
    IndoorPoiKind.exit => 'Emergency exit',
    IndoorPoiKind.reception => 'Reception',
    IndoorPoiKind.help => 'Help point',
    IndoorPoiKind.stairs => 'Stairs',
    IndoorPoiKind.entrance => 'Entrance',
  };

  IconData get icon => switch (this) {
    IndoorPoiKind.room => Icons.meeting_room_outlined,
    IndoorPoiKind.elevator => Icons.elevator_rounded,
    IndoorPoiKind.restroom => Icons.wc_rounded,
    IndoorPoiKind.exit => Icons.exit_to_app_rounded,
    IndoorPoiKind.reception => Icons.desk_rounded,
    IndoorPoiKind.help => Icons.support_agent_rounded,
    IndoorPoiKind.stairs => Icons.stairs_rounded,
    IndoorPoiKind.entrance => Icons.login_rounded,
  };

  Color get color => switch (this) {
    IndoorPoiKind.room => const Color(0xFF006D44),
    IndoorPoiKind.elevator => const Color(0xFF2563EB),
    IndoorPoiKind.restroom => const Color(0xFF0D9488),
    IndoorPoiKind.exit => const Color(0xFFE11D48),
    IndoorPoiKind.reception => const Color(0xFF7C3AED),
    IndoorPoiKind.help => const Color(0xFFF59E0B),
    IndoorPoiKind.stairs => const Color(0xFF6B7280),
    IndoorPoiKind.entrance => const Color(0xFF006D44),
  };
}

/// A navigable node on a floor (room, elevator bank, restroom, exit, etc.).
class IndoorNode {
  const IndoorNode({
    required this.id,
    required this.floorId,
    required this.name,
    required this.kind,
    required this.x,
    required this.y,
    this.accessible = true,
    this.elevatorBankId,
    this.notes = '',
  });

  final String id;
  final String floorId;
  final String name;
  final IndoorPoiKind kind;

  /// Normalized plan coordinates 0–1 within the floor canvas.
  final double x;
  final double y;

  /// Wheelchair / step-free reachable.
  final bool accessible;

  /// Shared id linking elevator landings across floors.
  final String? elevatorBankId;
  final String notes;
}

/// Undirected walkable connection between two nodes (same floor or via lift).
class IndoorEdge {
  const IndoorEdge({
    required this.fromId,
    required this.toId,
    required this.meters,
    this.viaElevator = false,
    this.accessible = true,
  });

  final String fromId;
  final String toId;
  final double meters;
  final bool viaElevator;
  final bool accessible;
}

class IndoorFloor {
  const IndoorFloor({
    required this.id,
    required this.label,
    required this.level,
    this.subtitle = '',
  });

  final String id;
  final String label;

  /// Sort key: lobby = 0, floor 1 = 1, basement = -1, etc.
  final int level;
  final String subtitle;
}

class IndoorVenue {
  const IndoorVenue({
    required this.id,
    required this.name,
    required this.placeId,
    required this.address,
    required this.floors,
    required this.nodes,
    required this.edges,
    this.description = '',
  });

  final String id;
  final String name;

  /// Linked outdoor [AccessiblePlace.id] when available.
  final String placeId;
  final String address;
  final String description;
  final List<IndoorFloor> floors;
  final List<IndoorNode> nodes;
  final List<IndoorEdge> edges;

  IndoorFloor? floorById(String id) {
    for (final f in floors) {
      if (f.id == id) return f;
    }
    return null;
  }

  IndoorNode? nodeById(String id) {
    for (final n in nodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  List<IndoorNode> nodesOnFloor(String floorId) =>
      [for (final n in nodes) if (n.floorId == floorId) n];

  List<IndoorNode> nodesOfKind(IndoorPoiKind kind, {String? floorId}) => [
        for (final n in nodes)
          if (n.kind == kind && (floorId == null || n.floorId == floorId)) n,
      ];
}

class IndoorRouteStep {
  const IndoorRouteStep({
    required this.node,
    required this.instruction,
    required this.meters,
  });

  final IndoorNode node;
  final String instruction;
  final double meters;
}

class IndoorRoute {
  const IndoorRoute({
    required this.nodes,
    required this.steps,
    required this.meters,
    required this.accessible,
  });

  final List<IndoorNode> nodes;
  final List<IndoorRouteStep> steps;
  final double meters;
  final bool accessible;

  String get distanceLabel {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}
