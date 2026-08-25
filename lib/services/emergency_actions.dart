import 'package:url_launcher/url_launcher.dart';

/// Phone, SMS, and maps launchers used by Emergency SOS.
class EmergencyActions {
  static String digits(String raw) => raw.replaceAll(RegExp(r'[^\d+]'), '');

  static Future<bool> call(String number) async {
    final n = digits(number);
    if (n.isEmpty) return false;
    final uri = Uri(scheme: 'tel', path: n);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> sms({
    required String body,
    List<String> phones = const [],
  }) async {
    final cleaned = phones.map(digits).where((p) => p.isNotEmpty).toList();
    final uri = cleaned.isEmpty
        ? Uri(scheme: 'sms', queryParameters: {'body': body})
        : Uri(
            scheme: 'sms',
            path: cleaned.join(','),
            queryParameters: {'body': body},
          );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> maps({
    required double lat,
    required double lng,
    String label = '',
  }) async {
    final q = label.isEmpty ? '$lat,$lng' : '$lat,$lng ($label)';
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q)}',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
