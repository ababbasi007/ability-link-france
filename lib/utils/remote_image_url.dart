/// Remaps known-broken remote image URLs so NetworkImage does not 404.
String sanitizeRemoteImageUrl(String url) {
  if (url.isEmpty) return url;
  // Removed / expired Unsplash assets still stored on older Firestore seed docs.
  const broken = {
    'https://images.unsplash.com/photo-1582750433449-648ed127bb48?w=400&h=400&fit=crop':
        'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1582750433449-648ed127bb48':
        'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400&h=400&fit=crop',
  };
  final exact = broken[url];
  if (exact != null) return exact;
  if (url.contains('photo-1582750433449-648ed127bb48')) {
    return 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400&h=400&fit=crop';
  }
  return url;
}
