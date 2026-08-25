/// A walkthrough or navigation video attached to a place listing.
class PlaceVideoSection {
  const PlaceVideoSection({
    required this.url,
    required this.label,
    this.kind = 'walkthrough',
    this.thumbnailUrl = '',
    this.durationSeconds = 0,
  });

  /// `walkthrough` | `navigation`
  final String kind;
  final String url;
  final String label;
  final String thumbnailUrl;
  final int durationSeconds;

  bool get isNavigation => kind == 'navigation';

  Map<String, dynamic> toMap() => {
    'url': url,
    'label': label,
    'kind': kind,
    if (thumbnailUrl.isNotEmpty) 'thumbnailUrl': thumbnailUrl,
    if (durationSeconds > 0) 'durationSeconds': durationSeconds,
  };

  factory PlaceVideoSection.fromMap(Map<String, dynamic> m) {
    return PlaceVideoSection(
      url: (m['url'] as String?) ?? '',
      label: (m['label'] as String?) ?? 'Venue video',
      kind: (m['kind'] as String?) ?? 'walkthrough',
      thumbnailUrl: (m['thumbnailUrl'] as String?) ?? '',
      durationSeconds: (m['durationSeconds'] as num?)?.toInt() ?? 0,
    );
  }
}
