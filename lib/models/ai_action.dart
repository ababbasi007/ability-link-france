/// Structured CTA attached to an AI assistant reply.
class AiAction {
  const AiAction({
    required this.id,
    required this.label,
    required this.type,
    this.payload = const {},
  });

  final String id;
  final String label;

  /// See [AiActionType] string values.
  final String type;
  final Map<String, String> payload;

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'type': type,
    'payload': payload,
  };

  factory AiAction.fromMap(Map<String, dynamic> data) {
    final raw = data['payload'];
    final payload = <String, String>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (k != null) payload['$k'] = '$v';
      });
    }
    return AiAction(
      id: (data['id'] as String?) ?? '',
      label: (data['label'] as String?) ?? 'Open',
      type: (data['type'] as String?) ?? '',
      payload: payload,
    );
  }
}

abstract final class AiActionType {
  static const providers = 'providers';
  static const providerProfile = 'providerProfile';
  static const bookProvider = 'bookProvider';
  static const travel = 'travel';
  static const education = 'education';
  static const benefits = 'benefits';
  static const map = 'map';
  static const search = 'search';
  static const stepFreeRoute = 'stepFreeRoute';
  static const telehealth = 'telehealth';
  static const rehab = 'rehab';
  static const caregiverHub = 'caregiverHub';
  static const appointments = 'appointments';
  static const emergency = 'emergency';
  static const rights = 'rights';
  static const transport = 'transport';
}
