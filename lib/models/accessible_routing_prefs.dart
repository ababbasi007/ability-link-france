import '../models/user_profile.dart';

/// Preferred primary travel mode for routing / personalization.
enum PreferredTransportMode {
  walk,
  wheelchair,
  transit,
}

extension PreferredTransportModeX on PreferredTransportMode {
  String get id => name;

  String get label => switch (this) {
        PreferredTransportMode.walk => 'Walking',
        PreferredTransportMode.wheelchair => 'Wheelchair',
        PreferredTransportMode.transit => 'Accessible transit',
      };

  static PreferredTransportMode fromId(String? raw) {
    switch (raw) {
      case 'wheelchair':
        return PreferredTransportMode.wheelchair;
      case 'transit':
        return PreferredTransportMode.transit;
      default:
        return PreferredTransportMode.walk;
    }
  }
}

/// User preferences for accessibility-aware walking / wheelchair routing.
class AccessibleRoutingPrefs {
  const AccessibleRoutingPrefs({
    this.preferredTransportMode = PreferredTransportMode.walk,
    this.wheelchairFriendly = true,
    this.avoidStairs = true,
    this.preferElevators = true,
    this.avoidSteepSlopes = true,
    this.avoidRoughTerrain = false,
    this.preferQuiet = false,
    this.preferSafe = true,
  });

  /// Primary travel mode preference (walk / wheelchair / transit).
  final PreferredTransportMode preferredTransportMode;

  /// Prefer a dedicated wheelchair-friendly graph when available (ORS).
  final bool wheelchairFriendly;

  /// Avoid stairs / steps when the engine supports it.
  final bool avoidStairs;

  /// Bias toward elevators / step-free venues as waypoints.
  final bool preferElevators;

  /// Cap maximum incline (ORS wheelchair restrictions).
  final bool avoidSteepSlopes;

  /// Prefer smoother surfaces (avoid cobbles / gravel when ORS available).
  final bool avoidRoughTerrain;

  /// Soft preference for quiet-tagged places along the route.
  final bool preferQuiet;

  /// Soft preference for high accessibility-score places as vias.
  final bool preferSafe;

  static const defaults = AccessibleRoutingPrefs();

  /// Seeds prefs from Passport mobility aid / elevator need.
  factory AccessibleRoutingPrefs.fromPassport(UserProfile? profile) {
    if (profile == null) return defaults;
    final aid = profile.mobilityAid.toLowerCase();
    final usesWheel = aid.contains('wheelchair') ||
        aid.contains('scooter') ||
        aid.contains('mobility');
    final needElevator = profile.accessibility['needElevator'] == true;
    return AccessibleRoutingPrefs(
      preferredTransportMode: usesWheel
          ? PreferredTransportMode.wheelchair
          : PreferredTransportMode.walk,
      wheelchairFriendly: usesWheel || needElevator,
      avoidStairs: usesWheel || needElevator || aid.isNotEmpty,
      preferElevators: usesWheel || needElevator,
      avoidSteepSlopes: usesWheel,
      avoidRoughTerrain: usesWheel,
      preferQuiet: profile.accessibilityProfiles
          .any((p) => p.toLowerCase().contains('sensory')),
      preferSafe: true,
    );
  }

  AccessibleRoutingPrefs copyWith({
    PreferredTransportMode? preferredTransportMode,
    bool? wheelchairFriendly,
    bool? avoidStairs,
    bool? preferElevators,
    bool? avoidSteepSlopes,
    bool? avoidRoughTerrain,
    bool? preferQuiet,
    bool? preferSafe,
  }) {
    final mode = preferredTransportMode ?? this.preferredTransportMode;
    var wheel = wheelchairFriendly ?? this.wheelchairFriendly;
    if (preferredTransportMode != null) {
      if (mode == PreferredTransportMode.wheelchair) {
        wheel = true;
      } else if (mode == PreferredTransportMode.walk &&
          wheelchairFriendly == null) {
        wheel = false;
      }
    }
    return AccessibleRoutingPrefs(
      preferredTransportMode: mode,
      wheelchairFriendly: wheel,
      avoidStairs: avoidStairs ?? this.avoidStairs,
      preferElevators: preferElevators ?? this.preferElevators,
      avoidSteepSlopes: avoidSteepSlopes ?? this.avoidSteepSlopes,
      avoidRoughTerrain: avoidRoughTerrain ?? this.avoidRoughTerrain,
      preferQuiet: preferQuiet ?? this.preferQuiet,
      preferSafe: preferSafe ?? this.preferSafe,
    );
  }

  Map<String, dynamic> toMap() => {
        'preferredTransportMode': preferredTransportMode.id,
        'wheelchairFriendly': wheelchairFriendly,
        'avoidStairs': avoidStairs,
        'preferElevators': preferElevators,
        'avoidSteepSlopes': avoidSteepSlopes,
        'avoidRoughTerrain': avoidRoughTerrain,
        'preferQuiet': preferQuiet,
        'preferSafe': preferSafe,
      };

  factory AccessibleRoutingPrefs.fromMap(Map<String, dynamic>? raw) {
    if (raw == null) return defaults;
    bool flag(String k, bool fallback) {
      final v = raw[k];
      if (v is bool) return v;
      return fallback;
    }

    return AccessibleRoutingPrefs(
      preferredTransportMode: PreferredTransportModeX.fromId(
        raw['preferredTransportMode'] as String?,
      ),
      wheelchairFriendly: flag('wheelchairFriendly', true),
      avoidStairs: flag('avoidStairs', true),
      preferElevators: flag('preferElevators', true),
      avoidSteepSlopes: flag('avoidSteepSlopes', true),
      avoidRoughTerrain: flag('avoidRoughTerrain', false),
      preferQuiet: flag('preferQuiet', false),
      preferSafe: flag('preferSafe', true),
    );
  }

  List<String> get activeLabels {
    final out = <String>[preferredTransportMode.label];
    if (wheelchairFriendly) out.add('Wheelchair');
    if (avoidStairs) out.add('No stairs');
    if (preferElevators) out.add('Elevators');
    if (avoidSteepSlopes) out.add('Gentle slopes');
    if (avoidRoughTerrain) out.add('Smooth surfaces');
    if (preferQuiet) out.add('Quiet');
    if (preferSafe) out.add('Safer');
    return out;
  }

  bool get wantsAccessibleProfile =>
      preferredTransportMode == PreferredTransportMode.wheelchair ||
      wheelchairFriendly ||
      avoidStairs ||
      preferElevators ||
      avoidSteepSlopes ||
      avoidRoughTerrain;
}
