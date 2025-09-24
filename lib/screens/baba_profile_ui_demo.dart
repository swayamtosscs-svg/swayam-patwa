import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../models/baba_page_model.dart';
import '../models/baba_page_post_model.dart';
import '../services/baba_page_post_service.dart';
import '../services/baba_page_service.dart';
import '../providers/auth_provider.dart';
import 'baba_page_post_creation_screen.dart';
import 'baba_pages_screen.dart';
import 'baba_page_reel_upload_screen.dart';

class BabaProfileUiDemoScreen extends StatefulWidget {
  final BabaPage? babaPage; // when provided, bind to real data
  const BabaProfileUiDemoScreen({super.key, this.babaPage});

  @override
  State<BabaProfileUiDemoScreen> createState() => _BabaProfileUiDemoScreenState();
}

class _BabaProfileUiDemoScreenState extends State<BabaProfileUiDemoScreen> {
  int selectedSegment = 0;

  List<BabaPagePost> _posts = [];
  bool _loadingPosts = false;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final page = widget.babaPage;
    final hasRealData = page != null;
    // Load posts when bound to real page
    if (hasRealData && !_loadingPosts && _posts.isEmpty) {
      _fetchPosts(page!);
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      extendBody: true,
      body: SafeArea(
        child: DefaultTextStyle.merge(
          style: GoogleFonts.poppins(),
          child: Column(
            children: [
              // Header (avatar, gradient background, name, tags)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // rounded gradient card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEBF6FF), Color(0xFFF5E9FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.only(top: 72, bottom: 18, left: 18, right: 18),
                    child: Column(
                      children: [
                        const SizedBox(height: 48),
                        Text(
                          hasRealData ? page.name : 'Baba Sayam',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(hasRealData ? page.location : 'Haridwar, India', style: TextStyle(color: Colors.grey[700])),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // tags
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildTag('[ ${hasRealData ? page.religion : 'Hindsium'} ]', Colors.orange.shade100, Colors.orange.shade700),
                            _buildTag('[ Yoga ]', Colors.blue.shade100, Colors.blue.shade700),
                            _buildTag('Spiritual Leader', Colors.green.shade100, Colors.green.shade800),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // pills (Follow / Message) inside header card
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _FollowButton(page: page),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                side: BorderSide(color: Colors.grey.shade300),
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
                              ),
                              child: Text('Message', style: TextStyle(color: Colors.grey.shade800)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Back arrow and top-right icons
                  Positioned(
                    left: 28,
                    top: 20,
                    child: GestureDetector(
                      onTap: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const BabaPagesScreen()),
                            (route) => false,
                          );
                        }
                      },
                      child: const Icon(Icons.arrow_back_ios_new, size: 20),
                    ),
                  ),
                  const Positioned(
                    right: 30,
                    top: 16,
                    child: Row(
                      children: [
                        Icon(Icons.settings_outlined, size: 20),
                        SizedBox(width: 10),
                        Icon(Icons.edit_outlined, size: 20),
                      ],
                    ),
                  ),

                  // Circular avatar with glow (overlapping)
                  Positioned(
                    top: -14,
                    left: (screenW / 2) - 62,
                    child: _glowingAvatar(
                      imageUrl: hasRealData && page.avatar.isNotEmpty
                          ? page.avatar
                          : 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=800&q=80&auto=format&fit=crop',
                      size: 124,
                    ),
                  ),
                ],
              ),

              // White card content below header
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 18),
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 90),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('About', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text(
                          'Yoga guru and spiritual leader. Guiding people to peace & balance.\n✨ "Peace begins with you."',
                          style: TextStyle(color: Colors.grey[700], height: 1.4),
                        ),
                        const SizedBox(height: 18),

                        const Text('Statistics', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _smallStatCard(icon: Icons.person, value: hasRealData ? '${page.followersCount}' : '2', label: 'Followers', color: Colors.orange.shade100),
                            _smallStatCard(icon: Icons.article_outlined, value: hasRealData ? '${page.postsCount}' : '3', label: 'Posts', color: Colors.blue.shade100),
                            _smallStatCard(icon: Icons.videocam_outlined, value: hasRealData ? '${page.videosCount}' : '0', label: 'Videos', color: Colors.green.shade100),
                            _smallStatCard(icon: Icons.auto_stories_outlined, value: hasRealData ? '${page.storiesCount}' : '0', label: 'Stories', color: Colors.purple.shade100),
                          ],
                        ),
                        const SizedBox(height: 18),

                        const Text('Website', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _launchUrl(hasRealData && (page.website.isNotEmpty) ? page.website : 'https://baba-ramdev.com'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.language, size: 16),
                                SizedBox(width: 8),
                                Text('Open website', style: TextStyle(decoration: TextDecoration.underline)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        _segmentControl(),

                        const SizedBox(height: 12),

                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1,
                          ),
                          itemCount: _loadingPosts ? 6 : (hasRealData ? _posts.length : 8),
                          itemBuilder: (context, i) {
                            if (_loadingPosts) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              );
                            }
                            if (hasRealData && i < _posts.length) {
                              final post = _posts[i];
                              final mediaUrl = post.media.isNotEmpty ? post.media.first.url : null;
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: mediaUrl != null
                                    ? Image.network(mediaUrl, fit: BoxFit.cover)
                                    : Container(color: Colors.grey.shade200),
                              );
                            }
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network('https://images.unsplash.com/photo-1508672019048-805c876b67e2?w=800&q=80&auto=format&fit=crop', fit: BoxFit.cover),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateBottomSheet(context),
        backgroundColor: Colors.orange.shade400,
        elevation: 6,
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTag(String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
    );
  }

  static Widget _glowingAvatar({required String imageUrl, double size = 100}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.white.withOpacity(0.9), blurRadius: 18, spreadRadius: 6),
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: Colors.white,
        backgroundImage: NetworkImage(imageUrl),
      ),
    );
  }

  Widget _smallStatCard({required IconData icon, required String value, required String label, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, size: 18),
                const Spacer(),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(label, style: const TextStyle(fontSize: 12)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _segmentControl() {
    final labels = ['Posts', 'Videos', 'Stories', 'Events / Live Sessions'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: List.generate(labels.length, (i) {
              final isSelected = i == selectedSegment;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => selectedSegment = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: isSelected
                          ? [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4))]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 13,
                          color: isSelected ? Colors.black87 : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      color: Colors.white,
      elevation: 12,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 62,
        child: Row(
          children: [
            const SizedBox(width: 12),
            _navItem(icon: Icons.home_outlined, label: 'Posts', onTap: () {}),
            _navItem(icon: Icons.dashboard_outlined, label: 'Dupeos', onTap: () {}),
            const Spacer(),
            _navItem(icon: Icons.calendar_today_outlined, label: 'Chirghunt', onTap: () {}),
            _navItem(icon: Icons.person_outline, label: 'Profile', onTap: () {}),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _navItem({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 4),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link')));
    }
  }

  void _openCreateBottomSheet(BuildContext context) {
    final page = widget.babaPage;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Create', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _createTile(
                        icon: Icons.grid_3x3_outlined,
                        label: 'Post',
                        color: Colors.blue.shade100,
                        onTap: page == null ? null : () async {
                          Navigator.pop(context);
                          final ok = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BabaPagePostCreationScreen(babaPage: page),
                            ),
                          );
                          if (ok == true) {
                            _fetchPosts(page);
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      _createTile(
                        icon: Icons.video_call_outlined,
                        label: 'Reel',
                        color: Colors.green.shade100,
                        onTap: page == null ? null : () async {
                          Navigator.pop(context);
                          final ok = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BabaPageReelUploadScreen(babaPage: page),
                            ),
                          );
                          if (ok == true) {
                            // Refresh reels if needed
                            print('Baba Ji reel uploaded successfully');
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      _createTile(
                        icon: Icons.auto_stories_outlined,
                        label: 'Story',
                        color: Colors.orange.shade100,
                        onTap: () {
                          // TODO: open story upload screen
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _createTile({required IconData icon, required String label, required Color color, VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchPosts(BabaPage page) async {
    try {
      setState(() => _loadingPosts = true);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.authToken;
      if (token == null) {
        setState(() => _loadingPosts = false);
        return;
      }
      final resp = await BabaPagePostService.getBabaPagePosts(
        babaPageId: page.id,
        token: token,
        page: 1,
        limit: 12,
      );
      if (!mounted) return;
      setState(() {
        _posts = resp.posts;
        _loadingPosts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingPosts = false);
    }
  }
}

class _FollowButton extends StatefulWidget {
  final BabaPage? page;
  const _FollowButton({required this.page});

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  bool _loading = false;
  bool _isFollowing = false;
  int _followers = 0;

  @override
  void initState() {
    super.initState();
    final page = widget.page;
    if (page != null) {
      _isFollowing = page.isFollowing;
      _followers = page.followersCount;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRealData = widget.page != null;
    return ElevatedButton(
      onPressed: !_loading && hasRealData ? _toggleFollow : null,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        backgroundColor: Colors.white,
        elevation: 0,
        side: BorderSide(color: Colors.blue.shade200),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
      ),
      child: Text(_isFollowing ? 'Following ($_followers)' : 'Follow ($_followers)',
          style: TextStyle(color: Colors.blue.shade800)),
    );
  }

  Future<void> _toggleFollow() async {
    final page = widget.page!;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.authToken;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login first')));
      return;
    }
    setState(() => _loading = true);
    try {
      if (_isFollowing) {
        final resp = await BabaPageService.unfollowBabaPage(pageId: page.id, token: token);
        if (resp.success) {
          setState(() {
            _isFollowing = false;
            _followers = (_followers - 1).clamp(0, 1 << 31);
          });
        }
      } else {
        final resp = await BabaPageService.followBabaPage(pageId: page.id, token: token);
        if (resp.success) {
          setState(() {
            _isFollowing = true;
            _followers = _followers + 1;
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}


