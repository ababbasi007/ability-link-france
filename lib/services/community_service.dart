import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/community.dart';
import '../models/user_profile.dart';
import 'notification_service.dart';

class CommunityService {
  CommunityService({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? get uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('communityPosts');
  CollectionReference<Map<String, dynamic>> get _groups =>
      _db.collection('communityGroups');
  CollectionReference<Map<String, dynamic>> get _events =>
      _db.collection('communityEvents');

  CollectionReference<Map<String, dynamic>>? get _blocked {
    final id = uid;
    if (id == null) return null;
    return _db.collection('users').doc(id).collection('blockedUsers');
  }

  CollectionReference<Map<String, dynamic>>? get _following {
    final id = uid;
    if (id == null) return null;
    return _db.collection('users').doc(id).collection('communityFollowing');
  }

  CollectionReference<Map<String, dynamic>>? get _topics {
    final id = uid;
    if (id == null) return null;
    return _db.collection('users').doc(id).collection('communityTopics');
  }

  String get _displayName {
    final n = _auth.currentUser?.displayName?.trim();
    if (n != null && n.isNotEmpty) return n;
    return 'Ability Link user';
  }

  Stream<List<CommunityPost>> watchPosts() {
    return _posts.snapshots().map((snap) {
      final list = snap.docs.map(CommunityPost.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<CommunityPost>> watchTipsForPlace(String placeId) {
    if (placeId.isEmpty) return Stream.value(const []);
    return watchPosts().map(
      (posts) => posts
          .where(
            (p) =>
                p.isVisible &&
                p.type == 'tip' &&
                p.placeId == placeId,
          )
          .toList(),
    );
  }

  Stream<List<CommunityReply>> watchReplies(String postId) {
    return _posts.doc(postId).collection('replies').snapshots().map((snap) {
      final list = snap.docs.map(CommunityReply.fromDoc).toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  Stream<List<CommunityGroup>> watchGroups() {
    return _groups.snapshots().map((snap) {
      final list = snap.docs.map(CommunityGroup.fromDoc).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  Stream<List<CommunityEvent>> watchEvents() {
    return _events.snapshots().map((snap) {
      final list = snap.docs.map(CommunityEvent.fromDoc).toList();
      list.sort((a, b) => a.startAt.compareTo(b.startAt));
      return list;
    });
  }

  Stream<Set<String>> watchBlockedUids() {
    final col = _blocked;
    if (col == null) return Stream.value(const {});
    return col.snapshots().map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  Stream<Set<String>> watchFollowingUids() {
    final col = _following;
    if (col == null) return Stream.value(const {});
    return col.snapshots().map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  Stream<Set<String>> watchFollowedTopics() {
    final col = _topics;
    if (col == null) return Stream.value(const {});
    return col.snapshots().map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  List<CommunityPost> filterPosts(
    List<CommunityPost> all, {
    required String type,
    required String query,
    required Set<String> blocked,
    String city = '',
    String groupId = '',
    Set<String> followingUids = const {},
    Set<String> followedTopics = const {},
    bool localOnly = false,
    bool followingOnly = false,
  }) {
    final q = query.trim().toLowerCase();
    final cityQ = city.trim().toLowerCase();
    return all.where((p) {
      if (!p.isVisible) return false;
      if (blocked.contains(p.uid) && !p.seeded) return false;
      if (groupId.isNotEmpty && p.groupId != groupId) return false;
      if (type != 'All' && p.type != type) return false;
      if (localOnly && cityQ.isNotEmpty) {
        if (!p.city.toLowerCase().contains(cityQ) &&
            p.city.toLowerCase() != 'global') {
          return false;
        }
      }
      if (followingOnly) {
        final byUser = followingUids.contains(p.uid);
        final byTopic = followedTopics.contains(p.topic);
        if (!byUser && !byTopic) return false;
      }
      if (q.isEmpty) return true;
      return p.title.toLowerCase().contains(q) ||
          p.body.toLowerCase().contains(q) ||
          p.city.toLowerCase().contains(q) ||
          p.authorName.toLowerCase().contains(q) ||
          p.topic.toLowerCase().contains(q);
    }).toList();
  }

  int localScore(CommunityGroup group, UserProfile? profile) {
    if (profile == null) return 40;
    final city = (profile.contact['city'] as String?)?.toLowerCase() ?? '';
    if (city.isNotEmpty && group.city.toLowerCase().contains(city)) return 96;
    if (group.isSupport) return 70;
    return 55;
  }

  Future<void> ensureSeeded() async {
    for (final p in seedPosts) {
      final ref = _posts.doc(p.id);
      final snap = await ref.get();
      if (snap.exists) continue;
      await ref.set({
        ...p.toMap(),
        'createdAt': Timestamp.fromDate(p.createdAt),
      });
    }
    for (final g in seedGroups) {
      final ref = _groups.doc(g.id);
      final snap = await ref.get();
      if (snap.exists) continue;
      await ref.set(g.toMap());
    }
    for (final e in seedEvents) {
      final ref = _events.doc(e.id);
      final snap = await ref.get();
      if (snap.exists) continue;
      await ref.set({...e.toMap(), 'startAt': Timestamp.fromDate(e.startAt)});
    }
  }

  Future<void> createPost({
    required String type,
    required String title,
    required String body,
    String city = '',
    String topic = 'Local life',
    String groupId = '',
    String placeId = '',
    String placeName = '',
    List<String> pollOptions = const [],
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to post');
    final options = pollOptions.map((e) => e.trim()).where((e) => e.isNotEmpty);
    await _posts.doc().set({
      'type': type,
      'uid': user.uid,
      'authorName': _displayName,
      'title': title.trim(),
      'body': body.trim(),
      'city': city.trim(),
      'topic': topic.trim().isEmpty ? 'Local life' : topic.trim(),
      'groupId': groupId,
      'placeId': placeId.trim(),
      'placeName': placeName.trim(),
      'status': 'published',
      'flagCount': 0,
      'replyCount': 0,
      'likeCount': 0,
      'likedBy': <String>[],
      'pollOptions': options.toList(),
      'pollCounts': List<int>.filled(options.length, 0),
      'voterUids': <String>[],
      'seeded': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createTipForPlace({
    required String placeId,
    required String placeName,
    required String title,
    required String body,
    String city = '',
    String topic = 'Mobility',
  }) async {
    await createPost(
      type: 'tip',
      title: title,
      body: body,
      city: city,
      topic: topic,
      placeId: placeId,
      placeName: placeName,
    );
  }

  Future<void> addReply(
    String postId,
    String body, {
    String parentId = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to reply');
    final postRef = _posts.doc(postId);
    await postRef.collection('replies').doc().set({
      'uid': user.uid,
      'authorName': _displayName,
      'body': body.trim(),
      'parentId': parentId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await postRef.update({'replyCount': FieldValue.increment(1)});
    final post = await postRef.get();
    final authorUid = (post.data()?['uid'] as String?) ?? '';
    if (authorUid.isNotEmpty && authorUid != user.uid) {
      await NotificationService(db: _db, auth: _auth).notifyMessage(
        uid: authorUid,
        title: 'New comment on your post',
        body: body.trim(),
        relatedId: postId,
      );
    }
  }

  Future<void> toggleLike(CommunityPost post) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to like');
    final ref = _posts.doc(post.id);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final liked = List<String>.from(
        snap.data()?['likedBy'] as List? ?? const [],
      );
      if (liked.contains(user.uid)) {
        liked.remove(user.uid);
      } else {
        liked.add(user.uid);
      }
      tx.update(ref, {'likedBy': liked, 'likeCount': liked.length});
    });
  }

  Future<void> vote(String postId, int optionIndex) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to vote');
    final ref = _posts.doc(postId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() ?? {};
      final voters = List<String>.from(data['voterUids'] as List? ?? const []);
      if (voters.contains(user.uid)) return;
      final counts = List<int>.from(
        (data['pollCounts'] as List? ?? const []).map(
          (e) => (e as num).toInt(),
        ),
      );
      if (optionIndex < 0 || optionIndex >= counts.length) return;
      voters.add(user.uid);
      counts[optionIndex] = counts[optionIndex] + 1;
      tx.update(ref, {'voterUids': voters, 'pollCounts': counts});
    });
  }

  Future<void> flagPost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to report');
    final ref = _posts.doc(postId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final count = ((snap.data()?['flagCount'] as num?)?.toInt() ?? 0) + 1;
      tx.update(ref, {
        'flagCount': count,
        'status': count >= 3 ? 'hidden' : 'published',
      });
    });
  }

  Future<void> blockUser(String otherUid) async {
    final col = _blocked;
    if (col == null) throw StateError('Sign in to block');
    if (otherUid.isEmpty || otherUid == uid) return;
    await col.doc(otherUid).set({'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> unblockUser(String otherUid) async {
    final col = _blocked;
    if (col == null) return;
    await col.doc(otherUid).delete();
  }

  Future<void> toggleFollowUser(String otherUid, {required bool follow}) async {
    final col = _following;
    if (col == null) throw StateError('Sign in to follow');
    if (otherUid.isEmpty || otherUid == uid) return;
    if (follow) {
      await col.doc(otherUid).set({'createdAt': FieldValue.serverTimestamp()});
    } else {
      await col.doc(otherUid).delete();
    }
  }

  Future<void> toggleFollowTopic(String topic, {required bool follow}) async {
    final col = _topics;
    if (col == null) throw StateError('Sign in to follow topics');
    final id = topic.trim();
    if (id.isEmpty) return;
    if (follow) {
      await col.doc(id).set({'createdAt': FieldValue.serverTimestamp()});
    } else {
      await col.doc(id).delete();
    }
  }

  Future<void> toggleJoin(CommunityGroup group) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to join');
    final members = [...group.memberUids];
    if (members.contains(user.uid)) {
      members.remove(user.uid);
    } else {
      members.add(user.uid);
    }
    await _groups.doc(group.id).update({
      'memberUids': members,
      'memberCount': members.length,
    });
  }

  Future<String> createGroup({
    required String name,
    required String summary,
    required String city,
    required String topic,
    required String kind,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to create a group');
    final ref = _groups.doc();
    await ref.set({
      'name': name.trim(),
      'summary': summary.trim(),
      'city': city.trim(),
      'topic': topic,
      'kind': kind,
      'createdBy': user.uid,
      'memberUids': [user.uid],
      'memberCount': 1,
    });
    return ref.id;
  }

  Future<String> createEvent({
    required String title,
    required String body,
    required String city,
    required String venue,
    required DateTime startAt,
    String topic = 'Local life',
    String groupId = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to create an event');
    final ref = _events.doc();
    await ref.set({
      'title': title.trim(),
      'body': body.trim(),
      'city': city.trim(),
      'venue': venue.trim(),
      'startAt': Timestamp.fromDate(startAt),
      'uid': user.uid,
      'authorName': _displayName,
      'topic': topic,
      'groupId': groupId,
      'rsvpUids': [user.uid],
      'rsvpCount': 1,
      'seeded': false,
    });
    return ref.id;
  }

  Future<void> toggleRsvp(CommunityEvent event) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to RSVP');
    final going = [...event.rsvpUids];
    if (going.contains(user.uid)) {
      going.remove(user.uid);
    } else {
      going.add(user.uid);
    }
    await _events.doc(event.id).update({
      'rsvpUids': going,
      'rsvpCount': going.length,
    });
  }
}

final seedPosts = <CommunityPost>[
  CommunityPost(
    id: 'c-welcome',
    type: 'post',
    uid: 'seed-community',
    authorName: 'Ability Link',
    title: 'Welcome to the community',
    body:
        'Share tips, ask questions, post experiences, join groups, and RSVP to events. Report anything unsafe — three reports hide a post.',
    city: 'Global',
    topic: 'Local life',
    createdAt: DateTime.now().subtract(const Duration(days: 4)),
    seeded: true,
  ),
  CommunityPost(
    id: 'c-discussion-metro',
    type: 'discussion',
    uid: 'seed-community',
    authorName: 'Access Advocates',
    title: 'How do you ask for extra time at metro gates?',
    body:
        'Open thread: what phrasing actually works with staff in your city? Share scripts in any language.',
    city: 'Paris',
    topic: 'Mobility',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    seeded: true,
    replyCount: 2,
  ),
  CommunityPost(
    id: 'c-exp-hospital',
    type: 'experience',
    uid: 'seed-community',
    authorName: 'Camille D.',
    title: 'MDPH appointment with a sign interpreter',
    body:
        'Booked LSF through the maison. Arrive 20 minutes early — the interpreter desk is on the ground floor, left of reception.',
    city: 'Lyon',
    topic: 'Hearing',
    createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
    seeded: true,
  ),
  CommunityPost(
    id: 'c-tip-hospital-west-wing',
    type: 'tip',
    uid: 'seed-community',
    authorName: 'Maya R.',
    title: 'Use the west wing entrance',
    body:
        'The main lobby elevator is often busy. West wing has a level entry and a quieter waiting area — staff at Door B can escort you.',
    city: 'Lahore',
    topic: 'Mobility',
    placeId: 'city-hospital',
    placeName: 'City Hospital',
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    seeded: true,
    likeCount: 6,
  ),
  CommunityPost(
    id: 'c-tip-green-cafe-counter',
    type: 'tip',
    uid: 'seed-community',
    authorName: 'Priya S.',
    title: 'Ask for the wide-lane counter',
    body:
        'The left counter has the most clearance for power chairs. Staff will read the menu aloud if you ask.',
    city: 'Lahore',
    topic: 'Mobility',
    placeId: 'green-cafe',
    placeName: 'Green Cafe',
    createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 6)),
    seeded: true,
    likeCount: 4,
  ),
  CommunityPost(
    id: 'c-tip-metro-gate-time',
    type: 'tip',
    uid: 'seed-community',
    authorName: 'Nadia R.',
    title: 'Metro staff will wait if you ask',
    body:
        'At the hub, tell the attendant you need extra time on the ramp. They held the doors for me twice this week.',
    city: 'Lahore',
    topic: 'Mobility',
    placeId: 'metro-hub',
    placeName: 'Metro Transit Hub',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    seeded: true,
    replyCount: 2,
  ),
  CommunityPost(
    id: 'c-tip-metro',
    type: 'tip',
    uid: 'seed-community',
    authorName: 'Nadia R.',
    title: 'Metro staff will wait if you ask',
    body:
        'At Lahore Metro, tell the attendant you need extra time on the ramp. They held the doors for me twice this week.',
    city: 'Lahore',
    topic: 'Mobility',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    seeded: true,
    replyCount: 2,
  ),
  CommunityPost(
    id: 'c-q-taxi',
    type: 'question',
    uid: 'seed-community',
    authorName: 'Omar K.',
    title: 'Wheelchair-friendly taxi in Lahore?',
    body:
        'Looking for a reliable accessible taxi for hospital visits. Folding chair, not power. Any numbers that actually show up?',
    city: 'Lahore',
    topic: 'Mobility',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    seeded: true,
    replyCount: 1,
  ),
  CommunityPost(
    id: 'c-issue-lift',
    type: 'issue',
    uid: 'seed-community',
    authorName: 'Sara Khan',
    title: 'Lift out at City Hospital block B',
    body:
        'Reported to reception. Staff directing wheelchair users to block A. Avoid B until Thursday if you can.',
    city: 'Lahore',
    topic: 'Mobility',
    createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    seeded: true,
  ),
  CommunityPost(
    id: 'c-poll-lifts',
    type: 'poll',
    uid: 'seed-community',
    authorName: 'Access Advocates',
    title: 'Should malls publish live lift status?',
    body:
        'Hourly updates on a public board or in-app. What would help you most?',
    city: 'Lahore',
    topic: 'Local life',
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    pollOptions: const ['Yes, hourly', 'Daily is enough', 'Not needed'],
    pollCounts: const [12, 4, 1],
    voterUids: const ['seed-a', 'seed-b'],
    seeded: true,
  ),
];

final seedGroups = <CommunityGroup>[
  CommunityGroup(
    id: 'g-lahore',
    name: 'Lahore Access Advocates',
    city: 'Lahore',
    topic: 'Local life',
    kind: 'local',
    createdBy: 'seed-community',
    summary: 'Barrier reports, metro tips, and weekend meetups.',
    memberUids: const ['seed-a', 'seed-b', 'seed-c'],
  ),
  CommunityGroup(
    id: 'g-paris',
    name: 'Paris access circle',
    city: 'Paris',
    topic: 'Local life',
    kind: 'local',
    createdBy: 'seed-community',
    summary: 'RATP, MDPH queues, and accessible cafés in the 11th and 19th.',
    memberUids: const ['seed-p1', 'seed-p2'],
  ),
  CommunityGroup(
    id: 'g-care',
    name: 'Parents & caregivers circle',
    city: 'Global',
    topic: 'Caregivers',
    kind: 'support',
    createdBy: 'seed-community',
    summary: 'Meds, school IEPs, and respite swaps — no medical advice.',
    memberUids: const ['seed-d'],
  ),
  CommunityGroup(
    id: 'g-deaf',
    name: 'Deaf community meetups',
    city: 'Karachi',
    topic: 'Hearing',
    kind: 'support',
    createdBy: 'seed-community',
    summary: 'Sign-friendly events and captioned film nights.',
    memberUids: const ['seed-e', 'seed-f'],
  ),
  CommunityGroup(
    id: 'g-mobility',
    name: 'Wheelchair & mobility support',
    city: 'Global',
    topic: 'Mobility',
    kind: 'support',
    createdBy: 'seed-community',
    summary: 'Ramp reports, repair shops, and travel with a chair.',
    memberUids: const ['seed-m1'],
  ),
  CommunityGroup(
    id: 'g-vision',
    name: 'Blind and low-vision network',
    city: 'Global',
    topic: 'Vision',
    kind: 'support',
    createdBy: 'seed-community',
    summary: 'Orientation tips, apps, and audio description nights.',
    memberUids: const ['seed-v1', 'seed-v2'],
  ),
];

final seedEvents = <CommunityEvent>[
  CommunityEvent(
    id: 'e-paris-mdph',
    title: 'MDPH paperwork clinic',
    body:
        'Volunteers help fill dossiers. Bring ID and any existing certificates. LSF interpreter booked.',
    city: 'Paris',
    venue: 'Maison départementale, 11th',
    startAt: DateTime.now().add(const Duration(days: 8, hours: 3)),
    uid: 'seed-community',
    authorName: 'Paris access circle',
    topic: 'Local life',
    groupId: 'g-paris',
    rsvpUids: const ['seed-p1'],
    seeded: true,
  ),
  CommunityEvent(
    id: 'e-care-coffee',
    title: 'Caregiver coffee (online)',
    body: '30-minute check-in. Cameras optional. No clinical advice.',
    city: 'Global',
    venue: 'Ability Link video room',
    startAt: DateTime.now().add(const Duration(days: 3, hours: 2)),
    uid: 'seed-community',
    authorName: 'Parents & caregivers circle',
    topic: 'Caregivers',
    groupId: 'g-care',
    rsvpUids: const ['seed-d'],
    seeded: true,
  ),
  CommunityEvent(
    id: 'e-karachi-film',
    title: 'Captioned film night',
    body: 'Open captions, step-free entry, companion seats held at the aisle.',
    city: 'Karachi',
    venue: 'Community arts centre',
    startAt: DateTime.now().add(const Duration(days: 12)),
    uid: 'seed-community',
    authorName: 'Deaf community meetups',
    topic: 'Hearing',
    groupId: 'g-deaf',
    rsvpUids: const ['seed-e'],
    seeded: true,
  ),
];
