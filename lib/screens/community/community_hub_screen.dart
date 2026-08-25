import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/community.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/background_task.dart';
import '../../services/community_service.dart';
import '../../theme/app_colors.dart';
import 'community_compose_screen.dart';
import 'community_group_screen.dart';
import 'community_post_screen.dart';

class CommunityHubScreen extends StatefulWidget {
  const CommunityHubScreen({super.key});

  @override
  State<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends State<CommunityHubScreen> {
  final _community = CommunityService();
  final _auth = AuthService();
  final _search = TextEditingController();
  String _filter = 'All';

  static const _filters = [
    ('All', 'All'),
    ('discussion', 'Discussions'),
    ('question', 'Q&A'),
    ('experience', 'Experiences'),
    ('local', 'Local'),
    ('groups', 'Groups'),
    ('events', 'Events'),
    ('following', 'Following'),
  ];

  @override
  void initState() {
    super.initState();
    runInBackground(_community.ensureSeeded(), 'seed community');
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _composeType {
    if (_filter == 'discussion' ||
        _filter == 'question' ||
        _filter == 'experience') {
      return _filter;
    }
    return 'post';
  }

  Future<void> _fab(UserProfile? profile) async {
    if (_filter == 'groups') {
      await _createGroup(profile);
      return;
    }
    if (_filter == 'events') {
      await _createEvent(profile);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CommunityComposeScreen(
          initialType: _composeType,
          city: (profile?.contact['city'] as String?) ?? '',
        ),
      ),
    );
  }

  Future<void> _createGroup(UserProfile? profile) async {
    final name = TextEditingController();
    final summary = TextEditingController();
    final city = TextEditingController(
      text: (profile?.contact['city'] as String?) ?? '',
    );
    var topic = 'Caregivers';
    var kind = 'support';
    try {
      final ok = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setModal) {
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  20 + MediaQuery.viewInsetsOf(ctx).bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Create group',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'support',
                            label: Text('Support'),
                          ),
                          ButtonSegment(value: 'local', label: Text('Local')),
                        ],
                        selected: {kind},
                        onSelectionChanged: (s) =>
                            setModal(() => kind = s.first),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: name,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: summary,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'What this group is for',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: city,
                        decoration: const InputDecoration(
                          labelText: 'City (or Global)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: topic,
                        decoration: const InputDecoration(
                          labelText: 'Topic',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final t in communityTopics)
                            DropdownMenuItem(value: t, child: Text(t)),
                        ],
                        onChanged: (v) {
                          if (v != null) setModal(() => topic = v);
                        },
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Create group'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
      if (ok != true || name.text.trim().isEmpty) return;
      final id = await _community.createGroup(
        name: name.text,
        summary: summary.text,
        city: city.text,
        topic: topic,
        kind: kind,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CommunityGroupScreen(groupId: id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      name.dispose();
      summary.dispose();
      city.dispose();
    }
  }

  Future<void> _createEvent(UserProfile? profile) async {
    final title = TextEditingController();
    final body = TextEditingController();
    final city = TextEditingController(
      text: (profile?.contact['city'] as String?) ?? '',
    );
    final venue = TextEditingController();
    var topic = 'Local life';
    var start = DateTime.now().add(const Duration(days: 7, hours: 2));
    try {
      final ok = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setModal) {
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  20 + MediaQuery.viewInsetsOf(ctx).bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Create event',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: title,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: body,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Details & access notes',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: city,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: venue,
                        decoration: const InputDecoration(
                          labelText: 'Venue or online link',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: topic,
                        decoration: const InputDecoration(
                          labelText: 'Topic',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final t in communityTopics)
                            DropdownMenuItem(value: t, child: Text(t)),
                        ],
                        onChanged: (v) {
                          if (v != null) setModal(() => topic = v);
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          start.toLocal().toString().substring(0, 16),
                        ),
                        subtitle: const Text('Date & time'),
                        trailing: const Icon(Icons.schedule),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: ctx,
                            initialDate: start,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date == null || !ctx.mounted) return;
                          final time = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.fromDateTime(start),
                          );
                          if (time == null) return;
                          setModal(() {
                            start = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        },
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Publish event'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
      if (ok != true || title.text.trim().isEmpty) return;
      await _community.createEvent(
        title: title.text,
        body: body.text,
        city: city.text,
        venue: venue.text,
        startAt: start,
        topic: topic,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      title.dispose();
      body.dispose();
      city.dispose();
      venue.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Community',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final profile = await _auth.watchCurrentProfile().first;
          if (!mounted) return;
          await _fab(profile);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: Icon(
          _filter == 'groups'
              ? Icons.group_add_outlined
              : _filter == 'events'
              ? Icons.event_outlined
              : Icons.edit_outlined,
        ),
        label: Text(
          _filter == 'groups'
              ? 'Group'
              : _filter == 'events'
              ? 'Event'
              : 'Post',
        ),
      ),
      body: StreamBuilder<UserProfile?>(
        stream: _auth.watchCurrentProfile(),
        builder: (context, profileSnap) {
          final profile = profileSnap.data;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search posts, groups, events, cities…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final f in _filters) ...[
                      FilterChip(
                        label: Text(f.$2),
                        selected: _filter == f.$1,
                        onSelected: (_) => setState(() => _filter = f.$1),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              if (profile != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Local first for ${profile.city}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: switch (_filter) {
                  'groups' => _GroupsTab(
                    community: _community,
                    profile: profile,
                    query: _search.text,
                  ),
                  'events' => _EventsTab(
                    community: _community,
                    profile: profile,
                    query: _search.text,
                  ),
                  _ => _FeedTab(
                    community: _community,
                    type: _filter,
                    query: _search.text,
                    profile: profile,
                  ),
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FeedTab extends StatelessWidget {
  const _FeedTab({
    required this.community,
    required this.type,
    required this.query,
    required this.profile,
  });

  final CommunityService community;
  final String type;
  final String query;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Set<String>>(
      stream: community.watchBlockedUids(),
      builder: (context, blockedSnap) {
        return StreamBuilder<Set<String>>(
          stream: community.watchFollowingUids(),
          builder: (context, followSnap) {
            return StreamBuilder<Set<String>>(
              stream: community.watchFollowedTopics(),
              builder: (context, topicSnap) {
                return StreamBuilder<List<CommunityPost>>(
                  stream: community.watchPosts(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting &&
                        !snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final postType = type == 'local' || type == 'following'
                        ? 'All'
                        : type;
                    final list = community.filterPosts(
                      snap.data ?? const [],
                      type: postType,
                      query: query,
                      blocked: blockedSnap.data ?? const {},
                      city: (profile?.contact['city'] as String?) ?? '',
                      localOnly: type == 'local',
                      followingOnly: type == 'following',
                      followingUids: followSnap.data ?? const {},
                      followedTopics: topicSnap.data ?? const {},
                    );
                    if (list.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            type == 'following'
                                ? 'Follow people or topics from a post to fill this feed.'
                                : 'No posts yet. Be the first.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final post = list[i];
                        return _PostCard(
                          post: post,
                          uid: community.uid,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    CommunityPostScreen(postId: post.id),
                              ),
                            );
                          },
                          onLike: () => community.toggleLike(post),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _GroupsTab extends StatefulWidget {
  const _GroupsTab({
    required this.community,
    required this.profile,
    required this.query,
  });

  final CommunityService community;
  final UserProfile? profile;
  final String query;

  @override
  State<_GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<_GroupsTab> {
  String _kind = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Wrap(
            spacing: 8,
            children: [
              for (final k in [
                ('all', 'All'),
                ('support', 'Support groups'),
                ('local', 'Local communities'),
              ])
                ChoiceChip(
                  label: Text(k.$2),
                  selected: _kind == k.$1,
                  onSelected: (_) => setState(() => _kind = k.$1),
                ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<CommunityGroup>>(
            stream: widget.community.watchGroups(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting &&
                  !snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final q = widget.query.trim().toLowerCase();
              var list = snap.data ?? const <CommunityGroup>[];
              if (_kind != 'all') {
                list = list.where((g) => g.kind == _kind).toList();
              }
              if (q.isNotEmpty) {
                list = list
                    .where(
                      (g) =>
                          g.name.toLowerCase().contains(q) ||
                          g.city.toLowerCase().contains(q) ||
                          g.summary.toLowerCase().contains(q) ||
                          g.topic.toLowerCase().contains(q),
                    )
                    .toList();
              }
              list = [...list]
                ..sort(
                  (a, b) => widget.community
                      .localScore(b, widget.profile)
                      .compareTo(
                        widget.community.localScore(a, widget.profile),
                      ),
                );
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    'No groups match that search.',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final g = list[i];
                  final joined = g.joinedBy(widget.community.uid);
                  final score = widget.community.localScore(g, widget.profile);
                  return Card(
                    child: ListTile(
                      title: Text(
                        g.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        '${g.kindLabel} · ${g.city} · ${g.topic}\n'
                        '${g.memberCount} members · $score% local match\n${g.summary}',
                      ),
                      isThreeLine: true,
                      trailing: TextButton(
                        onPressed: () => widget.community.toggleJoin(g),
                        child: Text(joined ? 'Leave' : 'Join'),
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CommunityGroupScreen(groupId: g.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EventsTab extends StatelessWidget {
  const _EventsTab({
    required this.community,
    required this.profile,
    required this.query,
  });

  final CommunityService community;
  final UserProfile? profile;
  final String query;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CommunityEvent>>(
      stream: community.watchEvents(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final q = query.trim().toLowerCase();
        final city = ((profile?.contact['city'] as String?) ?? '')
            .toLowerCase();
        var list = snap.data ?? const <CommunityEvent>[];
        if (q.isNotEmpty) {
          list = list
              .where(
                (e) =>
                    e.title.toLowerCase().contains(q) ||
                    e.city.toLowerCase().contains(q) ||
                    e.body.toLowerCase().contains(q) ||
                    e.venue.toLowerCase().contains(q),
              )
              .toList();
        }
        list = [...list]
          ..sort((a, b) {
            final aLocal =
                city.isNotEmpty && a.city.toLowerCase().contains(city) ? 0 : 1;
            final bLocal =
                city.isNotEmpty && b.city.toLowerCase().contains(city) ? 0 : 1;
            if (aLocal != bLocal) return aLocal.compareTo(bLocal);
            return a.startAt.compareTo(b.startAt);
          });
        if (list.isEmpty) {
          return Center(
            child: Text(
              'No events yet. Create a meetup or workshop.',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final e = list[i];
            final mine = e.going(community.uid);
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${e.whenLabel} · ${e.city}\n${e.venue} · ${e.topic}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.body,
                      style: GoogleFonts.plusJakartaSans(height: 1.35),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${e.rsvpCount} going · ${e.authorName}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () => community.toggleRsvp(e),
                          style: FilledButton.styleFrom(
                            backgroundColor: mine
                                ? const Color(0xFF22C55E)
                                : AppColors.primary,
                          ),
                          child: Text(mine ? 'Going' : 'RSVP'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.uid,
    required this.onTap,
    required this.onLike,
  });

  final CommunityPost post;
  final String? uid;
  final VoidCallback onTap;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final liked = post.likedByUser(uid);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      post.typeLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    post.topic,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    post.city,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                post.title,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                post.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    post.authorName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: onLike,
                    child: Row(
                      children: [
                        Icon(
                          liked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 18,
                          color: liked ? AppColors.sos : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.likeCount}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.replyCount}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
