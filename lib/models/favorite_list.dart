import 'package:cloud_firestore/cloud_firestore.dart';

/// A named list of saved places (`users/{uid}/favoriteLists/{id}`).
class FavoriteList {
  const FavoriteList({
    required this.id,
    required this.name,
    required this.placeIds,
    this.category = generalCategory,
    this.sharedWithCareCircle = false,
    this.createdAt,
    this.updatedAt,
  });

  static const defaultId = 'saved';
  static const defaultName = 'Saved';
  static const generalCategory = 'general';

  /// Accessibility Passport–aligned list categories.
  static const categoryIds = <String>[
    generalCategory,
    'wheelchair',
    'visual',
    'hearing',
    'cognitive',
  ];

  static const categoryLabels = <String, String>{
    generalCategory: 'General',
    'wheelchair': 'Wheelchair',
    'visual': 'Visual',
    'hearing': 'Hearing',
    'cognitive': 'Cognitive',
  };

  static String categoryLabel(String id) =>
      categoryLabels[id] ?? id;

  final String id;
  final String name;
  final List<String> placeIds;

  /// One of [categoryIds] — groups lists by accessibility need.
  final String category;
  final bool sharedWithCareCircle;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  int get count => placeIds.length;

  bool get isCategoryPreset => id.startsWith('cat-');

  factory FavoriteList.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final created = d['createdAt'];
    final updated = d['updatedAt'];
    final cat = (d['category'] as String?)?.trim() ?? generalCategory;
    return FavoriteList(
      id: doc.id,
      name: (d['name'] as String?)?.trim().isNotEmpty == true
          ? (d['name'] as String).trim()
          : defaultName,
      placeIds: List<String>.from(d['placeIds'] as List? ?? const []),
      category: categoryIds.contains(cat) ? cat : generalCategory,
      sharedWithCareCircle: d['sharedWithCareCircle'] == true,
      createdAt: created is Timestamp ? created.toDate() : null,
      updatedAt: updated is Timestamp ? updated.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'placeIds': placeIds,
        'category': category,
        'sharedWithCareCircle': sharedWithCareCircle,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
