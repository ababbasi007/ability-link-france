/// Recent map search strings stored on `users/{uid}.mapPrefs.recentSearches`.
const mapSearchHistoryMaxItems = 8;

List<String> parseRecentMapSearches(Object? mapPrefs) {
  if (mapPrefs is! Map) return const [];
  final raw = mapPrefs['recentSearches'];
  if (raw is! List) return const [];
  final out = <String>[];
  for (final item in raw) {
    if (item is! String) continue;
    final t = item.trim();
    if (t.isEmpty) continue;
    if (out.any((e) => e.toLowerCase() == t.toLowerCase())) continue;
    out.add(t);
    if (out.length >= mapSearchHistoryMaxItems) break;
  }
  return out;
}

List<String> pushRecentMapSearch(
  List<String> current,
  String query, {
  int maxItems = mapSearchHistoryMaxItems,
}) {
  final t = query.trim();
  if (t.isEmpty) return List<String>.from(current);
  final lower = t.toLowerCase();
  final next = [
    t,
    ...current.where((e) => e.toLowerCase() != lower),
  ];
  if (next.length > maxItems) next.removeRange(maxItems, next.length);
  return next;
}
