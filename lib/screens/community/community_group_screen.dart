import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/community.dart';
import '../../services/community_service.dart';
import '../../theme/app_colors.dart';
import 'community_compose_screen.dart';
import 'community_post_screen.dart';

class CommunityGroupScreen extends StatefulWidget {
  const CommunityGroupScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<CommunityGroupScreen> createState() => _CommunityGroupScreenState();
}

class _CommunityGroupScreenState extends State<CommunityGroupScreen> {
  final _community = CommunityService();

  Future<void> _compose(CommunityGroup group) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CommunityComposeScreen(
          initialType: 'discussion',
          groupId: group.id,
          city: group.city == 'Global' ? '' : group.city,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CommunityGroup>>(
      stream: _community.watchGroups(),
      builder: (context, groupSnap) {
        CommunityGroup? group;
        for (final g in groupSnap.data ?? const <CommunityGroup>[]) {
          if (g.id == widget.groupId) group = g;
        }
        if (group == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Group')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final g = group;
        final joined = g.joinedBy(_community.uid);
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              g.name,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _compose(g),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Post'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            children: [
              Text(
                '${g.kindLabel} · ${g.city} · ${g.topic}',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(g.summary, style: GoogleFonts.plusJakartaSans(height: 1.4)),
              const SizedBox(height: 8),
              Text(
                '${g.memberCount} members',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => _community.toggleJoin(g),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: Text(joined ? 'Leave group' : 'Join group'),
              ),
              const SizedBox(height: 20),
              Text(
                'Group feed',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<CommunityPost>>(
                stream: _community.watchPosts(),
                builder: (context, snap) {
                  final posts = _community.filterPosts(
                    snap.data ?? const [],
                    type: 'All',
                    query: '',
                    blocked: const {},
                    groupId: g.id,
                  );
                  if (posts.isEmpty) {
                    return Text(
                      'No posts in this group yet. Start a discussion.',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textSecondary,
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final p in posts)
                        Card(
                          child: ListTile(
                            title: Text(p.title),
                            subtitle: Text(
                              '${p.typeLabel} · ${p.likeCount} likes · ${p.replyCount} replies',
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      CommunityPostScreen(postId: p.id),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
