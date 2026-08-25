import 'package:url_launcher/url_launcher.dart';

import 'emergency_actions.dart';

/// Opens phone / website links for place contact rows.
class PlaceContactActions {
  static Future<bool> call(String phone) => EmergencyActions.call(phone);

  static Future<bool> openWebsite(String raw) async {
    final uri = normalizeWebsite(raw);
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Accepts bare domains (`example.com`) or full URLs.
  static Uri? normalizeWebsite(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    final withScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:').hasMatch(t)
        ? t
        : 'https://$t';
    final uri = Uri.tryParse(withScheme);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return uri;
  }
}
