import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'models/user_model.dart';
import 'models/post_model.dart';
import 'providers/auth_provider.dart';
import 'screens/followers_screen.dart';
import 'screens/following_screen.dart';
import 'screens/post_full_view_screen.dart';
import 'utils/snackbar_helper.dart';
import 'services/user_media_service.dart';
import 'services/api_service.dart';
import 'screens/search_screen.dart';
import 'screens/add_options_screen.dart';
import 'screens/home_screen.dart';
import 'screens/baba_pages_screen.dart';
import 'screens/live_stream_screen.dart';

class ProfileUI extends StatefulWidget {
  const ProfileUI({super.key});

  @override
  State<ProfileUI> createState() => _ProfileUIState();
}

class _ProfileUIState extends State<ProfileUI> {
  late Future<UserMediaResponse> _mediaFuture;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _gridSectionKey = GlobalKey();
  int _selectedTab = 0; // 0 = Posts, 1 = Reels, 2 = Tagged
  final Set<String> _deletedMediaIds = <String>{};

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _mediaFuture = UserMediaService.getUserMedia(userId: auth.userProfile?.id ?? '');
  }

  void _refreshMedia() {
    setState(() {
      // Don't clear deleted items - keep them hidden permanently
      final auth = Provider.of<AuthProvider>(context, listen: false);
      _mediaFuture = UserMediaService.getUserMedia(userId: auth.userProfile?.id ?? '');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.userProfile;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Signup page bg.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Top Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.spa, color: Colors.white, size: 20),
                        Text(
                          'Pilgrim of Peace',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showLogoutDialog(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.logout,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Profile Header Card
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      child: GestureDetector(
                        onTap: () {}, // Allow taps to pass through
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08), // Semi-transparent white to show background
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, spreadRadius: 5, offset: const Offset(0, 10)),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                child: Column(
                                  children: [
                                    // Avatar
                                    CircleAvatar(
                                      radius: 44,
                                      backgroundColor: Colors.grey.shade300,
                                      backgroundImage: (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty)
                                          ? NetworkImage(user.profileImageUrl!)
                                          : null,
                                      child: (user.profileImageUrl == null || user.profileImageUrl!.isEmpty)
                                          ? const Icon(Icons.person, color: Colors.white, size: 40)
                                          : null,
                                    ),
                                    const SizedBox(height: 12),

                                    // Name & username
                                    Text(
                                      user.fullName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '@${user.username ?? 'user'}',
                                      style: const TextStyle(color: Colors.black87),
                                    ),
                                    const SizedBox(height: 18),

                                    // Stats row
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _StatItem(value: '${user.postsCount}', label: 'Posts', onTap: () {}),
                                        _StatItem(value: '3', label: 'Reels', onTap: () { setState(() { _selectedTab = 1; }); _scrollToGrid(); }),
                                        _StatItem(value: '${user.followersCount}', label: 'Followers', onTap: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (_) => FollowersScreen(userId: user.id)));
                                        }),
                                        _StatItem(value: '${user.followingCount}', label: 'Following', onTap: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (_) => FollowingScreen(userId: user.id)));
                                        }),
                                      ],
                                    ),
                                    const SizedBox(height: 18),

                                    // Bio
                                    Text(
                                      user.bio == null || user.bio!.isEmpty
                                          ? 'Write something about yourself'
                                          : user.bio!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                                    ),
                                    const SizedBox(height: 18),

                                    // Tabs
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: _TabButton(
                                              label: 'Posts',
                                              icon: Icons.yard_outlined,
                                              isSelected: _selectedTab == 0,
                                              onTap: () {
                                                setState(() { _selectedTab = 0; });
                                              },
                                            ),
                                          ),
                                          Expanded(
                                            child: _TabButton(
                                              label: 'Reels',
                                              icon: Icons.play_circle_outline,
                                              isSelected: _selectedTab == 1,
                                              onTap: () {
                                                setState(() { _selectedTab = 1; });
                                                _scrollToGrid();
                                              },
                                            ),
                                          ),
                                          Expanded(
                                            child: _TabButton(
                                              label: 'Tagged',
                                              icon: Icons.book_outlined,
                                              isSelected: _selectedTab == 2,
                                              onTap: () {
                                                setState(() { _selectedTab = 2; });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // Grid Images from API (switch by selected tab)
                                    FutureBuilder<UserMediaResponse>(
                                      future: _mediaFuture,
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Padding(
                                            padding: EdgeInsets.all(24),
                                            child: CircularProgressIndicator(),
                                          );
                                        }
                                        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.success) {
                                          return const Text('Failed to load media', style: TextStyle(color: Colors.red));
                                        }
                                        final posts = snapshot.data!.posts
                                            .where((p) => (p.imageUrl?.isNotEmpty == true) || (p.videoUrl?.isNotEmpty == true))
                                            .toList();
                                        final reels = snapshot.data!.reels
                                            .where((p) => (p.videoUrl?.isNotEmpty == true) || (p.imageUrl?.isNotEmpty == true))
                                            .toList();
                                        final rawItems = _selectedTab == 0
                                            ? posts
                                            : _selectedTab == 1
                                              ? reels
                                              : <Post>[];
                                        final mediaItems = rawItems
                                            .where((p) => !_deletedMediaIds.contains(p.id))
                                            .where((p) => (p.imageUrl?.isNotEmpty == true) || (p.videoUrl?.isNotEmpty == true))
                                            .toList();
                                        return Container(
                                          key: _gridSectionKey,
                                          child: GridView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            crossAxisSpacing: 10,
                                            mainAxisSpacing: 10,
                                          ),
                                          itemCount: mediaItems.length,
                                          itemBuilder: (context, i) {
                                            final post = mediaItems[i];
                                            return _gridTile(post);
                                          },
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  Future<void> _scrollToGrid() async {
    final contextForGrid = _gridSectionKey.currentContext;
    if (contextForGrid != null) {
      await Scrollable.ensureVisible(
        contextForGrid,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
      return;
    }
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _gridImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: url.isNotEmpty
          ? Image.network(url, fit: BoxFit.cover)
          : Container(color: Colors.grey.shade200),
    );
  }

  Widget _gridTile(Post post) {
    final isVideo = (post.type == PostType.video || post.type == PostType.reel) &&
        (post.videoUrl != null && post.videoUrl!.isNotEmpty);

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PostFullViewScreen(post: post)));
      },
      onLongPress: () {
        _maybeShowDeleteOptions(post);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isVideo)
              Container(
                color: Colors.black,
                child: const Center(
                  child: Icon(Icons.play_circle_filled, color: Colors.white, size: 36),
                ),
              )
            else
              (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                  ? Image.network(
                      post.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) {
                        // If image fails to load, mark as deleted and rebuild
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _deletedMediaIds.add(post.id);
                            });
                          }
                        });
                        return Container(
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey, size: 28),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(Icons.image_not_supported, color: Colors.grey, size: 28),
                      ),
                    ),
          ],
        ),
      ),
    );
  }

  void _maybeShowDeleteOptions(Post post) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = auth.userProfile?.id;
    final ownerId = post.userId;
    if (currentUserId == null) return;
    if (ownerId != currentUserId && ownerId != 'current_user') return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(post);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(Post post) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete'),
        content: const Text('Are you sure you want to delete this media?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePost(post);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(Post post) async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.authToken;
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to delete')));
        return;
      }

      // Immediately add to deleted set for instant UI update
      setState(() {
        _deletedMediaIds.add(post.id);
      });

      // Post.id is mediaId for user uploads
      final resp = await ApiService.deleteMedia(mediaId: post.id, token: token);
      if (resp['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted successfully')));
        // Refresh the media data to get updated counts
        _refreshMedia();
      } else {
        // If API call failed, remove from deleted set
        setState(() {
          _deletedMediaIds.remove(post.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp['message'] ?? 'Delete failed')));
      }
    } catch (e) {
      // If error occurred, remove from deleted set
      setState(() {
        _deletedMediaIds.remove(post.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home,
                label: 'Home',
                isSelected: false,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
                },
              ),
              _buildNavItem(
                icon: Icons.search,
                label: 'Search',
                isSelected: false,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
                },
              ),
              _buildNavItem(
                icon: Icons.add,
                label: 'Add',
                isSelected: false,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddOptionsScreen()));
                },
              ),
              _buildNavItem(
                icon: Icons.self_improvement,
                label: 'Baba Ji',
                isSelected: false,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BabaPagesScreen()));
                },
              ),
              _buildNavItem(
                icon: Icons.live_tv,
                label: 'Live Darshan',
                isSelected: false,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveStreamScreen()));
                },
              ),
              _buildNavItem(
                icon: Icons.person,
                label: 'Account',
                isSelected: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF8B2E2E) : Colors.black54,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? const Color(0xFF8B2E2E) : Colors.black54,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout,
                color: Colors.red.shade600,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performLogout(context);
              },
              child: Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Show immediate feedback
      if (context.mounted) {
        SnackBarHelper.showInfo(context, 'Logging out...');
      }

      // Perform logout immediately (no loading dialog)
      await authProvider.logout();

      // Navigate to signup screen immediately
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/signup', (route) => false);
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        SnackBarHelper.showError(context, 'Logout failed: $e');
      }
    }
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback? onTap;
  const _StatItem({required this.value, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool highlight;
  final VoidCallback? onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    this.isSelected = false,
    this.highlight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (highlight) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF59B6AC),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
        child: const Center(
          child: Text('Connect & Follow',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFBFDFED) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))]
              : null,
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.black : Colors.grey.shade700,
              )),
        ),
      ),
    );
  }
}