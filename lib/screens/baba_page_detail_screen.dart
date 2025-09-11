import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/baba_page_model.dart';
import '../models/baba_page_post_model.dart';
import '../models/baba_page_reel_model.dart';
import '../services/baba_page_post_service.dart';
import '../services/baba_page_service.dart';
import '../services/baba_page_reel_service.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/baba_page_dp_widget.dart';
import '../widgets/in_app_video_widget.dart';
import '../widgets/baba_comment_dialog.dart';
import 'baba_page_post_creation_screen.dart';
import 'baba_page_reel_upload_screen.dart';
import 'baba_page_edit_menu_screen.dart';
import 'package:provider/provider.dart';

class BabaPageDetailScreen extends StatefulWidget {
  final BabaPage babaPage;

  const BabaPageDetailScreen({
    super.key,
    required this.babaPage,
  });

  @override
  State<BabaPageDetailScreen> createState() => _BabaPageDetailScreenState();
}

class _BabaPageDetailScreenState extends State<BabaPageDetailScreen> {
  List<BabaPagePost> _posts = [];
  List<BabaPageReel> _reels = [];
  bool _isLoadingPosts = false;
  bool _isLoadingReels = false;
  String? _postsErrorMessage;
  String? _reelsErrorMessage;
  bool _isFollowing = false;
  bool _isLoadingFollow = false;
  late BabaPage _currentBabaPage;
  int _selectedTabIndex = 0; // 0 for posts, 1 for reels

  @override
  void initState() {
    super.initState();
    _currentBabaPage = widget.babaPage;
    _loadFollowState();
    _loadPosts();
    _loadReels();
    _loadBabaPageDP();
  }

  Future<void> _loadFollowState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userProfile?.id;
      
      if (userId != null) {
        final followKey = 'follow_${userId}_${_currentBabaPage.id}';
        final isFollowing = prefs.getBool(followKey) ?? _currentBabaPage.isFollowing;
        setState(() {
          _isFollowing = isFollowing;
        });
      } else {
        setState(() {
          _isFollowing = _currentBabaPage.isFollowing;
        });
      }
    } catch (e) {
      print('Error loading follow state: $e');
      setState(() {
        _isFollowing = _currentBabaPage.isFollowing;
      });
    }
  }

  Future<void> _saveFollowState(bool isFollowing) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userProfile?.id;
      
      if (userId != null) {
        final followKey = 'follow_${userId}_${_currentBabaPage.id}';
        await prefs.setBool(followKey, isFollowing);
      }
    } catch (e) {
      print('Error saving follow state: $e');
    }
  }

  Future<void> _loadBabaPageDP() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;

      if (token == null) {
        print('BabaPageDetailScreen: No auth token for DP fetch');
        return;
      }

      print('BabaPageDetailScreen: Loading DP for page: ${_currentBabaPage.name} (ID: ${_currentBabaPage.id})');

      final response = await BabaPageService.getBabaPageDP(
        babaPageId: _currentBabaPage.id,
        token: token,
      );

      if (response['success'] == true) {
        final avatar = response['avatar'] as String?;
        final hasAvatar = response['hasAvatar'] as bool? ?? false;
        final followersCount = response['followersCount'] as int? ?? 0;
        
        print('BabaPageDetailScreen: DP loaded - Avatar: $avatar, Has Avatar: $hasAvatar, Followers: $followersCount');
        
        setState(() {
          _currentBabaPage = _currentBabaPage.copyWith(
            avatar: avatar ?? '',
            followersCount: followersCount,
          );
        });
      } else {
        print('BabaPageDetailScreen: DP load failed: ${response['message']}');
      }
    } catch (e) {
      print('BabaPageDetailScreen: Error loading DP: $e');
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoadingPosts = true;
      _postsErrorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;

      if (token == null) {
        setState(() {
          _postsErrorMessage = 'Please login to view posts';
          _isLoadingPosts = false;
        });
        return;
      }

      final response = await BabaPagePostService.getBabaPagePosts(
        babaPageId: _currentBabaPage.id,
        token: token,
      );

      if (response.success) {
        setState(() {
          _posts = response.posts;
          _isLoadingPosts = false;
        });
        print('BabaPageDetailScreen: Successfully loaded ${_posts.length} posts');
      } else {
        setState(() {
          _postsErrorMessage = response.message;
          _isLoadingPosts = false;
        });
        print('BabaPageDetailScreen: Failed to load posts: ${response.message}');
      }
    } catch (e) {
      setState(() {
        _postsErrorMessage = 'Error loading posts: $e';
        _isLoadingPosts = false;
      });
    }
  }

  Future<void> _loadReels() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingReels = true;
      _reelsErrorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;

      if (token == null) {
        if (mounted) {
          setState(() {
            _reelsErrorMessage = 'Please login to view reels';
            _isLoadingReels = false;
          });
        }
        return;
      }

      final response = await BabaPageReelService.getBabaPageReels(
        babaPageId: _currentBabaPage.id,
        token: token,
      );

      if (response['success'] == true) {
        final reelsData = response['data']['videos'] as List<dynamic>;
        final reels = reelsData.map((reelJson) => BabaPageReel.fromJson(reelJson)).toList();
        
        if (mounted) {
          setState(() {
            _reels = reels;
            _isLoadingReels = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _reelsErrorMessage = response['message'] ?? 'Failed to load reels';
            _isLoadingReels = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _reelsErrorMessage = 'Error loading reels: $e';
          _isLoadingReels = false;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    setState(() {
      _isLoadingFollow = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;

      if (token == null) {
        _showErrorSnackBar('Please login to follow/unfollow pages');
        setState(() {
          _isLoadingFollow = false;
        });
        return;
      }

      // Store the current state before making the API call
      final wasFollowing = _isFollowing;
      
      // Optimistically update the UI
      setState(() {
        _isFollowing = !_isFollowing;
      });

      final response = wasFollowing
          ? await BabaPageService.unfollowBabaPage(
              pageId: _currentBabaPage.id,
              token: token,
            )
          : await BabaPageService.followBabaPage(
              pageId: _currentBabaPage.id,
              token: token,
            );

      if (response.success) {
        // Success - state is already updated
        await _saveFollowState(_isFollowing);
        _showSuccessSnackBar(
          _isFollowing ? 'Successfully followed ${_currentBabaPage.name}' : 'Successfully unfollowed ${_currentBabaPage.name}',
        );
        
        // Update the followers count
        _updateFollowersCount(_isFollowing ? 1 : -1);
      } else {
        // Revert the state on failure
        setState(() {
          _isFollowing = wasFollowing;
        });
        await _saveFollowState(_isFollowing);
        _showErrorSnackBar(response.message);
      }
    } catch (e) {
      // Revert the state on error
      setState(() {
        _isFollowing = !_isFollowing;
      });
      await _saveFollowState(_isFollowing);
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() {
        _isLoadingFollow = false;
      });
    }
  }

  void _updateFollowersCount(int change) {
    // This would update the followers count in the UI
    // For now, we'll just print it
    print('Followers count changed by: $change');
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            leading: GestureDetector(
              onTap: () {
                print('Back button pressed in BabaPageDetailScreen');
                // Show immediate feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Back button pressed!'),
                    duration: Duration(seconds: 1),
                  ),
                );
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  print('Cannot pop - no previous route');
                  // If we can't pop, try to go to home or dashboard
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
              child: Container(
                margin: const EdgeInsets.all(8.0),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _currentBabaPage.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppTheme.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Cover Image
                    if (_currentBabaPage.coverImage.isNotEmpty)
                      Positioned.fill(
                        child: Image.network(
                          _currentBabaPage.coverImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppTheme.primaryColor.withOpacity(0.8),
                          ),
                        ),
                      )
                    else
                      Container(
                        color: AppTheme.primaryColor.withOpacity(0.8),
                      ),
                    // Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    // Avatar and Follow Button
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar and Name Row
                          Row(
                            children: [
                              BabaPageDPWidget(
                                currentImageUrl: _currentBabaPage.avatar,
                                babaPageId: _currentBabaPage.id,
                                token: Provider.of<AuthProvider>(context, listen: false).authToken ?? '',
                                onImageChanged: (String newImageUrl) async {
                                  print('BabaPageDetailScreen: DP changed to: $newImageUrl');
                                  print('BabaPageDetailScreen: Previous avatar: ${_currentBabaPage.avatar}');
                                  // Update the baba page with new image URL
                                  setState(() {
                                    _currentBabaPage = _currentBabaPage.copyWith(avatar: newImageUrl);
                                    print('BabaPageDetailScreen: New avatar after copyWith: ${_currentBabaPage.avatar}');
                                  });
                                  // Refresh the DP data from server
                                  await _loadBabaPageDP();
                                },
                                size: 80,
                                borderColor: Colors.white,
                                showEditButton: true,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _currentBabaPage.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins',
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          color: Colors.white70,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            _currentBabaPage.location,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                              fontFamily: 'Poppins',
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Follow/Unfollow Button - Full width
                          SizedBox(
                            width: double.infinity,
                            child: GestureDetector(
                            onTap: _isLoadingFollow ? null : _toggleFollow,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _isFollowing 
                                    ? Colors.black.withOpacity(0.8)
                                    : AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: _isFollowing 
                                      ? Colors.white.withOpacity(0.3)
                                      : Colors.transparent,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: _isLoadingFollow
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _isFollowing ? Icons.check : Icons.add,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _isFollowing ? 'Following' : 'Follow',
                                          style: TextStyle(
                                            color: _isFollowing ? Colors.white : Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ],
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
            ),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BabaPageEditMenuScreen(
                        babaPage: _currentBabaPage,
                      ),
                    ),
                  ).then((result) {
                    if (result == true) {
                      // Refresh the page data if needed
                      _loadBabaPageDP();
                    }
                  });
                },
                icon: const Icon(
                  Icons.edit,
                  color: Colors.white,
                ),
                tooltip: 'Edit Page',
              ),
            ],
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Religion Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getReligionColor(_currentBabaPage.religion).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getReligionColor(_currentBabaPage.religion).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _currentBabaPage.religion,
                      style: TextStyle(
                        color: _getReligionColor(_currentBabaPage.religion),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Description
                  Text(
                    'About',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentBabaPage.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontFamily: 'Poppins',
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Stats
                  _buildStatsSection(),
                  const SizedBox(height: 24),
                  // Website
                  if (_currentBabaPage.website.isNotEmpty) _buildWebsiteSection(),
                  const SizedBox(height: 24),
                  // Created Date
                  _buildInfoSection(
                    'Created',
                    _formatDate(_currentBabaPage.createdAt),
                    Icons.calendar_today,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoSection(
                    'Last Updated',
                    _formatDate(_currentBabaPage.updatedAt),
                    Icons.update,
                  ),
                ],
              ),
            ),
          ),
          // Content Tabs Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tab Selector
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTabIndex = 0;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedTabIndex == 0 
                                    ? AppTheme.primaryColor 
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.grid_on,
                                    color: _selectedTabIndex == 0 
                                        ? Colors.white 
                                        : AppTheme.textSecondary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Posts (${_posts.length})',
                                    style: TextStyle(
                                      color: _selectedTabIndex == 0 
                                          ? Colors.white 
                                          : AppTheme.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTabIndex = 1;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedTabIndex == 1 
                                    ? AppTheme.primaryColor 
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.video_library,
                                    color: _selectedTabIndex == 1 
                                        ? Colors.white 
                                        : AppTheme.textSecondary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Reels (${_reels.length})',
                                    style: TextStyle(
                                      color: _selectedTabIndex == 1 
                                          ? Colors.white 
                                          : AppTheme.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Create Content Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedTabIndex == 0 ? 'Posts' : 'Reels',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (_selectedTabIndex == 0) {
                            // Create Post
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BabaPagePostCreationScreen(
                                  babaPage: widget.babaPage,
                                ),
                              ),
                            ).then((_) {
                              _loadPosts();
                            });
                          } else {
                            // Create Reel
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BabaPageReelUploadScreen(
                                  babaPage: widget.babaPage,
                                ),
                              ),
                            ).then((_) {
                              _loadReels();
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _selectedTabIndex == 0 ? Icons.add : Icons.video_library,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedTabIndex == 0 ? 'Create Post' : 'Upload Reel',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Content Display
                  if (_selectedTabIndex == 0)
                    _buildPostsSection()
                  else
                    _buildReelsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: GestureDetector(
        onTap: () {
          print('Floating Action Button pressed for page: ${_currentBabaPage.name} (ID: ${_currentBabaPage.id})');
          // Show immediate feedback with page info
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Creating new post for ${_currentBabaPage.name}...'),
              duration: const Duration(seconds: 1),
            ),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BabaPagePostCreationScreen(
                babaPage: _currentBabaPage,
              ),
            ),
          ).then((_) {
            print('Returned from post creation screen via FAB for page: ${_currentBabaPage.name}');
            // Refresh posts when returning from creation screen
            _loadPosts();
          });
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                Icons.people,
                '${_currentBabaPage.followersCount}',
                'Followers',
                AppTheme.primaryColor,
              ),
              _buildStatCard(
                Icons.grid_on,
                '${_currentBabaPage.postsCount}',
                'Posts',
                Colors.green,
              ),
              _buildStatCard(
                Icons.play_circle_outline,
                '${_currentBabaPage.videosCount}',
                'Videos',
                Colors.orange,
              ),
              _buildStatCard(
                Icons.auto_stories,
                '${_currentBabaPage.storiesCount}',
                'Stories',
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String count, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildWebsiteSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Website',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _launchWebsite(_currentBabaPage.website),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.web,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child:                   Text(
                    _currentBabaPage.website,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.open_in_new,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.grey[600],
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          '$title: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontFamily: 'Poppins',
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Color _getReligionColor(String religion) {
    switch (religion.toLowerCase()) {
      case 'hinduism':
        return Colors.orange;
      case 'islam':
        return Colors.green;
      case 'christianity':
        return Colors.blue;
      case 'sikhism':
        return Colors.amber;
      case 'buddhism':
        return Colors.purple;
      case 'jainism':
        return Colors.red;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _launchWebsite(String url) async {
    // final Uri uri = Uri.parse(url);
    // if (await canLaunchUrl(uri)) {
    //   await launchUrl(uri, mode: LaunchMode.externalApplication);
    // }
  }

  Widget _buildPostsSection() {
    if (_isLoadingPosts) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_postsErrorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error fetching posts',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _postsErrorMessage!,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPosts,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.auto_stories,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share something on this page',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return _buildPostCard(post);
      },
    );
  }

  Widget _buildReelsSection() {
    if (_isLoadingReels) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_reelsErrorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _reelsErrorMessage!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadReels,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_reels.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.video_library,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No reels yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to upload a reel on this page',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _reels.length,
      itemBuilder: (context, index) {
        final reel = _reels[index];
        return InAppVideoWidget(
          reel: reel,
          autoplay: false, // Don't autoplay in the detail screen
          showFullDetails: true,
          onTap: () {
            // Handle reel tap - could open full screen or navigate to reel detail
            print('Reel tapped: ${reel.title}');
          },
        );
      },
    );
  }

  Widget _buildPostCard(BabaPagePost post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.self_improvement,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentBabaPage.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        _formatDate(post.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                // Delete Button
                GestureDetector(
                  onTap: () {
                    _showDeletePostConfirmation(post);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Post Content
            Text(
              post.content,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
                fontFamily: 'Poppins',
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            // Post Media
            if (post.media.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  post.media.first.url,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Post Stats
            Row(
              children: [
                _buildPostStat(Icons.favorite, '${post.likesCount}'),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => _showCommentsDialog(post),
                  child: _buildPostStat(Icons.comment, '${post.commentsCount}'),
                ),
                const SizedBox(width: 16),
                _buildPostStat(Icons.share, '${post.sharesCount}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostStat(IconData icon, String count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  void _showDeletePostConfirmation(BabaPagePost post) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Delete Post',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this post? This action cannot be undone.',
            style: TextStyle(
              fontFamily: 'Poppins',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deletePost(post);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePost(BabaPagePost post) async {
    print('BabaPageDetailScreen: Deleting post: ${post.id}');
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;

      if (token == null) {
        print('BabaPageDetailScreen: No auth token found');
        _showErrorSnackBar('Please login to delete posts');
        return;
      }

      print('BabaPageDetailScreen: Calling delete API for post: ${post.id}');
      final response = await BabaPagePostService.deleteBabaPagePost(
        babaPageId: _currentBabaPage.id,
        postId: post.id,
        token: token,
      );

      print('BabaPageDetailScreen: Delete response success: ${response.success}');
      print('BabaPageDetailScreen: Delete response message: ${response.message}');

      if (response.success) {
        _showSuccessSnackBar('Post deleted successfully!');
        _loadPosts(); // Refresh the posts list
      } else {
        _showErrorSnackBar(response.message);
      }
    } catch (e) {
      print('BabaPageDetailScreen: Error deleting post: $e');
      _showErrorSnackBar('Error deleting post: $e');
    }
  }

  void _showCommentsDialog(BabaPagePost post) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BabaCommentDialog(
          postId: post.id,
          babaPageId: _currentBabaPage.id,
          isReel: false,
          onCommentAdded: () {
            // Refresh posts to update comment count
            _loadPosts();
          },
        );
      },
    );
  }

}

