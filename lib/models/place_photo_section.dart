/// A labeled accessibility photo on a place listing.
class PlacePhotoSection {
  const PlacePhotoSection({
    required this.url,
    required this.label,
    this.source = 'listing',
  });

  final String url;
  final String label;
  /// listing | audit | community
  final String source;

  Map<String, dynamic> toMap() => {
    'url': url,
    'label': label,
    if (source.isNotEmpty) 'source': source,
  };

  factory PlacePhotoSection.fromMap(Map<String, dynamic> m) => PlacePhotoSection(
    url: (m['url'] as String?) ?? '',
    label: (m['label'] as String?) ?? 'Accessibility photo',
    source: (m['source'] as String?) ?? 'listing',
  );
}
