import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/community.dart';
import '../../services/community_service.dart';
import '../../theme/app_colors.dart';

class CommunityPostScreen extends StatefulWidget {
  const CommunityPostScreen({super.key, required this.postId});

  final String postId;

  @override
  State<CommunityPostScreen> createState() => _CommunityPostScreenState();
}

class _CommunityPostScreenState extends State<CommunityPostScreen> {
  final _community = CommunityService();
  final _reply = TextEditingController();
  bool _busy = false;
  String _replyParentId = '';
  String _replyHint = 'Write a comment…';

  // Held as fields: building these in `build` handed each rebuild a new stream,
  // which tore down and re-subscribed all three listeners.
  late final Stream<List<CommunityPost>> _posts = _community.watchPosts();
  late final Stream<Set<String>> _following = _community.watchFollowingUids();
  late final Stream<Set<String>> _topics = _community.watchFollowedTopics();

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _reply.text.trim();
    if (text.isEmpty) return;
    setState(() => _busy = true);
    try {
      await _community.addReply(widget.postId, text, parentId: _replyParentId);
      _reply.clear();
      _replyParentId = '';
      _replyHint = 'Write a comment…';
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _report(CommunityPost post) async {
    await _community.flagPost(post.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reported. Hidden after 3 reports.')),
    );
  }

  Future<void> _block(CommunityPost post) async {
    await _community.blockUser(post.uid);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${post.authorName} blocked from your feed')),
    );
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CommunityPost>>(
      stream: _posts,
      builder: (context, snap) {
        CommunityPost? post;
        for (final p in snap.data ?? const <CommunityPost>[]) {
          if (p.id == widget.postId) post = p;
        }
        if (post == null) {
          // A missing post used to spin forever, which looked identical whether
          // the feed was loading, the read failed, or the post was deleted.
          final loading =
              snap.connectionState == ConnectionState.waiting && !snap.hasData;
          return Scaffold(
            appBar: AppBar(title: const Text('Post')),
            body: loading
                ? const Center(child: CircularProgressIndicator())
                : _PostUnavailable(failed: snap.hasError),
          );
        }
        final p = post;
        return StreamBuilder<Set<String>>(
          stream: _following,
          builder: (context, followSnap) {
            return StreamBuilder<Set<String>>(
              stream: _topics,
              builder: (context, topicSnap) {
                final following = followSnap.data ?? const <String>{};
                final topics = topicSnap.data ?? const <String>{};
                final followsAuthor = following.contains(p.uid);
                final followsTopic = topics.contains(p.topic);
                final liked = p.likedByUser(_community.uid);
                return Scaffold(
                  backgroundColor: AppColors.background,
                  appBar: AppBar(
                    title: Text(
                      p.typeLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    actions: [
                      PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'report') _report(p);
                          if (v == 'block') _block(p);
                          if (v == 'follow') {
                            await _community.toggleFollowUser(
                              p.uid,
                              follow: !followsAuthor,
                            );
                          }
                          if (v == 'topic') {
                            await _community.toggleFollowTopic(
                              p.topic,
                              follow: !followsTopic,
                            );
                          }
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'follow',
                            child: Text(
                              followsAuthor
                                  ? 'Unfollow ${p.authorName}'
                                  : 'Follow ${p.authorName}',
                            ),
                          ),
                          PopupMenuItem(
                            value: 'topic',
                            child: Text(
                              followsTopic
                                  ? 'Unfollow topic ${p.topic}'
                                  : 'Follow topic ${p.topic}',
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'report',
                            child: Text('Report post'),
                          ),
                          const PopupMenuItem(
                            value: 'block',
                            child: Text('Block author'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  body: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          children: [
                            Text(
                              p.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${p.authorName} · ${p.city} · ${p.topic}',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              p.body,
                              style: GoogleFonts.plusJakartaSans(height: 1.4),
                            ),
                            if (p.isPoll) ...[
                              const SizedBox(height: 16),
                              _PollBox(
                                post: p,
                                uid: _community.uid,
                                onVote: (i) => _community.vote(p.id, i),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                IconButton(
                                  tooltip: liked ? 'Unlike' : 'Like',
                                  onPressed: () => _community.toggleLike(p),
                                  icon: Icon(
                                    liked
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: liked
                                        ? AppColors.sos
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  '${p.likeCount} likes · ${p.replyCount} comments',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                ActionChip(
                                  label: Text(
                                    followsAuthor ? 'Following' : 'Follow',
                                  ),
                                  onPressed: () => _community.toggleFollowUser(
                                    p.uid,
                                    follow: !followsAuthor,
                                  ),
                                ),
                                ActionChip(
                                  label: Text(
                                    followsTopic
                                        ? 'Topic followed'
                                        : 'Follow ${p.topic}',
                                  ),
                                  onPressed: () => _community.toggleFollowTopic(
                                    p.topic,
                                    follow: !followsTopic,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Comments',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            StreamBuilder<List<CommunityReply>>(
                              stream: _community.watchReplies(p.id),
                              builder: (context, replySnap) {
                                final replies =
                                    replySnap.data ?? const <CommunityReply>[];
                                if (replies.isEmpty) {
                                  return Text(
                                    'No comments yet. Share what helped you.',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppColors.textSecondary,
                                    ),
                                  );
                                }
                                final roots = replies
                                    .where((r) => r.parentId.isEmpty)
                                    .toList();
                                List<CommunityReply> kids(String id) => replies
                                    .where((r) => r.parentId == id)
                                    .toList();
                                return Column(
                                  children: [
                                    for (final r in roots) ...[
                                      _CommentTile(
                                        reply: r,
                                        onReply: () {
                                          setState(() {
                                            _replyParentId = r.id;
                                            _replyHint =
                                                'Reply to ${r.authorName}…';
                                          });
                                        },
                                      ),
                                      for (final c in kids(r.id))
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 24,
                                          ),
                                          child: _CommentTile(
                                            reply: c,
                                            nested: true,
                                            onReply: () {
                                              setState(() {
                                                _replyParentId = r.id;
                                                _replyHint =
                                                    'Reply to ${c.authorName}…';
                                              });
                                            },
                                          ),
                                        ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _reply,
                                  decoration: InputDecoration(
                                    hintText: _replyHint,
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                onPressed: _busy ? null : _send,
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                ),
                                icon: const Icon(Icons.send_rounded),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.reply,
    required this.onReply,
    this.nested = false,
  });

  final CommunityReply reply;
  final VoidCallback onReply;
  final bool nested;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: nested ? const Color(0xFFF8F9FB) : Colors.white,
      child: ListTile(
        title: Text(
          reply.authorName,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        subtitle: Text(reply.body),
        trailing: TextButton(onPressed: onReply, child: const Text('Reply')),
      ),
    );
  }
}

class _PollBox extends StatelessWidget {
  const _PollBox({required this.post, required this.uid, required this.onVote});

  final CommunityPost post;
  final String? uid;
  final ValueChanged<int> onVote;

  @override
  Widget build(BuildContext context) {
    final total = post.pollCounts.fold<int>(0, (a, b) => a + b);
    final voted = post.hasVoted(uid);
    return Column(
      children: [
        for (var i = 0; i < post.pollOptions.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: voted ? null : () => onVote(i),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        post.pollOptions[i],
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      total == 0
                          ? '0'
                          : '${((post.pollCounts[i] / total) * 100).round()}%',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            voted ? 'You already voted · $total votes' : '$total votes',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _PostUnavailable extends StatelessWidget {
  const _PostUnavailable({required this.failed});

  /// Distinguishes "we could not load it" from "it is gone".
  final bool failed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              failed ? Icons.cloud_off_rounded : Icons.forum_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              failed ? 'Could not load this post' : 'Post unavailable',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              failed
                  ? 'Check your connection and try again.'
                  : 'It may have been deleted or hidden by moderation.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Back to feed'),
            ),
          ],
        ),
      ),
    );
  }
}
