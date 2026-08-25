import 'dart:collection';

import '../data/indoor_venues.dart';
import '../models/indoor_venue.dart';

/// Indoor multi-floor navigation over seeded venue graphs.
class IndoorNavigationService {
  IndoorNavigationService({List<IndoorVenue>? venues})
    : _venues = List.unmodifiable(venues ?? seedIndoorVenues);

  final List<IndoorVenue> _venues;

  List<IndoorVenue> get venues => _venues;

  IndoorVenue? venueById(String id) {
    for (final v in _venues) {
      if (v.id == id || v.placeId == id) return v;
    }
    return null;
  }

  IndoorVenue? venueForPlace(String placeId) => indoorVenueForPlace(placeId);

  /// Shortest accessible path (Dijkstra). Stairs edges skipped when
  /// [preferAccessible] is true.
  IndoorRoute? route({
    required IndoorVenue venue,
    required String fromNodeId,
    required String toNodeId,
    bool preferAccessible = true,
  }) {
    final from = venue.nodeById(fromNodeId);
    final to = venue.nodeById(toNodeId);
    if (from == null || to == null) return null;
    if (from.id == to.id) {
      return IndoorRoute(
        nodes: [from],
        steps: [
          IndoorRouteStep(
            node: from,
            instruction: 'You are at ${from.name}',
            meters: 0,
          ),
        ],
        meters: 0,
        accessible: from.accessible,
      );
    }

    final adj = <String, List<(String, IndoorEdge)>>{};
    for (final e in venue.edges) {
      if (preferAccessible && !e.accessible) continue;
      adj.putIfAbsent(e.fromId, () => []).add((e.toId, e));
      adj.putIfAbsent(e.toId, () => []).add((e.fromId, e));
    }

    final dist = <String, double>{for (final n in venue.nodes) n.id: double.infinity};
    final prev = <String, String?>{};
    final prevEdge = <String, IndoorEdge?>{};
    dist[from.id] = 0;

    final pq = SplayTreeSet<(double, String)>((a, b) {
      final c = a.$1.compareTo(b.$1);
      if (c != 0) return c;
      return a.$2.compareTo(b.$2);
    });
    pq.add((0, from.id));

    while (pq.isNotEmpty) {
      final current = pq.first;
      pq.remove(current);
      final u = current.$2;
      final d = current.$1;
      if (d != dist[u]) continue;
      if (u == to.id) break;
      for (final entry in adj[u] ?? const <(String, IndoorEdge)>[]) {
        final v = entry.$1;
        final edge = entry.$2;
        final nd = d + edge.meters;
        if (nd < (dist[v] ?? double.infinity)) {
          dist[v] = nd;
          prev[v] = u;
          prevEdge[v] = edge;
          pq.add((nd, v));
        }
      }
    }

    if ((dist[to.id] ?? double.infinity).isInfinite) {
      // Retry without accessibility filter if no path.
      if (preferAccessible) {
        return route(
          venue: venue,
          fromNodeId: fromNodeId,
          toNodeId: toNodeId,
          preferAccessible: false,
        );
      }
      return null;
    }

    final pathIds = <String>[];
    String? cur = to.id;
    while (cur != null) {
      pathIds.add(cur);
      cur = prev[cur];
    }
    final ids = pathIds.reversed.toList();
    final nodes = <IndoorNode>[
      for (final id in ids)
        if (venue.nodeById(id) != null) venue.nodeById(id)!,
    ];

    final steps = <IndoorRouteStep>[];
    var accessible = true;
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (!node.accessible) accessible = false;
      if (i == 0) {
        steps.add(
          IndoorRouteStep(
            node: node,
            instruction: 'Start at ${node.name}',
            meters: 0,
          ),
        );
        continue;
      }
      final edge = prevEdge[node.id];
      final meters = edge?.meters ?? 0;
      final fromNode = nodes[i - 1];
      String instruction;
      if (edge?.viaElevator == true) {
        final fromFloor = venue.floorById(fromNode.floorId)?.label ?? '';
        final toFloor = venue.floorById(node.floorId)?.label ?? '';
        instruction = 'Take elevator from $fromFloor to $toFloor';
      } else if (node.kind == IndoorPoiKind.exit) {
        instruction = 'Continue to emergency exit · ${node.name}';
      } else if (node.kind == IndoorPoiKind.restroom) {
        instruction = 'Arrive at ${node.name}';
      } else {
        instruction = 'Go to ${node.name}';
      }
      steps.add(
        IndoorRouteStep(node: node, instruction: instruction, meters: meters),
      );
    }

    return IndoorRoute(
      nodes: nodes,
      steps: steps,
      meters: dist[to.id] ?? 0,
      accessible: accessible && preferAccessible,
    );
  }

  /// Nearest emergency exit from [fromNodeId] (accessible preferred).
  IndoorRoute? evacuate({
    required IndoorVenue venue,
    required String fromNodeId,
    bool preferAccessible = true,
  }) {
    IndoorRoute? best;
    for (final exit in venue.nodesOfKind(IndoorPoiKind.exit)) {
      final r = route(
        venue: venue,
        fromNodeId: fromNodeId,
        toNodeId: exit.id,
        preferAccessible: preferAccessible,
      );
      if (r == null) continue;
      if (best == null || r.meters < best.meters) best = r;
    }
    return best;
  }
}
