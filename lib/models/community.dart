import 'package:cloud_firestore/cloud_firestore.dart';

const communityTopics = [
  'Mobility',
  'Vision',
  'Hearing',
  'Cognitive',
  'Caregivers',
  'Employment',
  'Education',
  'Local life',
];

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.type,
    required this.uid,
    required this.authorName,
    required this.title,
    required this.body,
    required this.city,
    required this.createdAt,
    this.status = 'published',
    this.flagCount = 0,
    this.replyCount = 0,
    this.likeCount = 0,
    this.likedBy = const [],
    this.topic = 'Local life',
    this.groupId = '',
    this.placeId = '',
    this.placeName = '',
    this.pollOptions = const [],
    this.pollCounts = const [],
    this.voterUids = const [],
    this.seeded = false,
  });

  /// post | question | tip | issue | poll | discussion | experience
  final String id;
  final String type;
  final String uid;
  final String authorName;
  final String title;
  final String body;
  final String city;
  final DateTime createdAt;
  final String status;
  final int flagCount;
  final int replyCount;
  final int likeCount;
  final List<String> likedBy;
  final String topic;
  final String groupId;
  final String placeId;
  final String placeName;
  final List<String> pollOptions;
  final List<int> pollCounts;
  final List<String> voterUids;
  final bool seeded;

  bool get isVisible => status != 'hidden' && flagCount < 3;
  bool get isPoll => type == 'poll';

  bool likedByUser(String? userId) =>
      userId != null && likedBy.contains(userId);

  String get typeLabel => switch (type) {
    'question' => 'Q&A',
    'tip' => 'Tip',
    'issue' => 'Issue',
    'poll' => 'Poll',
    'discussion' => 'Discussion',
    'experience' => 'Experience',
    _ => 'Post',
  };

  bool hasVoted(String? userId) {
    if (userId == null) return false;
    return voterUids.contains(userId);
  }

  factory CommunityPost.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return CommunityPost(
      id: doc.id,
      type: (d['type'] as String?) ?? 'post',
      uid: (d['uid'] as String?) ?? '',
      authorName: (d['authorName'] as String?) ?? 'Community member',
      title: (d['title'] as String?) ?? '',
      body: (d['body'] as String?) ?? '',
      city: (d['city'] as String?) ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      status: (d['status'] as String?) ?? 'published',
      flagCount: (d['flagCount'] as num?)?.toInt() ?? 0,
      replyCount: (d['replyCount'] as num?)?.toInt() ?? 0,
      likeCount: (d['likeCount'] as num?)?.toInt() ?? 0,
      likedBy: List<String>.from(d['likedBy'] as List? ?? const []),
      topic: (d['topic'] as String?) ?? 'Local life',
      groupId: (d['groupId'] as String?) ?? '',
      placeId: (d['placeId'] as String?) ?? '',
      placeName: (d['placeName'] as String?) ?? '',
      pollOptions: List<String>.from(d['pollOptions'] as List? ?? const []),
      pollCounts: List<int>.from(
        (d['pollCounts'] as List? ?? const []).map((e) => (e as num).toInt()),
      ),
      voterUids: List<String>.from(d['voterUids'] as List? ?? const []),
      seeded: d['seeded'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type,
    'uid': uid,
    'authorName': authorName,
    'title': title,
    'body': body,
    'city': city,
    'status': status,
    'flagCount': flagCount,
    'replyCount': replyCount,
    'likeCount': likeCount,
    'likedBy': likedBy,
    'topic': topic,
    'groupId': groupId,
    'placeId': placeId,
    'placeName': placeName,
    'pollOptions': pollOptions,
    'pollCounts': pollCounts,
    'voterUids': voterUids,
    'seeded': seeded,
  };
}

class CommunityReply {
  const CommunityReply({
    required this.id,
    required this.uid,
    required this.authorName,
    required this.body,
    required this.createdAt,
    this.parentId = '',
  });

  final String id;
  final String uid;
  final String authorName;
  final String body;
  final DateTime createdAt;
  final String parentId;

  factory CommunityReply.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return CommunityReply(
      id: doc.id,
      uid: (d['uid'] as String?) ?? '',
      authorName: (d['authorName'] as String?) ?? 'Member',
      body: (d['body'] as String?) ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      parentId: (d['parentId'] as String?) ?? '',
    );
  }
}

class CommunityGroup {
  const CommunityGroup({
    required this.id,
    required this.name,
    required this.city,
    required this.summary,
    required this.memberUids,
    this.topic = 'Local life',
    this.kind = 'local',
    this.createdBy = '',
  });

  final String id;
  final String name;
  final String city;
  final String summary;
  final List<String> memberUids;
  final String topic;

  /// support | local
  final String kind;
  final String createdBy;

  int get memberCount => memberUids.length;
  bool joinedBy(String? uid) => uid != null && memberUids.contains(uid);
  bool get isSupport => kind == 'support';

  String get kindLabel => isSupport ? 'Support group' : 'Local community';

  factory CommunityGroup.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return CommunityGroup(
      id: doc.id,
      name: (d['name'] as String?) ?? 'Group',
      city: (d['city'] as String?) ?? '',
      summary: (d['summary'] as String?) ?? '',
      memberUids: List<String>.from(d['memberUids'] as List? ?? const []),
      topic: (d['topic'] as String?) ?? 'Local life',
      kind:
          (d['kind'] as String?) ??
          (((d['topic'] as String?) ?? 'local') == 'local' ||
                  (d['topic'] as String?) == 'Local life'
              ? 'local'
              : 'support'),
      createdBy: (d['createdBy'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'city': city,
    'summary': summary,
    'memberUids': memberUids,
    'memberCount': memberUids.length,
    'topic': topic,
    'kind': kind,
    'createdBy': createdBy,
  };
}

class CommunityEvent {
  const CommunityEvent({
    required this.id,
    required this.title,
    required this.body,
    required this.city,
    required this.venue,
    required this.startAt,
    required this.uid,
    required this.authorName,
    this.topic = 'Local life',
    this.groupId = '',
    this.rsvpUids = const [],
    this.seeded = false,
  });

  final String id;
  final String title;
  final String body;
  final String city;
  final String venue;
  final DateTime startAt;
  final String uid;
  final String authorName;
  final String topic;
  final String groupId;
  final List<String> rsvpUids;
  final bool seeded;

  int get rsvpCount => rsvpUids.length;
  bool going(String? userId) => userId != null && rsvpUids.contains(userId);

  String get whenLabel {
    final l = startAt.toLocal();
    final h = l.hour % 12 == 0 ? 12 : l.hour % 12;
    final m = l.minute.toString().padLeft(2, '0');
    final am = l.hour >= 12 ? 'PM' : 'AM';
    return '${l.day}/${l.month}/${l.year} $h:$m $am';
  }

  factory CommunityEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['startAt'];
    return CommunityEvent(
      id: doc.id,
      title: (d['title'] as String?) ?? 'Event',
      body: (d['body'] as String?) ?? '',
      city: (d['city'] as String?) ?? '',
      venue: (d['venue'] as String?) ?? '',
      startAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      uid: (d['uid'] as String?) ?? '',
      authorName: (d['authorName'] as String?) ?? 'Host',
      topic: (d['topic'] as String?) ?? 'Local life',
      groupId: (d['groupId'] as String?) ?? '',
      rsvpUids: List<String>.from(d['rsvpUids'] as List? ?? const []),
      seeded: d['seeded'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'body': body,
    'city': city,
    'venue': venue,
    'uid': uid,
    'authorName': authorName,
    'topic': topic,
    'groupId': groupId,
    'rsvpUids': rsvpUids,
    'rsvpCount': rsvpUids.length,
    'seeded': seeded,
  };
}
