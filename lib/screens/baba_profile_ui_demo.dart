import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/baba_page_model.dart';
import '../models/baba_page_post_model.dart';
import '../services/baba_page_post_service.dart';
import '../services/baba_page_service.dart';
import '../services/feed_refresh_service.dart';
import '../services/follow_state_service.dart';
import '../services/media_upload_service.dart';
import '../services/local_storage_service.dart';
import '../services/baba_page_dp_service.dart';
import '../services/baba_page_reel_service.dart';
import '../models/baba_page_reel_model.dart';
import '../services/baba_page_story_service.dart';
import '../models/baba_page_story_model.dart';
import '../models/story_model.dart';
import '../screens/story_viewer_screen.dart';
import '../providers/auth_provider.dart';
import '../utils/avatar_utils.dart';
import '../utils/responsive_utils.dart';
import 'baba_page_post_creation_screen.dart';
import 'baba_pages_screen.dart';
import 'baba_page_reel_upload_screen.dart';
import 'baba_page_story_upload_screen.dart';
import '../widgets/video_player_widget.dart';

class BabaProfileUiDemoScreen extends StatefulWidget {
  final BabaPage? babaPage; // when provided, bind to real data
  const BabaProfileUiDemoScreen({super.key, this.babaPage});

  @override
  State<BabaProfileUiDemoScreen> createState() => _BabaProfileUiDemoScreenState();
}

class _BabaProfileUiDemoScreenState extends State<BabaProfileUiDemoScreen> with AutomaticKeepAliveClientMixin {
  int selectedSegment = 0;

  List<BabaPagePost> _posts = [];
  bool _loadingPosts = false;
  bool _postsLoaded = false; // Prevent multiple loads
  
  List<MediaData> _videos = [];
  bool _loadingVideos = false;
  bool _videosLoaded = false; // Prevent multiple loads
  
  List<BabaPageStory> _stories = [];
  bool _loadingStories = false;
  bool _storiesLoaded = false; // Prevent multiple loads
  
  // Local state for current avatar URL
  String? _currentAvatarUrl;

  @override
  bool get wantKeepAlive => true; // Keep the page alive to prevent rebuilds

  @override
  void initState() {
    super.initState();
    // Initialize avatar URL from the BabaPage if available
    if (widget.babaPage != null) {
      _currentAvatarUrl = widget.babaPage!.avatar;
    }
  }

  String _getDisplayAvatarUrl() {
    // Priority: Local state > BabaPage avatar > Default
    if (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty) {
      return AvatarUtils.getAbsoluteAvatarUrl(_currentAvatarUrl);
    }
    
    final page = widget.babaPage;
    if (page != null && page.avatar.isNotEmpty) {
      return AvatarUtils.getAbsoluteAvatarUrl(page.avatar);
    }
    
    return AvatarUtils.getDefaultAvatarUrl() ?? '';
  }

  @override
  void dispose() {
    // Clean up resources to prevent memory leaks
    super.dispose();
  }
  
  // Method to reset loaded state when needed
  void _resetLoadedState() {
    _postsLoaded = false;
    _videosLoaded = false;
    _storiesLoaded = false;
    _posts.clear();
    _videos.clear();
    _stories.clear();
  }

  // Check if current user is the creator of this Baba page
  bool _isCurrentUserCreator() {
    final page = widget.babaPage;
    if (page == null) return false;
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.userProfile?.id;
      
      if (currentUserId == null) return false;
      
      // Check if current user's ID matches the creator's ID
      return page.creatorId == currentUserId;
    } catch (e) {
      print('Error checking creator: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final page = widget.babaPage;
    final hasRealData = page != null;
    final isCreator = _isCurrentUserCreator();
    final screenW = MediaQuery.of(context).size.width;
    
    // Load posts when bound to real page (only once)
    if (hasRealData && !_loadingPosts && !_postsLoaded && _posts.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _postsLoaded = true;
          _fetchPosts(page!);
        }
      });
    }
    
    // Load videos when bound to real page (only once)
    if (hasRealData && !_loadingVideos && !_videosLoaded && _videos.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _videosLoaded = true;
          _fetchVideos(page!);
        }
      });
    }
    
    // Load stories when bound to real page (only once)
    if (hasRealData && !_loadingStories && !_storiesLoaded && _stories.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _storiesLoaded = true;
          _fetchStories(page!);
        }
      });
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      extendBody: true,
      floatingActionButton: isCreator ? FloatingActionButton.extended(
        onPressed: () => _openCreateBottomSheet(context),
        backgroundColor: Colors.orange.shade400,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Create',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ) : null,
      body: SafeArea(
        child: DefaultTextStyle.merge(
          style: GoogleFonts.poppins(),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Header with DP and info
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Gradient card
                  Container(
                    margin: ResponsiveUtils.getResponsivePadding(context, horizontal: 4.5, vertical: 1.5),
                    padding: EdgeInsets.only(
                      top: ResponsiveUtils.getResponsiveHeight(context, 9),
                      bottom: ResponsiveUtils.getResponsiveHeight(context, 2.25),
                      left: ResponsiveUtils.getResponsiveWidth(context, 4.5),
                      right: ResponsiveUtils.getResponsiveWidth(context, 4.5),
                    ),
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
                    child: Column(
                      children: [
                        SizedBox(height: ResponsiveUtils.getResponsiveHeight(context, 6.0)),
                        Text(
                          hasRealData ? page.name : 'Baba Sayam',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: ResponsiveUtils.getResponsiveHeight(context, 0.75)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                            SizedBox(width: ResponsiveUtils.getResponsiveWidth(context, 1.0)),
                            Text(hasRealData ? page.location : 'Haridwar, India', style: TextStyle(color: Colors.grey[700])),
                          ],
                        ),
                        SizedBox(height: ResponsiveUtils.getResponsiveHeight(context, 1.5)),
                          // Tags
                          Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                alignment: WrapAlignment.center,
                                children: [
                                  _buildTag(hasRealData ? page.religion : 'Hinduism', Colors.orange.shade100, Colors.orange.shade700),
                                  _buildTag('Yoga', Colors.blue.shade100, Colors.blue.shade700),
                                  _buildTag('Spiritual Leader', Colors.green.shade100, Colors.green.shade800),
                                ],
                        ),
                        const SizedBox(height: 16),
                          // Follow button
                        Center(
                          child: _FollowButton(page: page),
                        ),
                      ],
                    ),
                  ),

                    // DP with frame
                  Positioned(
                    top: -14,
                    left: (screenW / 2) - 62,
                    child: _glowingAvatar(
                      imageUrl: _getDisplayAvatarUrl(),
                      size: 124,
                    ),
                  ),
                  
                    // Back button - positioned on top (renders on top of everything)
                    Positioned(
                      left: 16,
                      top: 0,
                      child: SafeArea(
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
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Edit button (only for creator) - positioned on top right
                    if (isCreator)
                      Positioned(
                        right: 16,
                        top: 0,
                        child: SafeArea(
                          child: GestureDetector(
                            onTap: () => _showDPUploadOptions(context),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                
                // Content tabs and display
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.getResponsiveWidth(context, 4.5),
                    vertical: ResponsiveUtils.getResponsiveHeight(context, 2.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _segmentControl(),
                      SizedBox(height: ResponsiveUtils.getResponsiveHeight(context, 1.5)),
                      _buildSelectedContent(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedContent() {
    switch (selectedSegment) {
      case 0:
        return _buildPostsList();
      case 1:
        return _buildVideosList();
      case 2:
        return _buildStoriesList();
      case 3:
        return _buildEventsList();
      default:
        return _buildPostsList();
    }
  }

  Widget _buildPostsList() {
    if (_loadingPosts) {
      return _buildPostsSkeleton();
    }

    if (_posts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.grid_on_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No posts yet', style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('Create your first post', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _posts.length,
      itemBuilder: (context, index) => _buildPostItem(_posts[index]),
    );
  }

  Widget _buildPostItem(BabaPagePost post) {
    final firstMedia = post.media.isNotEmpty ? post.media.first : null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: firstMedia != null && firstMedia.url.isNotEmpty
                ? SizedBox(
                    width: double.infinity,
                    height: 300,
                    child: Image.network(firstMedia.url, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
                      return Container(height: 300, color: Colors.grey.shade300, child: Center(child: Icon(firstMedia.type == 'image' ? Icons.image : Icons.video_file, size: 48, color: Colors.grey.shade600)));
                    }),
                  )
                : Container(height: 300, color: Colors.grey.shade200, child: Center(child: Icon(Icons.image_outlined, size: 64, color: Colors.grey.shade400))),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.content.isNotEmpty)
                  Text(post.content, style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w400), maxLines: 3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                if (post.commentsCount > 0) ...[
                  Row(
                    children: [
                      Icon(Icons.comment, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text('${post.commentsCount}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 1),
    );
  }

  Widget _buildPostsSkeleton() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, i) => Container(
        margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
          color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Container(
              height: 300,
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.grey))),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 100, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _glowingAvatar({required String imageUrl, double size = 100}) {
    final isValidUrl = AvatarUtils.isValidAvatarUrl(imageUrl);
    
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            image: DecorationImage(image: AssetImage('assets/images/babji_dp_bg_frame.jpg'), fit: BoxFit.cover),
            ),
          ),
        Positioned(
          left: size * 0.2,
          top: size * 0.2,
          child: Container(
            width: size * 0.6,
            height: size * 0.6,
            decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, spreadRadius: 1)]),
            child: ClipOval(
              child: isValidUrl
                  ? Image.network(imageUrl, width: size * 0.6, height: size * 0.6, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
                      return Container(width: size * 0.6, height: size * 0.6, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.orange.withOpacity(0.1), Colors.orange.withOpacity(0.3)], begin: Alignment.topLeft, end: Alignment.bottomRight)));
                    })
                  : Container(width: size * 0.6, height: size * 0.6, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.orange.withOpacity(0.1), Colors.orange.withOpacity(0.3)], begin: Alignment.topLeft, end: Alignment.bottomRight))),
            ),
          ),
        ),
      ],
    );
  }

  Widget _segmentControl() {
    final labels = ['Posts', 'Videos', 'Stories', 'Events'];
              return Container(
                padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(30)),
                child: Row(
                  children: List.generate(labels.length, (i) {
                    final isSelected = i == selectedSegment;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                         setState(() => selectedSegment = i);
                if (i == 0 && widget.babaPage != null && !_postsLoaded && _posts.isEmpty) _fetchPosts(widget.babaPage!);
                if (i == 1 && widget.babaPage != null && !_videosLoaded && _videos.isEmpty) _fetchVideos(widget.babaPage!);
                if (i == 2 && widget.babaPage != null && !_storiesLoaded && _stories.isEmpty) _fetchStories(widget.babaPage!);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                  boxShadow: isSelected ? [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4))] : null,
                          ),
                          child: Center(
                            child: Text(
                              labels[i],
                              textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, fontSize: 11, color: isSelected ? Colors.black87 : Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
    );
  }

  Widget _buildVideosList() {
    if (_loadingVideos) {
      return Column(children: List.generate(3, (index) => _buildVideoItemSkeleton()));
    }

    if (_videos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.video_library_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No videos uploaded yet', style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('Upload your first video to get started', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 0.8,
      ),
      itemCount: _videos.length,
      itemBuilder: (context, index) => _buildVideoItem(_videos[index]),
    );
  }

  Widget _buildVideoItem(MediaData video) {
    return GestureDetector(
      onTap: () => _playVideoWithSound(video),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(Icons.video_file, color: Colors.grey.shade600, size: 24),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            height: 16,
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.video_file, size: 8, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Uploaded ${_formatDate(video.uploadedAt)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 7),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoItemSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.getResponsiveHeight(context, 1.0)),
                        Container(
                          height: 12,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStoriesList() {
    if (_loadingStories) {
      return Column(children: List.generate(3, (index) => _buildStoryItemSkeleton()));
    }

    if (_stories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.auto_stories_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No stories yet', style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('Create your first story', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 0.8,
      ),
      itemCount: _stories.length,
      itemBuilder: (context, index) => _buildStoryItem(_stories[index]),
    );
  }

  Widget _buildStoryItem(BabaPageStory story) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: GestureDetector(
                onTap: () => _openStoryViewer(story),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                        child: story.media.url.isNotEmpty
                            ? Image.network(
                                story.media.url,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) =>
                                  loadingProgress == null ? child : Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    color: Colors.grey.shade300,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey)
                                      )
                                    )
                                  ),
                              errorBuilder: (context, error, stackTrace) => Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    color: Colors.grey.shade300,
                                child: const Center(child: Icon(Icons.auto_stories, color: Colors.grey, size: 32))
                              ),
                              )
                            : Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: Colors.grey.shade300,
                              child: const Center(child: Icon(Icons.auto_stories, color: Colors.grey, size: 32))
                            ),
                    ),
                    Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_stories, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStoryItemSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
      child: Padding(
        padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 16,
                  width: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildEventsList() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.event_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('No events scheduled', style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Schedule your first live session', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
      return 'Just now';
  }

  void _openCreateBottomSheet(BuildContext context) {
    final page = widget.babaPage;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.35,
        maxChildSize: 0.8,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Create', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _createTile(
                      icon: Icons.grid_3x3_outlined,
                      label: 'Post',
                      color: const Color(0xFF2196F3),
                      onTap: page == null
                          ? null
                          : () async {
                  Navigator.pop(context);
                              final ok = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => BabaPagePostCreationScreen(babaPage: page)),
                              );
                              if (ok == true) _fetchPosts(page);
                            },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _createTile(
                      icon: Icons.video_call_outlined,
                      label: 'Reel',
                      color: const Color(0xFF4CAF50),
                      onTap: page == null
                          ? null
                          : () async {
                              Navigator.pop(context);
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => BabaPageReelUploadScreen(babaPage: page)),
                              );
                            },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _createTile(
                      icon: Icons.auto_stories_outlined,
                      label: 'Story',
                      color: const Color(0xFFFF9800),
                      onTap: page == null
                          ? null
                          : () async {
                              Navigator.pop(context);
                              final ok = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => BabaPageStoryUploadScreen(babaPage: page)),
                              );
                              if (ok == true) _fetchStories(page);
                            },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
                ),
              );
            }

  Widget _createTile({required IconData icon, required String label, required Color color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 120,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), shape: BoxShape.circle),
              child: Icon(icon, size: 24, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white)),
          ],
        ),
              ),
            );
          }

  Future<void> _fetchPosts(BabaPage page) async {
    if (_loadingPosts) return;
    try {
      setState(() => _loadingPosts = true);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.authToken;
      if (token == null) { setState(() => _loadingPosts = false); return; }
      final resp = await BabaPagePostService.getBabaPagePosts(babaPageId: page.id, token: token, page: 1, limit: 20);
      if (!mounted) return;
      setState(() { _posts = resp.posts; _loadingPosts = false; _postsLoaded = true; });
        } catch (e) {
      if (!mounted) return;
      setState(() { _loadingPosts = false; _postsLoaded = true; });
    }
  }

  Future<void> _fetchVideos(BabaPage page) async {
    if (_loadingVideos) return;
    try {
      if (mounted) setState(() => _loadingVideos = true);
      List<MediaData> videos = [];
      try {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final token = auth.authToken;
        if (token != null) {
          final reelsResponse = await BabaPageReelService.getBabaPageReels(babaPageId: page.id, token: token, page: 1, limit: 8);
          if (reelsResponse['success'] == true) {
            final reelsData = reelsResponse['data']['videos'] as List<dynamic>? ?? [];
            for (final reelData in reelsData) {
              final reel = BabaPageReel.fromJson(reelData);
              if (reel.video.url.isNotEmpty) {
                videos.add(MediaData(mediaId: reel.id, publicId: '', secureUrl: reel.video.url, folderPath: '', fileName: reel.title.isNotEmpty ? reel.title : '${reel.babaPageId}_${reel.id}', fileType: 'video', fileSize: 0, dimensions: {}, duration: 0, uploadedBy: reel.babaPageId, username: page.name, uploadedAt: reel.createdAt));
              }
            }
          }
        }
      } catch (e) { print('Error fetching server videos: $e'); }
      if (mounted) { setState(() { _videos = videos; _loadingVideos = false; }); }
    } catch (e) {
      if (mounted) setState(() => _loadingVideos = false);
    }
  }

  Future<void> _fetchStories(BabaPage page) async {
    if (_loadingStories) return;
    try {
      if (mounted) setState(() => _loadingStories = true);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.authToken;
      if (token != null) {
        final stories = await BabaPageStoryService.getBabaPageStories(babaPageId: page.id, token: token, page: 1, limit: 20);
        if (mounted) { setState(() { _stories = stories; _loadingStories = false; }); }
      } else {
        if (mounted) setState(() => _loadingStories = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loadingStories = false);
    }
  }

  void _showDPUploadOptions(BuildContext context) {
    final page = widget.babaPage;
    if (page == null) return;
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => Container(decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))), child: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))), const Padding(padding: EdgeInsets.all(16), child: Text('Change Profile Picture', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)))), ListTile(leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.camera_alt, color: Colors.blue)), title: const Text('Take Photo'), subtitle: const Text('Use camera to take a new photo'), onTap: () { Navigator.pop(context); _pickImageFromCamera(); }), ListTile(leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.photo_library, color: Colors.green)), title: const Text('Choose from Gallery'), subtitle: const Text('Select photo from your gallery'), onTap: () { Navigator.pop(context); _pickImageFromGallery(); }), if ((_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty) || page.avatar.isNotEmpty) ListTile(leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.delete_outline, color: Colors.red)), title: const Text('Remove Current Photo'), subtitle: const Text('Delete your current profile picture'), onTap: () { Navigator.pop(context); _deleteCurrentDP(); }), const SizedBox(height: 20)])));
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera, maxWidth: 800, maxHeight: 800, imageQuality: 85);
      if (image != null) await _uploadDP(File(image.path));
    } catch (e) { _showSnackBar('Error taking photo: $e', Colors.red); }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 85);
      if (image != null) await _uploadDP(File(image.path));
    } catch (e) { _showSnackBar('Error selecting image: $e', Colors.red); }
  }

  Future<void> _uploadDP(File imageFile) async {
    final page = widget.babaPage;
    if (page == null) { _showSnackBar('Please select a Baba Ji page first', Colors.orange); return; }
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.authToken;
    if (token == null || token.isEmpty) { _showSnackBar('Please login first', Colors.red); return; }
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
    try {
      final response = await BabaPageDPService.uploadBabaPageDP(imageFile: imageFile, babaPageId: page.id, token: token);
      if (mounted) Navigator.pop(context);
      if (response['success'] == true) {
        final data = response['data'];
        final avatarUrl = data['avatarUrl'] as String?;
        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          setState(() => _currentAvatarUrl = avatarUrl);
          _showSnackBar('Baba Ji page display picture uploaded successfully!', Colors.green);
        } else { _showSnackBar('Upload successful but no image URL returned', Colors.orange); }
      } else { _showSnackBar(response['message'] ?? 'Failed to upload display picture', Colors.red); }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackBar('Error uploading display picture: $e', Colors.red);
    }
  }

  Future<void> _deleteCurrentDP() async {
    final page = widget.babaPage;
    if (page == null) { _showSnackBar('Please select a Baba Ji page first', Colors.orange); return; }
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.authToken;
    if (token == null || token.isEmpty) { _showSnackBar('Please login first', Colors.red); return; }
    final bool? shouldDelete = await showDialog<bool>(context: context, builder: (BuildContext context) => AlertDialog(title: const Text('Delete Display Picture'), content: const Text('Are you sure you want to delete this display picture? This action cannot be undone.'), actions: [TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.of(context).pop(true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete'))]));
    if (shouldDelete != true) return;
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
    try {
      final response = await BabaPageDPService.deleteBabaPageDP(babaPageId: page.id, token: token);
      if (mounted) Navigator.pop(context);
      if (response['success'] == true) {
        setState(() => _currentAvatarUrl = '');
        _showSnackBar('Display picture deleted successfully!', Colors.green);
      } else { _showSnackBar(response['message'] ?? 'Failed to delete display picture', Colors.red); }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackBar('Error deleting display picture: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: backgroundColor, duration: const Duration(seconds: 2)));
  }

  void _playVideoWithSound(MediaData video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              video.fileName.isNotEmpty ? video.fileName : 'Video',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: Center(
            child: _SimpleVideoPlayer(
              videoUrl: video.secureUrl,
              videoTitle: video.fileName.isNotEmpty ? video.fileName : 'Video',
            ),
          ),
        ),
      ),
    );
  }

  void _openStoryViewer(BabaPageStory story) async {
    // Start with current page's stories
    final currentPageStories = _stories.map((s) => _convertBabaPageStoryToStory(s)).toList();
    
    // Fetch stories from all other baba pages for navigation
    List<Story> allBabaPageStories = [];
    try {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.authToken;
      if (token != null) {
        // Get all baba pages
        final babaPagesResponse = await BabaPageService.getBabaPages(
          token: token,
          page: 1,
          limit: 50,
        );
        
        if (babaPagesResponse.success) {
          // Fetch stories from each baba page
          for (final page in babaPagesResponse.pages) {
            if (page.id != widget.babaPage?.id) { // Skip current page (already loaded)
              try {
                final pageStories = await BabaPageStoryService.getBabaPageStories(
        babaPageId: page.id,
        token: token,
                  page: 1,
                  limit: 10,
                );
                
                if (pageStories.isNotEmpty) {
                  final convertedStories = pageStories.map((s) {
                    return Story(
                      id: s.id,
                      authorId: page.id,
                      authorName: page.name,
                      authorUsername: page.name.toLowerCase().replaceAll(' ', ''),
                      authorAvatar: page.avatar,
                      media: s.media.url,
                      mediaId: s.id,
                      type: s.media.type,
                      mentions: [],
                      hashtags: [],
                      isActive: s.isActive,
                      views: [],
                      viewsCount: s.viewsCount,
                      expiresAt: s.expiresAt,
                      createdAt: s.createdAt,
                      updatedAt: s.updatedAt,
                    );
                  }).toList();
                  allBabaPageStories.addAll(convertedStories);
      }
    } catch (e) {
                print('Error fetching stories for ${page.name}: $e');
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching all baba page stories: $e');
    }
    
    // Combine current page stories with other baba page stories
    final allStories = [...currentPageStories, ...allBabaPageStories];
    final currentStory = _convertBabaPageStoryToStory(story);
    final initialIndex = currentPageStories.indexOf(currentStory);
    
    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => StoryViewerScreen(story: currentStory, allStories: allStories, initialIndex: initialIndex >= 0 ? initialIndex : 0)));
    }
  }

  Story _convertBabaPageStoryToStory(BabaPageStory babaStory) {
    return Story(id: babaStory.id, authorId: widget.babaPage?.id ?? '', authorName: widget.babaPage?.name ?? 'Babaji', authorUsername: widget.babaPage?.name ?? 'babaji', authorAvatar: widget.babaPage?.avatar, media: babaStory.media.url, mediaId: babaStory.id, type: babaStory.media.type, mentions: [], hashtags: [], isActive: babaStory.isActive, views: [], viewsCount: babaStory.viewsCount, expiresAt: babaStory.expiresAt, createdAt: babaStory.createdAt, updatedAt: babaStory.updatedAt);
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
    if (widget.page != null) {
      _loadFollowStateFromPrefs();
    }
  }

  /// Load follow state from SharedPreferences
  Future<void> _loadFollowStateFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pageId = widget.page?.id;
      
      if (pageId == null) return;
      
      // Load saved follow state for this specific page
      final savedState = prefs.getBool('follow_state_$pageId');
      final savedFollowers = prefs.getInt('followers_$pageId');
      
      if (savedState != null) {
          setState(() {
          _isFollowing = savedState;
          });
        }
      
      if (savedFollowers != null) {
          setState(() {
          _followers = savedFollowers;
          });
      }
      
      // Also check with server to ensure consistency
      _checkFollowStatus();
    } catch (e) {
      print('_FollowButton: Error loading follow state: $e');
    }
  }

  /// Save follow state to SharedPreferences
  Future<void> _saveFollowStateToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pageId = widget.page?.id;
      
      if (pageId == null) return;
      
      await prefs.setBool('follow_state_$pageId', _isFollowing);
      await prefs.setInt('followers_$pageId', _followers);
    } catch (e) {
      print('_FollowButton: Error saving follow state: $e');
    }
  }

  Future<void> _checkFollowStatus() async {
    if (widget.page == null) return;
    
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
        final userId = auth.userProfile?.id;
        
        if (userId != null) {
        // Use existing page data for follow status
        if (widget.page != null) {
          setState(() {
            _isFollowing = widget.page!.isFollowing;
            _followers = widget.page!.followersCount;
          });
          
          // Save to prefs after getting server state
          await _saveFollowStateToPrefs();
        }
      }
    } catch (e) {
      print('_FollowButton: Error checking follow status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
      return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getResponsiveWidth(context, 2.0),
        vertical: ResponsiveUtils.getResponsiveHeight(context, 0.25),
      ),
            decoration: BoxDecoration(
        gradient: _isFollowing
            ? LinearGradient(
                colors: [Colors.grey.shade400, Colors.grey.shade500],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Colors.orange.shade400, Colors.orange.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
            color: (_isFollowing ? Colors.grey : Colors.orange).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
                ),
              ],
          ),
          child: _loading 
          ? const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          : GestureDetector(
              onTap: widget.page == null ? null : _toggleFollow,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getResponsiveWidth(context, 3.0),
                  vertical: ResponsiveUtils.getResponsiveHeight(context, 0.5),
            ),
            child: Row(
                  mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                      _isFollowing ? Icons.check_circle : Icons.add,
                      size: 18,
                      color: Colors.white,
                    ),
                    SizedBox(width: ResponsiveUtils.getResponsiveWidth(context, 1.0)),
          Text(
                      _isFollowing
                          ? 'Following (${widget.page?.followersCount ?? _followers})'
                          : 'Follow',
                      style: const TextStyle(
                        color: Colors.white,
                    fontWeight: FontWeight.w600,
              fontSize: 14,
                  ),
          ),
        ],
      ),
                ),
              ),
    );
  }

  Future<void> _toggleFollow() async {
    if (_loading || widget.page == null) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.authToken;
    
    if (token == null || auth.userProfile == null) {
      // Show login prompt
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to follow Baba Ji'),
              backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() => _loading = true);
    
    try {
      final currentState = _isFollowing;
      
      // Optimistically update UI
          setState(() {
        _isFollowing = !currentState;
        _followers = _isFollowing ? _followers + 1 : _followers - 1;
      });

      // Save optimistic state to prefs
      await _saveFollowStateToPrefs();

      // Call API - use existing follow/unfollow methods
      bool success = false;
      if (currentState) {
        // Unfollow
        final response = await BabaPageService.unfollowBabaPage(
          pageId: widget.page!.id,
          token: token,
        );
        success = response.success;
        } else {
        // Follow
        final response = await BabaPageService.followBabaPage(
          pageId: widget.page!.id,
          token: token,
        );
        success = response.success;
      }

      if (success) {
        // Call was successful, update from server to ensure consistency
        await _checkFollowStatus();
        
        // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
            content: Text(
              _isFollowing
                  ? 'You are now following ${widget.page?.name ?? "Baba Ji"}'
                  : 'You unfollowed ${widget.page?.name ?? "Baba Ji"}',
            ),
            backgroundColor: _isFollowing ? Colors.green : Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
        } else {
        // Call failed, revert optimistic update
            setState(() {
          _isFollowing = currentState;
          _followers = _isFollowing ? _followers + 1 : _followers - 1;
            });
          
            ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update follow status'),
                backgroundColor: Colors.red,
              ),
            );
      }
    } catch (e) {
      // Revert optimistic update on error
          setState(() {
        _isFollowing = !_isFollowing;
        _followers = _isFollowing ? _followers - 1 : _followers + 1;
          });
          
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
          content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _SimpleVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;

  const _SimpleVideoPlayer({
    required this.videoUrl,
    required this.videoTitle,
  });

  @override
  State<_SimpleVideoPlayer> createState() => _SimpleVideoPlayerState();
}

class _SimpleVideoPlayerState extends State<_SimpleVideoPlayer> {
  late final Player player;
  late final VideoController videoController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      player = Player();
      videoController = VideoController(player);
      await player.open(Media(widget.videoUrl));
    } catch (e) {
      print('SimpleVideoPlayer: Error initializing: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Video(
      controller: videoController,
      controls: NoVideoControls,
    );
  }
}
