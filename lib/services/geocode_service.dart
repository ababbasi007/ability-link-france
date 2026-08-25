import 'dart:convert';
import 'dart:io';

class GeocodeResult {
  const GeocodeResult({
    required this.lat,
    required this.lng,
    required this.displayName,
  });

  final double lat;
  final double lng;
  final String displayName;
}

/// Lightweight address/landmark geocoding via OpenStreetMap Nominatim.
class GeocodeService {
  Future<GeocodeResult?> searchOne(
    String query, {
    String? countryCode,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return null;

    final params = <String, String>{
      'q': q,
      'format': 'jsonv2',
      'limit': '1',
      if (countryCode != null && countryCode.trim().isNotEmpty)
        'countrycodes': countryCode.trim().toLowerCase(),
    };
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', params);

    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.userAgentHeader, 'ability-link/1.0');
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final res = await req.close();
      if (res.statusCode < 200 || res.statusCode >= 300) {
        return null;
      }
      final body = await utf8.decodeStream(res);
      final data = jsonDecode(body);
      if (data is! List || data.isEmpty) return null;
      final first = data.first;
      if (first is! Map) return null;

      final lat = double.tryParse('${first['lat'] ?? ''}');
      final lng = double.tryParse('${first['lon'] ?? ''}');
      final name = '${first['display_name'] ?? ''}'.trim();
      if (lat == null || lng == null) return null;

      return GeocodeResult(
        lat: lat,
        lng: lng,
        displayName: name.isEmpty ? q : name,
      );
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
