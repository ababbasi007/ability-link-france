import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/accessible_service.dart';
import '../models/favorite_list.dart';
import '../models/place.dart';
import '../models/place_barrier_report.dart';
import '../models/place_photo_section.dart';
import '../models/place_video_section.dart';
import 'local_place_cache.dart';
import 'seed_write_guard.dart';

class PlacesService {
  PlacesService({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  }) : _db = db ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _places =>
      _db.collection('places');

  /// Safety cap for client catalog watches. Demo catalogs are tens of docs;
  /// this stops a future dump from downloading the whole collection.
  static const watchLimit = 250;

  Stream<List<AccessiblePlace>> watchPlaces({int limit = watchLimit}) {
    return _places
        .orderBy('score', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) {
            final remote = snap.docs
                .map(AccessiblePlace.fromDoc)
                .where((p) => !p.hidden)
                .toList();
            return mergeWithSeedCatalog(remote);
          },
        );
  }

  /// Prefer Firestore docs, then fill any missing demo/seed listings (e.g. new
  /// Abbottabad test places) so the map works even when seeding is blocked.
  static List<AccessiblePlace> mergeWithSeedCatalog(
    List<AccessiblePlace> remote,
  ) {
    if (remote.isEmpty) {
      return seedPlaces.where((p) => !p.hidden).toList();
    }
    final byId = <String, AccessiblePlace>{
      for (final p in remote) p.id: p,
    };
    for (final p in seedPlaces) {
      if (p.hidden || byId.containsKey(p.id)) continue;
      byId[p.id] = p;
    }
    return byId.values.toList();
  }

  /// Default discovery origin (Abbottabad testing area).
  static const defaultOriginLat = 34.1688;
  static const defaultOriginLng = 73.2215;

  static const catalogVersion = 4;

  /// Client-side search over [places] (fine for current demo volume).
  List<AccessiblePlace> search(
    List<AccessiblePlace> places, {
    String query = '',
    String need = 'all', // all | wheelchair | visual | hearing | cognitive
    Set<String> amenities = const {},
    bool openNowOnly = false,
    bool alwaysOpenOnly = false,
    bool verifiedOnly = false,
    bool fullyAccessibleOnly = false,
    double? maxKm,
    double originLat = defaultOriginLat,
    double originLng = defaultOriginLng,
    PlaceSort sort = PlaceSort.relevance,
  }) {
    final now = DateTime.now();
    var results = places.where((p) {
      if (!p.matchesQuery(query)) return false;
      if (need != 'all') {
        final label = switch (need) {
          'wheelchair' => 'Wheelchair',
          'visual' => 'Visual',
          'hearing' => 'Hearing',
          'cognitive' => 'Cognitive',
          _ => 'All Places',
        };
        if (!p.matchesFilter(label)) return false;
      }
      if (!p.matchesAmenities(amenities)) return false;
      if (openNowOnly && !p.isOpenNow(now: now)) return false;
      if (alwaysOpenOnly && !p.isAlwaysOpen) return false;
      if (verifiedOnly && !p.verified) return false;
      if (fullyAccessibleOnly && !p.isFullyAccessible()) return false;
      if (maxKm != null && p.distanceKm(originLat, originLng) > maxKm) {
        return false;
      }
      return true;
    }).toList();

    switch (sort) {
      case PlaceSort.distance:
        results.sort(
          (a, b) => a
              .distanceKm(originLat, originLng)
              .compareTo(b.distanceKm(originLat, originLng)),
        );
      case PlaceSort.rating:
        results.sort((a, b) => b.rating.compareTo(a.rating));
      case PlaceSort.relevance:
        if (query.trim().isEmpty) {
          results.sort((a, b) => b.score.compareTo(a.score));
        } else {
          final q = query.trim().toLowerCase();
          results.sort((a, b) {
            final aExact = a.name.toLowerCase().startsWith(q) ? 0 : 1;
            final bExact = b.name.toLowerCase().startsWith(q) ? 0 : 1;
            if (aExact != bExact) return aExact.compareTo(bExact);
            return b.score.compareTo(a.score);
          });
        }
    }
    return results;
  }

  Future<AccessiblePlace?> getPlace(String id) async {
    final doc = await _places.doc(id).get();
    if (!doc.exists) return null;
    return AccessiblePlace.fromDoc(doc);
  }

  /// Uploads an accessibility certificate / inspection report for a venue.
  Future<String> uploadAccessibilityCertificate({
    required String placeId,
    required Uint8List bytes,
    required String fileName,
    DateTime? inspectionDate,
    bool markGovernmentCertified = true,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sign in to upload a certificate');
    if (placeId.trim().isEmpty) throw StateError('Place required');
    if (bytes.isEmpty) throw StateError('Empty file');
    if (bytes.lengthInBytes > 12 * 1024 * 1024) {
      throw StateError('File too large (max 12 MB)');
    }

    final safeName = fileName.trim().isEmpty
        ? 'certificate.pdf'
        : fileName.trim().replaceAll(RegExp(r'[^\w.\-]+'), '_');
    final path =
        'place_certificates/$placeId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final ref = _storage.ref(path);
    await ref.putData(
      bytes,
      SettableMetadata(contentType: _contentTypeFor(safeName)),
    );
    final url = await ref.getDownloadURL();
    final date = inspectionDate ?? DateTime.now();
    await _places.doc(placeId).set({
      'certificateUrl': url,
      'inspectionDate': Timestamp.fromDate(date),
      if (markGovernmentCertified) 'governmentCertified': true,
      'certificateUploadedBy': uid,
      'certificateUploadedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return url;
  }

  static String _contentTypeFor(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'application/pdf';
  }

  /// Fetch a list of places by ids (uses `whereIn`, chunked to Firestore limits).
  Future<List<AccessiblePlace>> fetchPlacesByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final unique = ids.toSet().toList();
    final results = <AccessiblePlace>[];

    for (var i = 0; i < unique.length; i += 10) {
      final chunk = unique.sublist(i, (i + 10).clamp(0, unique.length));
      final snap = await _places
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      results.addAll(
        snap.docs
            .map(AccessiblePlace.fromDoc)
            .where((p) => !p.hidden),
      );
    }

    return results;
  }

  Future<void> toggleFavorite(String placeId, {String? listId}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Sign in to save favorites');
    }
    final targetListId = listId ?? FavoriteList.defaultId;
    await _ensureDefaultFavoriteList(uid);
    final listRef = _db
        .collection('users')
        .doc(uid)
        .collection('favoriteLists')
        .doc(targetListId);
    final legacyRef = _db
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(placeId);

    var removed = false;
    await _db.runTransaction((tx) async {
      final listSnap = await tx.get(listRef);
      final data = listSnap.data() ?? {};
      final ids = List<String>.from(data['placeIds'] as List? ?? const []);
      final exists = ids.contains(placeId);
      removed = exists;
      if (exists) {
        ids.remove(placeId);
      } else {
        ids.add(placeId);
      }
      tx.set(listRef, {
        'name': (data['name'] as String?) ?? FavoriteList.defaultName,
        'placeIds': ids,
        'updatedAt': FieldValue.serverTimestamp(),
        if (!listSnap.exists) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (exists) {
        tx.delete(legacyRef);
      } else {
        tx.set(legacyRef, {
          'placeId': placeId,
          'listId': targetListId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
    if (removed) {
      final stillSaved = await _isPlaceInAnyList(uid, placeId);
      if (stillSaved) {
        await legacyRef.set({
          'placeId': placeId,
          'listId': targetListId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  Future<void> addToFavoriteList({
    required String listId,
    required String placeId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sign in to save favorites');
    await _ensureDefaultFavoriteList(uid);
    final listRef = _db
        .collection('users')
        .doc(uid)
        .collection('favoriteLists')
        .doc(listId);
    final legacyRef = _db
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(placeId);
    await _db.runTransaction((tx) async {
      final listSnap = await tx.get(listRef);
      if (!listSnap.exists) throw StateError('List not found');
      final ids = List<String>.from(
        listSnap.data()?['placeIds'] as List? ?? const [],
      );
      if (!ids.contains(placeId)) ids.add(placeId);
      tx.set(listRef, {
        'placeIds': ids,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      tx.set(legacyRef, {
        'placeId': placeId,
        'listId': listId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> removeFromFavoriteList({
    required String listId,
    required String placeId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sign in to save favorites');
    final listRef = _db
        .collection('users')
        .doc(uid)
        .collection('favoriteLists')
        .doc(listId);
    final legacyRef = _db
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(placeId);
    await _db.runTransaction((tx) async {
      final listSnap = await tx.get(listRef);
      if (!listSnap.exists) return;
      final ids = List<String>.from(
        listSnap.data()?['placeIds'] as List? ?? const [],
      );
      ids.remove(placeId);
      tx.set(listRef, {
        'placeIds': ids,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
    final stillSaved = await _isPlaceInAnyList(uid, placeId);
    if (!stillSaved) await legacyRef.delete();
  }

  Future<bool> _isPlaceInAnyList(String uid, String placeId) async {
    final lists = await _db
        .collection('users')
        .doc(uid)
        .collection('favoriteLists')
        .get();
    for (final doc in lists.docs) {
      final ids = List<String>.from(doc.data()['placeIds'] as List? ?? const []);
      if (ids.contains(placeId)) return true;
    }
    return false;
  }

  Future<String> createFavoriteList(
    String name, {
    String category = FavoriteList.generalCategory,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sign in to create a list');
    final cleaned = name.trim();
    if (cleaned.isEmpty) throw StateError('List name cannot be empty');
    final cat = FavoriteList.categoryIds.contains(category)
        ? category
        : FavoriteList.generalCategory;
    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('favoriteLists')
        .doc();
    await ref.set({
      'name': cleaned,
      'placeIds': <String>[],
      'category': cat,
      'sharedWithCareCircle': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> renameFavoriteList({
    required String listId,
    required String name,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sign in to rename a list');
    final cleaned = name.trim();
    if (cleaned.isEmpty) throw StateError('List name cannot be empty');
    await _db
        .collection('users')
        .doc(uid)
        .collection('favoriteLists')
        .doc(listId)
        .set({
      'name': cleaned,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteFavoriteList(String listId) async {
    if (listId == FavoriteList.defaultId) {
      throw StateError('The default Saved list cannot be deleted');
    }
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sign in to delete a list');
    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('favoriteLists')
        .doc(listId);
    final snap = await ref.get();
    if (!snap.exists) return;
    final ids = List<String>.from(snap.data()?['placeIds'] as List? ?? const []);
    await ref.delete();
    for (final placeId in ids) {
      final stillSaved = await _isPlaceInAnyList(uid, placeId);
      if (!stillSaved) {
        await _db
            .collection('users')
            .doc(uid)
            .collection('favorites')
            .doc(placeId)
            .delete();
      }
    }
  }

  Stream<List<FavoriteList>> watchFavoriteLists() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _db
        .collection('users')
        .doc(uid)
        .collection('favoriteLists')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) {
          final lists = snap.docs.map(FavoriteList.fromDoc).toList();
          lists.sort((a, b) {
            if (a.id == FavoriteList.defaultId) return -1;
            if (b.id == FavoriteList.defaultId) return 1;
            final aTime = a.updatedAt ?? a.createdAt ?? DateTime(1970);
            final bTime = b.updatedAt ?? b.createdAt ?? DateTime(1970);
            return bTime.compareTo(aTime);
          });
          return lists;
        });
  }

  Future<void> _ensureDefaultFavoriteList(String uid) async {
    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('favoriteLists')
        .doc(FavoriteList.defaultId);
    final snap = await ref.get();
    if (!snap.exists) {
      final legacy = await _db
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .get();
      final ids = legacy.docs.map((d) => d.id).toList();
      await ref.set({
        'name': FavoriteList.defaultName,
        'placeIds': ids,
        'category': FavoriteList.generalCategory,
        'sharedWithCareCircle': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await _ensureAccessibilityCategoryLists(uid);
  }

  /// Ensures Passport-aligned category lists (wheelchair / visual / …).
  Future<void> _ensureAccessibilityCategoryLists(String uid) async {
    final batch = _db.batch();
    var writes = 0;
    for (final cat in FavoriteList.categoryIds) {
      if (cat == FavoriteList.generalCategory) continue;
      final id = 'cat-$cat';
      final ref = _db
          .collection('users')
          .doc(uid)
          .collection('favoriteLists')
          .doc(id);
      final snap = await ref.get();
      if (snap.exists) continue;
      batch.set(ref, {
        'name': FavoriteList.categoryLabel(cat),
        'placeIds': <String>[],
        'category': cat,
        'sharedWithCareCircle': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      writes++;
    }
    if (writes > 0) await batch.commit();
  }

  Future<void> setFavoriteListShared({
    required String listId,
    required bool shared,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sign in required');

    await _db
        .collection('users')
        .doc(uid)
        .collection('favoriteLists')
        .doc(listId)
        .set({
      'sharedWithCareCircle': shared,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<Set<String>> watchFavoriteIds() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value({});
    }
    return watchFavoriteLists().map((lists) {
      final ids = <String>{};
      for (final list in lists) {
        ids.addAll(list.placeIds);
      }
      return ids;
    });
  }

  /// Fetch favorite places from Firestore and write them to the local cache
  /// so they survive offline. Call this opportunistically when online.
  Future<void> syncFavoritesToCache() async {
    try {
      final ids = await watchFavoriteIds().first;
      if (ids.isEmpty) return;
      final places = await fetchPlacesByIds(ids.toList());
      await LocalPlaceCache.instance.saveFavorites(places);
    } catch (_) {
      // Best-effort — never throw.
    }
  }

  /// Load favorites from local cache (works offline).
  Future<List<AccessiblePlace>> loadCachedFavorites() =>
      LocalPlaceCache.instance.loadFavorites();

  /// Legacy text-only report — prefer [PlaceReportService.submit].
  @Deprecated('Use PlaceReportService.submit for structured barrier reports')
  Future<void> reportIncorrect({
    required String placeId,
    required String placeName,
    required String details,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Sign in to report incorrect information');
    }
    await _db.collection('placeReports').add({
      ...placeReportDocument(
        uid: uid,
        placeId: placeId,
        placeName: placeName,
        category: PlaceBarrierCategory.incorrectInfo.id,
        details: details,
      ),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Seeds missing places and upgrades amenity tags / photos on known listings.
  Future<int> ensureSeeded() {
    return SeedWriteGuard.runOnce('places', _auth, () async {
      const catalog = 'places';
      var n = 0;
      for (final place in seedPlaces) {
        final ref = _places.doc(place.id);
        final snap = await ref.get();
        if (!snap.exists) {
          try {
            await ref.set({
              ...place.toMap(),
              'seeded': true,
              'createdAt': FieldValue.serverTimestamp(),
            });
            n++;
          } on FirebaseException catch (e) {
            if (SeedWriteGuard.isPermissionDenied(e)) {
              await SeedWriteGuard.block(catalog);
              break;
            }
            rethrow;
          }
          continue;
        }
        final version = (snap.data()?['catalogVersion'] as num?)?.toInt() ?? 0;
        if (version >= catalogVersion) continue;
        try {
          await ref.update({
            'features': place.features,
            'needs': place.needs,
            'photoUrls': place.photoUrls,
            'imageUrl': place.imageUrl,
            'description': place.description,
            'catalogVersion': catalogVersion,
            'governmentCertified': place.governmentCertified,
            if (place.inspectionDate != null)
              'inspectionDate': Timestamp.fromDate(place.inspectionDate!),
          });
          n++;
        } on FirebaseException catch (e) {
          if (SeedWriteGuard.isPermissionDenied(e)) {
            await SeedWriteGuard.block(catalog);
            break;
          }
        } catch (_) {
          // Update may require the catalog-upgrade rule; listing still usable.
        }
      }
      return n;
    });
  }
}

enum PlaceSort { relevance, distance, rating }

/// Midtown NYC demo dataset for Ability Map.
final seedPlaces = <AccessiblePlace>[
  AccessiblePlace(
    id: 'city-hospital',
    name: 'City Hospital',
    category: 'hospital',
    lat: 40.7690,
    lng: -73.9542,
    score: 95,
    rating: 4.8,
    reviewCount: 128,
    openNow: true,
    imageUrl:
        'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=800&h=480&fit=crop',
    photoUrls: const [
      'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?w=800&h=480&fit=crop',
      'https://images.unsplash.com/photo-1516549655169-df83a0774514?w=800&h=480&fit=crop',
    ],
    photoSections: const [
      PlacePhotoSection(
        url:
            'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=800&h=480&fit=crop',
        label: 'Main entrance',
        source: 'listing',
      ),
      PlacePhotoSection(
        url:
            'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?w=800&h=480&fit=crop',
        label: 'Step-free ramp',
        source: 'audit',
      ),
      PlacePhotoSection(
        url:
            'https://images.unsplash.com/photo-1516549655169-df83a0774514?w=800&h=480&fit=crop',
        label: 'Accessible restroom',
        source: 'audit',
      ),
    ],
    features: [
      'stepFree',
      'ramp',
      'elevator',
      'toilet',
      'parking',
      'braille',
      'hearing',
      'signLanguage',
      'serviceAnimal',
    ],
    needs: ['wheelchair', 'visual', 'hearing'],
    address: '525 E 68th St, New York, NY',
    phone: '+1 (212) 555-0168',
    hours: 'Open 24 hours',
    website: 'https://cityhospital.example',
    verified: true,
    governmentCertified: true,
    inspectionDate: DateTime(2024, 11, 15),
    catalogVersion: PlacesService.catalogVersion,
    peakHoursHint: 'Usually busiest 10 AM–12 PM on weekdays',
    videoSections: const [
      PlaceVideoSection(
        url:
            'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
        label: 'Main entrance walkthrough',
        kind: 'walkthrough',
        durationSeconds: 15,
      ),
      PlaceVideoSection(
        url:
            'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
        label: 'Step-free route to reception',
        kind: 'navigation',
        durationSeconds: 21,
      ),
    ],
    accessibleServices: const [
      AccessibleServiceItem(
        id: 'staff.wheelchairAssist',
        label: 'Wheelchair escort',
        description: 'Volunteers meet you at the curb and guide you inside.',
        source: 'listing',
      ),
      AccessibleServiceItem(
        id: 'signLanguage',
        label: 'Sign-language interpreter',
        description: 'Book ASL support 24 hours ahead via the main line.',
        source: 'listing',
      ),
      AccessibleServiceItem(
        id: 'formats',
        label: 'Alternate formats',
        description: 'Large-print forms and audio instructions on request.',
        source: 'listing',
      ),
    ],
    description:
        'Fully accessible hospital with step-free entrances, elevators, Braille wayfinding, ASL interpreters on request, and service-animal welcome.',
  ),
  AccessiblePlace(
    id: 'green-cafe',
    name: 'Green Cafe',
    category: 'cafe',
    lat: 40.7614,
    lng: -73.9776,
    score: 92,
    rating: 4.7,
    reviewCount: 86,
    openNow: true,
    imageUrl:
        'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=800&h=480&fit=crop',
    photoUrls: const [
      'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800&h=480&fit=crop',
    ],
    features: [
      'stepFree',
      'ramp',
      'toilet',
      'hearing',
      'serviceAnimal',
      'petFriendly',
    ],
    needs: ['wheelchair', 'hearing'],
    address: '45 Rockefeller Plaza, New York, NY',
    phone: '+1 (212) 555-0145',
    hours: 'Mon–Fri 7:00–20:00 · Sat–Sun 8:00–18:00',
    website: 'https://greencafe.example',
    verified: true,
    catalogVersion: PlacesService.catalogVersion,
    description:
        'Cafe with wheelchair access, induction loop, accessible restroom, and service-animal friendly seating.',
  ),
  AccessiblePlace(
    id: 'central-library',
    name: 'Central Library',
    category: 'library',
    lat: 40.7532,
    lng: -73.9822,
    score: 90,
    rating: 4.6,
    reviewCount: 64,
    openNow: true,
    imageUrl:
        'https://images.unsplash.com/photo-1521587760476-6c12a4b040da?w=800&h=480&fit=crop',
    photoUrls: const [
      'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=800&h=480&fit=crop',
    ],
    features: [
      'stepFree',
      'ramp',
      'elevator',
      'visual',
      'braille',
      'quiet',
      'toilet',
    ],
    needs: ['wheelchair', 'visual', 'cognitive'],
    address: '476 5th Ave, New York, NY',
    phone: '+1 (212) 555-0176',
    hours: 'Mon–Thu 10:00–20:00 · Fri–Sat 10:00–18:00 · Sun 13:00–17:00',
    website: 'https://centrallibrary.example',
    verified: true,
    catalogVersion: PlacesService.catalogVersion,
    description:
        'Public library with elevators, Braille collections, quiet sensory rooms, and large-print sections.',
  ),
  AccessiblePlace(
    id: 'grand-mall',
    name: 'Grand Mall',
    category: 'mall',
    lat: 40.7505,
    lng: -73.9934,
    score: 88,
    rating: 4.5,
    reviewCount: 210,
    openNow: true,
    imageUrl:
        'https://images.unsplash.com/photo-1519567241046-7f570eee3ce6?w=800&h=480&fit=crop',
    photoUrls: const [
      'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800&h=480&fit=crop',
    ],
    features: [
      'stepFree',
      'ramp',
      'elevator',
      'toilet',
      'parking',
      'serviceAnimal',
      'familyFriendly',
    ],
    needs: ['wheelchair'],
    address: '151 W 34th St, New York, NY',
    phone: '+1 (212) 555-0134',
    hours: 'Mon–Sat 10:00–21:00 · Sun 11:00–19:00',
    website: 'https://grandmall.example',
    verified: false,
    catalogVersion: PlacesService.catalogVersion,
    description:
        'Shopping center with accessible parking, elevators, restrooms, and service-animal welcome.',
  ),
  AccessiblePlace(
    id: 'metro-hub',
    name: 'Metro Transit Hub',
    category: 'transit',
    lat: 40.7527,
    lng: -73.9772,
    score: 86,
    rating: 4.3,
    reviewCount: 95,
    openNow: true,
    imageUrl:
        'https://images.unsplash.com/photo-1569163139394-de440dcb39c3?w=800&h=480&fit=crop',
    photoUrls: const [
      'https://images.unsplash.com/photo-1474487548417-781cb71495f3?w=800&h=480&fit=crop',
    ],
    features: [
      'elevator',
      'stepFree',
      'ramp',
      'visual',
      'braille',
      'hearing',
      'accessibleTransit',
    ],
    needs: ['wheelchair', 'visual', 'hearing'],
    address: 'Grand Central Terminal, New York, NY',
    phone: '+1 (212) 555-0100',
    hours: 'Open 24 hours · Info desk 6:00–22:00',
    website: 'https://metrohub.example',
    verified: true,
    catalogVersion: PlacesService.catalogVersion,
    description:
        'Transit hub with elevators, tactile paving, hearing loops, and accessible platforms.',
  ),
  AccessiblePlace(
    id: 'riverside-park',
    name: 'Riverside Accessible Park',
    category: 'park',
    lat: 40.7750,
    lng: -73.9880,
    score: 84,
    rating: 4.4,
    reviewCount: 41,
    openNow: true,
    imageUrl:
        'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800&h=480&fit=crop',
    photoUrls: const [
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&h=480&fit=crop',
    ],
    features: [
      'stepFree',
      'ramp',
      'toilet',
      'quiet',
      'serviceAnimal',
      'freeParking',
      'familyFriendly',
      'petFriendly',
    ],
    needs: ['wheelchair', 'cognitive'],
    address: 'Riverside Park South, New York, NY',
    phone: '+1 (212) 555-0190',
    hours: 'Daily 6:00–22:00',
    website: 'https://riversidepark.example',
    verified: false,
    catalogVersion: PlacesService.catalogVersion,
    description:
        'Park paths with step-free routes, accessible restrooms, quiet zones, and service-animal welcome.',
  ),
  AccessiblePlace(
    id: 'quiet-studio',
    name: 'Quiet Studio Loft',
    category: 'cafe',
    lat: 40.7450,
    lng: -73.9900,
    score: 87,
    rating: 4.6,
    reviewCount: 38,
    openNow: true,
    imageUrl:
        'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&h=480&fit=crop',
    photoUrls: const [
      'https://images.unsplash.com/photo-1497366754035-f200968a6e72?w=800&h=480&fit=crop',
    ],
    features: ['stepFree', 'quiet', 'toilet', 'serviceAnimal'],
    needs: ['cognitive', 'wheelchair'],
    address: '18 W 21st St, New York, NY',
    phone: '+1 (212) 555-0121',
    hours: 'Tue–Sun 9:00–18:00 · Closed Mon',
    website: 'https://quietstudio.example',
    verified: true,
    catalogVersion: PlacesService.catalogVersion,
    description:
        'Low-sensory cafe with dimmable lighting, quiet hours, and a step-free entrance.',
  ),
  AccessiblePlace(
    id: 'community-sign-center',
    name: 'Community Sign Center',
    category: 'library',
    lat: 40.7588,
    lng: -73.9680,
    score: 91,
    rating: 4.7,
    reviewCount: 52,
    openNow: true,
    imageUrl:
        'https://images.unsplash.com/photo-1573164574572-cb89e39749b4?w=800&h=480&fit=crop',
    photoUrls: const [
      'https://images.unsplash.com/photo-1524178232363-1fb2b075b655?w=800&h=480&fit=crop',
    ],
    features: [
      'stepFree',
      'hearing',
      'signLanguage',
      'visual',
      'elevator',
      'toilet',
    ],
    needs: ['hearing', 'visual', 'wheelchair'],
    address: '220 E 51st St, New York, NY',
    phone: '+1 (212) 555-0151',
    hours: 'Mon–Fri 9:00–17:00 · Sat 10:00–14:00',
    website: 'https://signcenter.example',
    verified: true,
    catalogVersion: PlacesService.catalogVersion,
    description:
        'Community hub with ASL staff, captioned events, hearing loops, and step-free access.',
  ),
  // ── Extended category coverage (native pins + module-linked types) ─────────
  _categorySeed(
    id: 'midtown-clinic',
    name: 'Midtown Community Clinic',
    category: 'clinic',
    lat: 40.756,
    lng: -73.981,
    score: 88,
    description: 'Outpatient clinic with step-free entrance and accessible exam rooms.',
  ),
  _categorySeed(
    id: 'park-ave-medical',
    name: 'Park Avenue Medical Group',
    category: 'doctor',
    lat: 40.762,
    lng: -73.971,
    score: 90,
    description: 'Primary care practice with wheelchair-accessible waiting area.',
  ),
  _categorySeed(
    id: 'riverside-rehab',
    name: 'Riverside Rehab Center',
    category: 'rehab',
    lat: 40.771,
    lng: -73.992,
    score: 93,
    description: 'Physiotherapy gym with hoists, wide doors, and accessible parking.',
  ),
  _categorySeed(
    id: 'manhattan-college',
    name: 'Manhattan Accessible College',
    category: 'school',
    lat: 40.748,
    lng: -73.985,
    score: 86,
    description: 'Campus with elevators, accessible lecture halls, and quiet study rooms.',
  ),
  _categorySeed(
    id: 'calm-minds-therapy',
    name: 'Calm Minds Therapy',
    category: 'therapist',
    lat: 40.754,
    lng: -73.991,
    score: 89,
    description: 'Counselling office with step-free access and sensory-friendly rooms.',
  ),
  _categorySeed(
    id: 'smile-dental',
    name: 'Smile Accessible Dental',
    category: 'dentist',
    lat: 40.759,
    lng: -73.984,
    score: 87,
    description: 'Dental clinic with adjustable chairs and accessible restroom.',
  ),
  _categorySeed(
    id: 'social-security-office',
    name: 'Social Security Office',
    category: 'government',
    lat: 40.752,
    lng: -73.988,
    score: 82,
    description: 'Public benefits desk with ramp, hearing loop, and priority seating.',
  ),
  _categorySeed(
    id: 'accessible-bank',
    name: 'Accessible Community Bank',
    category: 'bank',
    lat: 40.761,
    lng: -73.978,
    score: 85,
    description: 'Branch with low counters, step-free entry, and accessible ATM.',
  ),
  _categorySeed(
    id: 'midtown-hotel',
    name: 'Midtown Accessible Hotel',
    category: 'hotel',
    lat: 40.757,
    lng: -73.976,
    score: 91,
    description: 'Roll-in showers, visual alarms, and accessible concierge desk.',
  ),
  _categorySeed(
    id: 'harvest-kitchen',
    name: 'Harvest Kitchen',
    category: 'restaurant',
    lat: 40.746,
    lng: -73.987,
    score: 88,
    description: 'Restaurant with wide aisles, accessible restroom, and quiet booth seating.',
  ),
  _categorySeed(
    id: 'fresh-market',
    name: 'Fresh Accessible Market',
    category: 'grocery',
    lat: 40.764,
    lng: -73.983,
    score: 84,
    description: 'Supermarket with accessible checkout and step-free produce aisles.',
    features: const [
      'stepFree',
      'ramp',
      'toilet',
      'elevator',
      'familyFriendly',
    ],
  ),
  _categorySeed(
    id: 'unity-worship',
    name: 'Unity Interfaith Center',
    category: 'worship',
    lat: 40.768,
    lng: -73.965,
    score: 86,
    description: 'Worship space with ramp, hearing loop, and accessible seating.',
  ),
  _categorySeed(
    id: 'modern-art-museum',
    name: 'Modern Art Museum',
    category: 'museum',
    lat: 40.761,
    lng: -73.977,
    score: 90,
    description: 'Museum with elevators, tactile exhibits, and captioned tours.',
  ),
  _categorySeed(
    id: 'fit-for-all-gym',
    name: 'Fit For All Gym',
    category: 'gym',
    lat: 40.743,
    lng: -73.994,
    score: 85,
    description: 'Adaptive equipment, wide locker rooms, and accessible pool lift.',
  ),
  _categorySeed(
    id: 'rockaway-beach',
    name: 'Rockaway Accessible Beach',
    category: 'beach',
    lat: 40.742,
    lng: -73.998,
    score: 83,
    description: 'Mobi-mat beach access, accessible changing rooms, and calm hours.',
    features: const [
      'stepFree',
      'ramp',
      'toilet',
      'elevator',
      'freeParking',
      'familyFriendly',
      'petFriendly',
    ],
  ),
  _categorySeed(
    id: 'laguardia-terminal',
    name: 'LaGuardia Terminal B',
    category: 'airport',
    lat: 40.776,
    lng: -73.874,
    score: 88,
    description: 'Airport terminal with wheelchair assistance, visual paging, and accessible restrooms.',
  ),
  _categorySeed(
    id: 'penn-station',
    name: 'Penn Station',
    category: 'railway',
    lat: 40.750,
    lng: -73.994,
    score: 80,
    description: 'Railway station with elevator access to platforms and tactile wayfinding.',
  ),
  _categorySeed(
    id: 'bryant-park-comfort',
    name: 'Bryant Park Comfort Station',
    category: 'public_toilet',
    lat: 40.753,
    lng: -73.983,
    score: 87,
    description: 'Public Changing Places–style restroom with adult changing bench.',
  ),
  _categorySeed(
    id: 'midtown-pharmacy',
    name: 'Midtown Accessible Pharmacy',
    category: 'pharmacy',
    lat: 40.758,
    lng: -73.980,
    score: 86,
    description: 'Pharmacy counter at wheelchair height with step-free entry.',
  ),

  // ── Abbottabad, Pakistan (local testing set) ───────────────────────────────
  AccessiblePlace(
    id: 'abb-ayub-teaching-hospital',
    name: 'Ayub Teaching Hospital',
    category: 'hospital',
    lat: 34.2046,
    lng: 73.2332,
    score: 94,
    rating: 4.7,
    reviewCount: 210,
    openNow: true,
    imageUrl:
        'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=800&h=480&fit=crop',
    photoUrls: const [
      'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?w=800&h=480&fit=crop',
    ],
    features: [
      'stepFree',
      'ramp',
      'elevator',
      'toilet',
      'parking',
      'braille',
      'hearing',
      'serviceAnimal',
    ],
    needs: ['wheelchair', 'visual', 'hearing'],
    address: 'Ayub Medical Complex, Abbottabad, KP',
    phone: '+92 992 382571',
    hours: '24/7 Open',
    website: 'https://ayubmed.edu.pk',
    verified: true,
    governmentCertified: true,
    inspectionDate: DateTime(2025, 6, 12),
    catalogVersion: PlacesService.catalogVersion,
    peakHoursHint: 'Busy 9 AM–1 PM on weekdays',
    description:
        'Major teaching hospital with step-free entrances, elevators, accessible restrooms, and reserved disability parking.',
  ),
  AccessiblePlace(
    id: 'abb-doctors-hospital',
    name: 'Doctors Hospital Abbottabad',
    category: 'hospital',
    lat: 34.1568,
    lng: 73.2142,
    score: 91,
    rating: 4.6,
    reviewCount: 96,
    openNow: true,
    imageUrl:
        'https://images.unsplash.com/photo-1516549655169-df83a0774514?w=800&h=480&fit=crop',
    features: [
      'stepFree',
      'ramp',
      'elevator',
      'toilet',
      'parking',
      'dropOff',
    ],
    needs: ['wheelchair'],
    address: 'Mansehra Road, Abbottabad, KP',
    phone: '+92 992 555010',
    hours: '24/7 Open',
    website: 'https://doctorshospital.abbottabad.example',
    verified: true,
    catalogVersion: PlacesService.catalogVersion,
    description:
        'Private hospital with ramp access, elevators, and an accessible drop-off bay at the main entrance.',
  ),
  AccessiblePlace(
    id: 'abb-pine-restaurant',
    name: 'Pine View Restaurant',
    category: 'restaurant',
    lat: 34.1695,
    lng: 73.2218,
    score: 88,
    rating: 4.5,
    reviewCount: 74,
    openNow: true,
    imageUrl:
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&h=480&fit=crop',
    features: [
      'stepFree',
      'ramp',
      'toilet',
      'parking',
      'accessibleSeating',
      'familyFriendly',
    ],
    needs: ['wheelchair'],
    address: 'Jinnah Road, Abbottabad, KP',
    phone: '+92 992 555020',
    hours: 'Open 11:00 AM – 11:00 PM',
    website: 'https://pineview.abbottabad.example',
    verified: true,
    catalogVersion: PlacesService.catalogVersion,
    description:
        'Family restaurant with a step-free entrance, accessible restroom, and wide aisle seating.',
  ),
  AccessiblePlace(
    id: 'abb-city-mall',
    name: 'Abbottabad City Mall',
    category: 'mall',
    lat: 34.1662,
    lng: 73.2189,
    score: 89,
    rating: 4.4,
    reviewCount: 132,
    openNow: true,
    imageUrl:
        'https://images.unsplash.com/photo-1519567241046-7f570e3cb635?w=800&h=480&fit=crop',
    features: [
      'stepFree',
      'elevator',
      'toilet',
      'parking',
      'freeParking',
      'wideCorridors',
      'familyFriendly',
    ],
    needs: ['wheelchair'],
    address: 'Supply Bazaar Road, Abbottabad, KP',
    phone: '+92 992 555030',
    hours: 'Open 10:00 AM – 10:00 PM',
    website: 'https://citymall.abbottabad.example',
    verified: true,
    catalogVersion: PlacesService.catalogVersion,
    description:
        'Shopping mall with elevators, accessible restrooms, wide corridors, and reserved parking near the entrance.',
  ),
  AccessiblePlace(
    id: 'abb-ilyasi-masjid',
    name: 'Ilyasi Masjid',
    category: 'worship',
    lat: 34.17115,
    lng: 73.25878,
    score: 86,
    rating: 4.8,
    reviewCount: 180,
    openNow: true,
    imageUrl:
        'https://images.unsplash.com/photo-1564769625905-50e93615e769?w=800&h=480&fit=crop',
    features: [
      'stepFree',
      'ramp',
      'toilet',
      'parking',
      'hearing',
      'serviceAnimal',
    ],
    needs: ['wheelchair', 'hearing'],
    address: 'Ilyasi Nala, Abbottabad, KP',
    phone: '+92 992 555040',
    hours: 'Open for prayer times',
    website: 'https://ilyasimasjid.abbottabad.example',
    verified: true,
    catalogVersion: PlacesService.catalogVersion,
    description:
        'Historic mosque with ramp access to the prayer hall, accessible washrooms, and nearby parking.',
  ),
  AccessiblePlace(
    id: 'abb-shimla-park',
    name: 'Shimla Hill Viewpoint',
    category: 'park',
    lat: 34.1618,
    lng: 73.2405,
    score: 82,
    rating: 4.3,
    reviewCount: 58,
    openNow: true,
    imageUrl:
        'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800&h=480&fit=crop',
    features: [
      'stepFree',
      'ramp',
      'toilet',
      'parking',
      'freeParking',
      'quiet',
      'petFriendly',
    ],
    needs: ['wheelchair', 'cognitive'],
    address: 'Shimla Hill, Abbottabad, KP',
    phone: '+92 992 555045',
    hours: 'Daily 6:00 AM – 8:00 PM',
    website: 'https://shimlahill.abbottabad.example',
    verified: false,
    catalogVersion: PlacesService.catalogVersion,
    description:
        'Hill viewpoint with a partial step-free path, accessible parking, and a calm outdoor seating area.',
  ),
  AccessiblePlace(
    id: 'abb-hbl-main',
    name: 'HBL Main Branch Abbottabad',
    category: 'bank',
    lat: 34.1681,
    lng: 73.2194,
    score: 85,
    rating: 4.2,
    reviewCount: 41,
    openNow: true,
    imageUrl:
        'https://images.unsplash.com/photo-1501167786227-4cbae383b138?w=800&h=480&fit=crop',
    features: [
      'stepFree',
      'ramp',
      'toilet',
      'elevator',
      'lowCounters',
      'parking',
    ],
    needs: ['wheelchair'],
    address: 'The Mall, Abbottabad, KP',
    phone: '+92 992 555050',
    hours: 'Mon–Fri 9:00 AM – 5:00 PM',
    website: 'https://hbl.com.pk',
    verified: true,
    catalogVersion: PlacesService.catalogVersion,
    description:
        'Bank branch with ramp entry, elevator access, and a low-height service counter.',
  ),
  AccessiblePlace(
    id: 'abb-sarban-pharmacy',
    name: 'Sarban Accessible Pharmacy',
    category: 'pharmacy',
    lat: 34.1702,
    lng: 73.2231,
    score: 87,
    rating: 4.5,
    reviewCount: 39,
    openNow: true,
    imageUrl:
        'https://images.unsplash.com/photo-1587854691554-cf9fadbcd81f?w=800&h=480&fit=crop',
    features: [
      'stepFree',
      'toilet',
      'parking',
      'lowCounters',
      'wideCorridors',
    ],
    needs: ['wheelchair'],
    address: 'Sarban Chowk, Abbottabad, KP',
    phone: '+92 992 555060',
    hours: 'Open 9:00 AM – 11:00 PM',
    website: 'https://sarbanpharmacy.abbottabad.example',
    verified: true,
    catalogVersion: PlacesService.catalogVersion,
    description:
        'Neighborhood pharmacy with step-free entry, wide aisles, and a wheelchair-height counter.',
  ),
  AccessiblePlace(
    id: 'abb-mansehra-rd-parking',
    name: 'Mansehra Road Accessible Parking',
    category: 'parking',
    lat: 34.1724,
    lng: 73.2256,
    score: 84,
    rating: 4.1,
    reviewCount: 22,
    openNow: true,
    imageUrl:
        'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=800&h=480&fit=crop',
    features: [
      'parking',
      'freeParking',
      'stepFree',
      'dropOff',
      'evAccessibleParking',
    ],
    needs: ['wheelchair'],
    address: 'Mansehra Road near Supply, Abbottabad, KP',
    phone: '+92 992 555070',
    hours: '24/7 Open',
    website: 'https://parking.abbottabad.example',
    verified: true,
    catalogVersion: PlacesService.catalogVersion,
    description:
        'Marked accessible parking bays with a step-free curb cut and short drop-off lane.',
  ),
  AccessiblePlace(
    id: 'abb-public-restroom',
    name: 'Jinnah Road Accessible Restroom',
    category: 'public_toilet',
    lat: 34.1674,
    lng: 73.2201,
    score: 90,
    rating: 4.4,
    reviewCount: 28,
    openNow: true,
    imageUrl:
        'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=800&h=480&fit=crop',
    features: [
      'toilet',
      'stepFree',
      'ramp',
      'familyFriendly',
    ],
    needs: ['wheelchair'],
    address: 'Jinnah Road Public Complex, Abbottabad, KP',
    phone: '+92 992 555080',
    hours: 'Daily 8:00 AM – 10:00 PM',
    website: 'https://publicrestrooms.abbottabad.example',
    verified: true,
    catalogVersion: PlacesService.catalogVersion,
    description:
        'Public Changing Places–style restroom with step-free entry and grab rails.',
  ),
];

AccessiblePlace _categorySeed({
  required String id,
  required String name,
  required String category,
  required double lat,
  required double lng,
  required int score,
  required String description,
  List<String> features = const ['stepFree', 'ramp', 'toilet', 'elevator'],
}) {
  return AccessiblePlace(
    id: id,
    name: name,
    category: category,
    lat: lat,
    lng: lng,
    score: score,
    rating: 4.4,
    reviewCount: 24,
    openNow: true,
    imageUrl:
        'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&h=480&fit=crop',
    features: features,
    needs: const ['wheelchair'],
    address: 'Midtown Manhattan, New York, NY',
    verified: true,
    catalogVersion: PlacesService.catalogVersion,
    description: description,
  );
}
