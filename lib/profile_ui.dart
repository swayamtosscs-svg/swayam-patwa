import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'models/user_model.dart';
import 'models/post_model.dart';
import 'providers/auth_provider.dart';
import 'screens/followers_screen.dart';
import 'screens/following_screen.dart';
import 'screens/post_full_view_screen.dart';
import 'screens/post_slider_screen.dart';
import 'utils/snackbar_helper.dart';
import 'services/user_media_service.dart';
import 'services/api_service.dart';
import 'services/local_storage_service.dart';
import 'screens/search_screen.dart';
import 'screens/add_options_screen.dart';
import 'screens/home_screen.dart';
import 'screens/baba_pages_screen.dart';
import 'screens/live_stream_screen.dart';
import 'screens/reels_screen.dart';
import 'screens/profile_edit_screen.dart';
import 'screens/story_upload_screen.dart';
import 'widgets/dp_widget.dart';

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
    _mediaFuture = UserMediaService.forceRefreshUserMedia(userId: auth.userProfile?.id ?? '');
    
    // Listen for media updates to refresh post counts automatically
    UserMediaService.onMediaUpdated = (String userId) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (userId == auth.userProfile?.id && mounted) {
        print('ProfileUI: Media updated for current user, refreshing...');
        _refreshMedia();
      }
    };
  }

  void _refreshMedia() {
    setState(() {
      // Don't clear deleted items - keep them hidden permanently
      final auth = Provider.of<AuthProvider>(context, listen: false);
      _mediaFuture = UserMediaService.forceRefreshUserMedia(userId: auth.userProfile?.id ?? '');
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
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Signup page bg.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                // Blur effect overlay
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
                // Spiritual symbols overlay
                _buildSpiritualSymbolsOverlay(),
                SafeArea(
                  child: Column(
                    children: [
                      // Custom App Bar (Messages screen style)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.black),
                              onPressed: () {
                                // Navigate back to home screen using bottom navigation
                                final navigator = Navigator.of(context);
                                navigator.pushNamedAndRemoveUntil('/home', (route) => false);
                              },
                            ),
                            const Expanded(
                              child: Text(
                                'Account',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: 20,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.search, color: Colors.black),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
                              },
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.black),
                              tooltip: 'More options',
                              onSelected: (String value) {
                                if (value == 'edit_profile') {
                                  _navigateToEditProfile(user);
                                } else if (value == 'logout') {
                                  _showLogoutDialog(context);
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                const PopupMenuItem<String>(
                                  value: 'edit_profile',
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, color: Color(0xFF1A1A1A), size: 20),
                                        SizedBox(width: 12),
                                        Text(
                                          'Edit Profile',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF1A1A1A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const PopupMenuDivider(),
                                const PopupMenuItem<String>(
                                  value: 'logout',
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Icon(Icons.logout, color: Color(0xFFE53E3E), size: 20),
                                        SizedBox(width: 12),
                                        Text(
                                          'Logout',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFFE53E3E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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
                                        // Avatar with story add overlay; DP editing moved to Edit Profile
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                        Container(
                                          width: 96,
                                          height: 96,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [Color(0xFF00C853), Color(0xFF00E676)],
                                            ),
                                          ),
                                          child: Center(
                                            child: Container(
                                              width: 92,
                                              height: 92,
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: DPWidget(
                                                  currentImageUrl: user.profileImageUrl,
                                                  userId: user.id,
                                                  token: auth.authToken ?? '',
                                                  userName: user.fullName,
                                                  onImageChanged: (String newImageUrl) async {
                                                    final updatedUser = user.copyWith(
                                                      profileImageUrl: newImageUrl.isEmpty ? null : newImageUrl,
                                                    );
                                                    auth.updateLocalUserProfile(updatedUser);
                                                  },
                                                  size: 88,
                                                  borderColor: Colors.white,
                                                  showEditButton: false,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: GestureDetector(
                                            onTap: () {
                                              final token = auth.authToken;
                                              if (token == null || token.isEmpty) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Please login to add a story')),
                                                );
                                                return;
                                              }
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => StoryUploadScreen(token: token),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: const Color(0xFF00C853), width: 3),
                                              ),
                                              child: const Center(
                                                child: Icon(Icons.add, color: Color(0xFF00C853), size: 18),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
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

                                    // Stats row with real data
                                    FutureBuilder<UserMediaResponse>(
                                      future: _mediaFuture,
                                      builder: (context, snapshot) {
                                        int postsCount = 0;
                                        int reelsCount = 0;
                                        
                                        if (snapshot.hasData && snapshot.data!.success) {
                                          postsCount = snapshot.data!.posts.length;
                                          reelsCount = snapshot.data!.reels.length;
                                          print('ProfileUI: REAL post count: $postsCount, REAL reel count: $reelsCount for ${auth.userProfile?.username}');
                                        }
                                        
                                        return Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          children: [
                                            _StatItem(value: postsCount.toString(), label: 'Posts', onTap: () {}),
                                            _StatItem(value: reelsCount.toString(), label: 'Reels', onTap: () { setState(() { _selectedTab = 1; }); _scrollToGrid(); }),
                                            FutureBuilder<List<Map<String, dynamic>>>(
                                              future: Provider.of<AuthProvider>(context, listen: false).getFollowersForUser(user.id),
                                              builder: (context, followersSnapshot) {
                                                int realFollowersCount = user.followersCount;
                                                if (followersSnapshot.hasData) {
                                                  realFollowersCount = followersSnapshot.data!.length;
                                                }
                                                return _StatItem(
                                                  value: realFollowersCount.toString(), 
                                                  label: 'Followers', 
                                                  onTap: () async {
                                                    await Navigator.push(context, MaterialPageRoute(builder: (_) => FollowersScreen(userId: user.id)));
                                                    // Refresh the screen to show updated counts
                                                    if (mounted) {
                                                      setState(() {});
                                                    }
                                                  }
                                                );
                                              },
                                            ),
                                            FutureBuilder<List<Map<String, dynamic>>>(
                                              future: Provider.of<AuthProvider>(context, listen: false).getFollowingUsersForUser(user.id),
                                              builder: (context, followingSnapshot) {
                                                int realFollowingCount = user.followingCount;
                                                if (followingSnapshot.hasData) {
                                                  realFollowingCount = followingSnapshot.data!.length;
                                                }
                                                return _StatItem(
                                                  value: realFollowingCount.toString(), 
                                                  label: 'Following', 
                                                  onTap: () async {
                                                    await Navigator.push(context, MaterialPageRoute(builder: (_) => FollowingScreen(userId: user.id)));
                                                    // Refresh the screen to show updated counts
                                                    if (mounted) {
                                                      setState(() {});
                                                    }
                                                  }
                                                );
                                              },
                                            ),
                                          ],
                                        );
                                      },
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
                                            childAspectRatio: 1,
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
              ],
            ),
          ),
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
        Navigator.push(context, MaterialPageRoute(builder: (_) => PostSliderScreen(
          posts: [post], // Single post for now
          initialIndex: 0,
        )));
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

      print('ProfileUI: Starting permanent deletion for post ID: ${post.id}');

      // Call deletion API directly
      final resp = await ApiService.deleteMedia(mediaId: post.id, token: token);
      
      print('ProfileUI: Delete response: $resp');
      
      if (resp['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resp['message'] ?? 'Post permanently deleted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Clear from local storage only after successful API deletion
        await LocalStorageService.deletePost(post.id);
        
        // Also mark as deleted in the deleted posts list
        await LocalStorageService.markPostAsDeleted(post.id);
        
        // Refresh the media data to get updated counts
        _refreshMedia();
      } else {
        // Remove from deleted set if deletion failed
        setState(() {
          _deletedMediaIds.remove(post.id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resp['message'] ?? 'Failed to delete post'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Remove from deleted set if deletion failed
      setState(() {
        _deletedMediaIds.remove(post.id);
      });
      
      print('ProfileUI: Delete error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting post: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
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

      // Navigate to login screen immediately
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        SnackBarHelper.showError(context, 'Logout failed: $e');
      }
    }
  }


  void _navigateToEditProfile(UserModel user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEditScreen(user: user),
      ),
    );
    
    if (result == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUserProfile();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // Spiritual symbols overlay (same as home screen)
  Widget _buildSpiritualSymbolsOverlay() {
    return Positioned.fill(
      child: CustomPaint(
        painter: SpiritualSymbolsPainter(),
      ),
    );
  }
}

// Spiritual symbols painter for background overlay
class SpiritualSymbolsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw various spiritual symbols across the background
    _drawOm(canvas, size, paint);
    _drawCross(canvas, size, paint);
    _drawStarOfDavid(canvas, size, paint);
    _drawCrescent(canvas, size, paint);
    _drawLotus(canvas, size, paint);
    _drawPeaceSymbol(canvas, size, paint);
  }

  void _drawOm(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    final center = Offset(size.width * 0.2, size.height * 0.3);
    final radius = 20.0;
    
    // Simplified Om symbol
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(path, paint);
  }

  void _drawCross(Canvas canvas, Size size, Paint paint) {
    final center = Offset(size.width * 0.8, size.height * 0.2);
    final length = 30.0;
    
    // Vertical line
    canvas.drawLine(
      Offset(center.dx, center.dy - length),
      Offset(center.dx, center.dy + length),
      paint,
    );
    
    // Horizontal line
    canvas.drawLine(
      Offset(center.dx - length, center.dy),
      Offset(center.dx + length, center.dy),
      paint,
    );
  }

  void _drawStarOfDavid(Canvas canvas, Size size, Paint paint) {
    final center = Offset(size.width * 0.7, size.height * 0.6);
    final radius = 25.0;
    
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60.0) * (pi / 180);
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCrescent(Canvas canvas, Size size, Paint paint) {
    final center = Offset(size.width * 0.3, size.height * 0.7);
    final radius = 20.0;
    
    final path = Path();
    path.addArc(
      Rect.fromCircle(center: center, radius: radius),
      0.5 * pi,
      pi,
    );
    canvas.drawPath(path, paint);
  }

  void _drawLotus(Canvas canvas, Size size, Paint paint) {
    final center = Offset(size.width * 0.5, size.height * 0.8);
    final radius = 15.0;
    
    // Draw lotus petals
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45.0) * (pi / 180);
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      
      final petalPath = Path();
      petalPath.addOval(Rect.fromCircle(center: Offset(x, y), radius: 8));
      canvas.drawPath(petalPath, paint);
    }
  }

  void _drawPeaceSymbol(Canvas canvas, Size size, Paint paint) {
    final center = Offset(size.width * 0.1, size.height * 0.5);
    final radius = 25.0;
    
    // Draw circle
    canvas.drawCircle(center, radius, paint);
    
    // Draw peace symbol lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    // Vertical line
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      linePaint,
    );
    
    // Diagonal lines
    final diagonalLength = radius * 0.7;
    canvas.drawLine(
      center,
      Offset(center.dx - diagonalLength, center.dy - diagonalLength),
      linePaint,
    );
    canvas.drawLine(
      center,
      Offset(center.dx + diagonalLength, center.dy - diagonalLength),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
          Text(label, style: const TextStyle(color: Colors.black)),
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
