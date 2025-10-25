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
      // Load posts with delay to improve initial page load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Add small delay to let UI render first
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _fetchPosts(widget.babaPage!);
            }
          });
        }
      });
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final screenW = MediaQuery.of(context).size.width;
    final page = widget.babaPage;
    final hasRealData = page != null;
    
    // Load posts when bound to real page - ensure posts load automatically (only once)
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
      body: SafeArea(
        child: DefaultTextStyle.merge(
          style: GoogleFonts.poppins(),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Header (avatar, gradient background, name, tags)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                  // rounded gradient card
                  Container(
                    margin: ResponsiveUtils.getResponsivePadding(context, horizontal: 4.5, vertical: 1.5),
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
                    padding: EdgeInsets.only(
                      top: ResponsiveUtils.getResponsiveHeight(context, 9),
                      bottom: ResponsiveUtils.getResponsiveHeight(context, 2.25),
                      left: ResponsiveUtils.getResponsiveWidth(context, 4.5),
                      right: ResponsiveUtils.getResponsiveWidth(context, 4.5),
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
                        // tags
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 300) {
                              // For small screens, use smaller tags and tighter spacing
                              return Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                alignment: WrapAlignment.center,
                                children: [
                                  _buildTag(hasRealData ? page.religion : 'Hinduism', Colors.orange.shade100, Colors.orange.shade700, isSmall: true),
                                  _buildTag('Yoga', Colors.blue.shade100, Colors.blue.shade700, isSmall: true),
                                  _buildTag('Spiritual Leader', Colors.green.shade100, Colors.green.shade800, isSmall: true),
                                ],
                              );
                            } else {
                              // For normal screens, use regular tags
                              return Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                alignment: WrapAlignment.center,
                                children: [
                                  _buildTag(hasRealData ? page.religion : 'Hinduism', Colors.orange.shade100, Colors.orange.shade700),
                                  _buildTag('Yoga', Colors.blue.shade100, Colors.blue.shade700),
                                  _buildTag('Spiritual Leader', Colors.green.shade100, Colors.green.shade800),
                                ],
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        // Follow button inside header card
                        Center(
                          child: _FollowButton(page: page),
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
                  Positioned(
                    right: 30,
                    top: 16,
                    child: GestureDetector(
                      onTap: () => _showDPUploadOptions(context),
                      child: const Icon(Icons.edit_outlined, size: 20),
                    ),
                  ),

                  // Circular avatar with glow (overlapping) - No DP upload functionality
                  Positioned(
                    top: -14,
                    left: (screenW / 2) - 62,
                    child: _glowingAvatar(
                      imageUrl: _getDisplayAvatarUrl(),
                      size: 124,
                    ),
                  ),
                  ],
                ),

                // White card content below header
                Container(
                  margin: ResponsiveUtils.getResponsivePadding(context, horizontal: 4.5),
                  padding: EdgeInsets.fromLTRB(
                    ResponsiveUtils.getResponsiveWidth(context, 4.5),
                    ResponsiveUtils.getResponsiveHeight(context, 2.25),
                    ResponsiveUtils.getResponsiveWidth(context, 4.5),
                    ResponsiveUtils.getResponsiveHeight(context, 11.25),
                  ),
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

                        _segmentControl(),

                        SizedBox(height: ResponsiveUtils.getResponsiveHeight(context, 1.5)),

                        // Show content based on selected tab
                        IndexedStack(
                          index: selectedSegment,
                          children: [
                            // Posts tab
                            hasRealData && _posts.isEmpty
                                ? Container(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.image_outlined,
                                          size: 64,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No posts yet',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Upload your first post to get started',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: () => _openCreateBottomSheet(context),
                                          icon: const Icon(Icons.add),
                                          label: const Text('Create Post'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange.shade400,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : _loadingPosts
                                    ? _buildPostsSkeleton()
                                    : GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      mainAxisSpacing: ResponsiveUtils.getResponsiveWidth(context, 2.5),
                                      crossAxisSpacing: ResponsiveUtils.getResponsiveWidth(context, 2.5),
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
                                        return GestureDetector(
                                          onTap: () => _showPostFullScreen(post),
                                          onLongPress: () => _showDeletePostDialog(post),
                                          child: Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Container(
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  child: mediaUrl != null
                                                      ? Image.network(
                                                          mediaUrl, 
                                                          width: double.infinity,
                                                          height: double.infinity,
                                                          fit: BoxFit.cover,
                                                          loadingBuilder: (context, child, loadingProgress) {
                                                            if (loadingProgress == null) return child;
                                                            return Container(
                                                              width: double.infinity,
                                                              height: double.infinity,
                                                              color: Colors.grey.shade200,
                                                              child: const Center(
                                                                child: CircularProgressIndicator(
                                                                  strokeWidth: 2,
                                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                          errorBuilder: (context, error, stackTrace) {
                                                            return Container(
                                                              width: double.infinity,
                                                              height: double.infinity,
                                                              color: Colors.grey.shade200,
                                                              child: const Icon(
                                                                Icons.image_not_supported,
                                                                color: Colors.grey,
                                                                size: 32,
                                                              ),
                                                            );
                                                          },
                                                        )
                                                      : Container(
                                                          width: double.infinity,
                                                          height: double.infinity,
                                                          color: Colors.grey.shade200,
                                                        ),
                                                ),
                                              ),
                                              // Delete button overlay
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: GestureDetector(
                                                  onTap: () => _showDeletePostDialog(post),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red.withOpacity(0.8),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          width: double.infinity,
                                          height: double.infinity,
                                          child: Image.network(
                                            'https://images.unsplash.com/photo-1508672019048-805c876b67e2?w=800&q=80&auto=format&fit=crop', 
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Container(
                                                width: double.infinity,
                                                height: double.infinity,
                                                color: Colors.grey.shade200,
                                                child: const Center(
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                                  ),
                                                ),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                width: double.infinity,
                                                height: double.infinity,
                                                color: Colors.grey.shade200,
                                                child: const Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.grey,
                                                  size: 32,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                            // Videos tab
                            _buildVideosList(),
                            // Stories tab
                            _buildStoriesList(),
                            // Events/Live Sessions tab
                            _buildEventsList(),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
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
    );
  }

  Widget _buildTag(String text, Color bg, Color textColor, {bool isSmall = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12, 
        vertical: isSmall ? 4 : 6
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text, 
        style: TextStyle(
          color: textColor, 
          fontWeight: FontWeight.w600,
          fontSize: isSmall ? 11 : 12,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _buildPostsSkeleton() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: ResponsiveUtils.getResponsiveWidth(context, 2.5),
        crossAxisSpacing: ResponsiveUtils.getResponsiveWidth(context, 2.5),
        childAspectRatio: 1,
      ),
      itemCount: 6,
      itemBuilder: (context, i) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
            ),
          ),
        );
      },
    );
  }

  static Widget _glowingAvatar({required String imageUrl, double size = 100}) {
    final isValidUrl = AvatarUtils.isValidAvatarUrl(imageUrl);
    
    return Stack(
      children: [
        // Frame background (same as Baba pages)
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/babji_dp_bg_frame.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        
        // Profile picture positioned within the frame
        Positioned(
          left: size * 0.2, // More centered positioning
          top: size * 0.2,
          child: Container(
            width: size * 0.6, // Smaller size to show more frame
            height: size * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, spreadRadius: 1),
              ],
            ),
            child: ClipOval(
              child: isValidUrl
                  ? Image.network(
                      imageUrl,
                      width: size * 0.6,
                      height: size * 0.6,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to gradient if image fails to load
                        return Container(
                          width: size * 0.6,
                          height: size * 0.6,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.withOpacity(0.1),
                                Colors.orange.withOpacity(0.3),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      width: size * 0.6,
                      height: size * 0.6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.withOpacity(0.1),
                            Colors.orange.withOpacity(0.3),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _smallStatCard({required IconData icon, required String value, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(6),
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  value, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label, 
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _segmentControl() {
    final labels = ['Posts', 'Videos', 'Stories', 'Events'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 350) {
              // For small screens, use a scrollable horizontal list
              return Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: labels.length,
                  itemBuilder: (context, i) {
                    final isSelected = i == selectedSegment;
                    return GestureDetector(
                      onTap: () {
                         setState(() => selectedSegment = i);
                         // Only load data if not already loaded
                         if (i == 0 && widget.babaPage != null && !_postsLoaded && _posts.isEmpty) {
                           _fetchPosts(widget.babaPage!);
                         }
                         if (i == 1 && widget.babaPage != null && !_videosLoaded && _videos.isEmpty) {
                           _fetchVideos(widget.babaPage!);
                         }
                         if (i == 2 && widget.babaPage != null && !_storiesLoaded && _stories.isEmpty) {
                           _fetchStories(widget.babaPage!);
                         }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                              fontSize: 11,
                              color: isSelected ? Colors.black87 : Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            } else if (constraints.maxWidth < 400) {
              // For medium screens, use reduced margins and smaller font
              return Container(
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
                        onTap: () {
                         setState(() => selectedSegment = i);
                         // Only load data if not already loaded
                         if (i == 0 && widget.babaPage != null && !_postsLoaded && _posts.isEmpty) {
                           _fetchPosts(widget.babaPage!);
                         }
                         if (i == 1 && widget.babaPage != null && !_videosLoaded && _videos.isEmpty) {
                           _fetchVideos(widget.babaPage!);
                         }
                         if (i == 2 && widget.babaPage != null && !_storiesLoaded && _stories.isEmpty) {
                           _fetchStories(widget.babaPage!);
                         }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          margin: const EdgeInsets.symmetric(horizontal: 1),
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
                                fontSize: 10,
                                color: isSelected ? Colors.black87 : Colors.grey[600],
                              ),
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
            } else {
              // For normal screens, use the original layout with reduced margins
              return Container(
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
                        onTap: () {
                         setState(() => selectedSegment = i);
                         // Only load data if not already loaded
                         if (i == 0 && widget.babaPage != null && !_postsLoaded && _posts.isEmpty) {
                           _fetchPosts(widget.babaPage!);
                         }
                         if (i == 1 && widget.babaPage != null && !_videosLoaded && _videos.isEmpty) {
                           _fetchVideos(widget.babaPage!);
                         }
                         if (i == 2 && widget.babaPage != null && !_storiesLoaded && _stories.isEmpty) {
                           _fetchStories(widget.babaPage!);
                         }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
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
                                fontSize: 11,
                                color: isSelected ? Colors.black87 : Colors.grey[600],
                              ),
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
          },
        ),
      ],
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
          initialChildSize: 0.45,
          minChildSize: 0.35,
          maxChildSize: 0.8,
          builder: (context, scrollController) {
            return Container(
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
                      Expanded(
                        child: _createTile(
                          icon: Icons.grid_3x3_outlined,
                          label: 'Post',
                          color: const Color(0xFF2196F3), // Vibrant blue
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
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _createTile(
                          icon: Icons.video_call_outlined,
                          label: 'Reel',
                          color: const Color(0xFF4CAF50), // Vibrant green
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
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _createTile(
                          icon: Icons.auto_stories_outlined,
                          label: 'Story',
                          color: const Color(0xFFFF9800), // Vibrant orange
                          onTap: page == null ? null : () async {
                            Navigator.pop(context);
                            final ok = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BabaPageStoryUploadScreen(babaPage: page),
                              ),
                            );
                            if (ok == true) {
                              _fetchStories(page);
                            }
                          },
                        ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              label, 
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchPosts(BabaPage page) async {
    // Always allow fetching posts to ensure they show permanently
    if (_loadingPosts) return; // Only prevent if already loading
    
    try {
      setState(() => _loadingPosts = true);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.authToken;
      if (token == null) {
        print('BabaProfileUiDemo: No auth token found');
        setState(() => _loadingPosts = false);
        return;
      }
      
      print('BabaProfileUiDemo: Fetching posts for page ${page.id} (${page.name})');
      print('BabaProfileUiDemo: Using token: ${token.substring(0, 20)}...');
      
      // Load more posts to ensure we get all uploaded posts
      final resp = await BabaPagePostService.getBabaPagePosts(
        babaPageId: page.id,
        token: token,
        page: 1,
        limit: 20, // Increased limit to get more posts
      );
      
      print('BabaProfileUiDemo: API Response - Success: ${resp.success}');
      print('BabaProfileUiDemo: API Response - Message: ${resp.message}');
      print('BabaProfileUiDemo: API Response - Posts count: ${resp.posts.length}');
      
      if (!mounted) return;
      setState(() {
        _posts = resp.posts;
        _loadingPosts = false;
        _postsLoaded = true;
      });
      
      print('BabaProfileUiDemo: Loaded ${resp.posts.length} posts');
      if (resp.posts.isNotEmpty) {
        print('BabaProfileUiDemo: Posts data: ${resp.posts.map((p) => '${p.id}: "${p.content.substring(0, p.content.length > 20 ? 20 : p.content.length)}..." (${p.media.length} media)').join(', ')}');
        
        // Debug each post
        for (int i = 0; i < resp.posts.length; i++) {
          final post = resp.posts[i];
          print('BabaProfileUiDemo: Post $i - ID: ${post.id}, Content: "${post.content}", Media: ${post.media.length}');
          for (int j = 0; j < post.media.length; j++) {
            print('BabaProfileUiDemo:   Media $j - URL: ${post.media[j].url}');
          }
        }
      } else {
        print('BabaProfileUiDemo: No posts returned from API');
      }
    } catch (e) {
      print('BabaProfileUiDemo: Error fetching posts: $e');
      print('BabaProfileUiDemo: Error stack trace: ${StackTrace.current}');
      if (!mounted) return;
      setState(() {
        _loadingPosts = false;
        _postsLoaded = true; // Mark as loaded even on error to prevent retry
      });
    }
  }

  Future<void> _fetchVideos(BabaPage page) async {
    if (_loadingVideos) return; // Prevent multiple simultaneous calls
    
    try {
      if (mounted) {
        setState(() => _loadingVideos = true);
      }
      
      List<MediaData> videos = [];
      
      // Get videos from server for this specific Baba page
      try {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final token = auth.authToken;
        if (token != null) {
          print('BabaProfileUiDemo: Fetching videos from server for page ${page.id}');
          
          // Fetch videos from server using BabaPageReelService
          final reelsResponse = await BabaPageReelService.getBabaPageReels(
            babaPageId: page.id,
            token: token,
            page: 1,
            limit: 8, // Reduced from 20 to 8 for faster loading
          );
          
          if (reelsResponse['success'] == true) {
            final reelsData = reelsResponse['data']['videos'] as List<dynamic>? ?? [];
            print('BabaProfileUiDemo: Server returned ${reelsData.length} videos');
            
            // Convert server videos to MediaData format
            for (final reelData in reelsData) {
              final reel = BabaPageReel.fromJson(reelData);
              if (reel.video.url.isNotEmpty) {
                videos.add(MediaData(
                  mediaId: reel.id,
                  publicId: '',
                  secureUrl: reel.video.url,
                  folderPath: '',
                  fileName: reel.title.isNotEmpty ? reel.title : '${reel.babaPageId}_${reel.id}',
                  fileType: 'video',
                  fileSize: 0,
                  dimensions: {},
                  duration: 0,
                  uploadedBy: reel.babaPageId,
                  username: page.name,
                  uploadedAt: reel.createdAt,
                ));
              }
            }
          } else {
            print('BabaProfileUiDemo: Server returned error: ${reelsResponse['message']}');
          }
        }
      } catch (e) {
        print('Error fetching server videos: $e');
      }
      
      // Also get videos from local storage (reels) as backup - ONLY for this specific BabaPage
      try {
        final localReels = await LocalStorageService.getUserReels();
        
        // Filter local reels to only include videos uploaded by this specific BabaPage
        final filteredLocalReels = localReels.where((reel) {
          // Only include videos that belong to this specific BabaPage
          return reel.userId == page.id || reel.username == page.name;
        }).toList();
        
        print('BabaProfileUiDemo: Filtered ${filteredLocalReels.length} local videos for page ${page.id} (${page.name})');
        
        // Convert filtered local reels to MediaData format for consistency
        for (final reel in filteredLocalReels) {
          if (reel.videoUrl != null && reel.videoUrl!.isNotEmpty) {
            // Check if this video is already added from server
            final alreadyExists = videos.any((v) => v.secureUrl == reel.videoUrl);
            if (!alreadyExists) {
              videos.add(MediaData(
                mediaId: reel.id,
                publicId: '',
                secureUrl: reel.videoUrl!,
                folderPath: '',
                fileName: (reel.caption?.isNotEmpty == true) ? reel.caption! : '${reel.username}_${reel.id}',
                fileType: 'video',
                fileSize: 0,
                dimensions: {},
                duration: 0,
                uploadedBy: reel.userId,
                username: reel.username,
                uploadedAt: reel.createdAt,
              ));
            }
          }
        }
      } catch (e) {
        print('Error fetching local reels: $e');
      }
      
      // Final filter to ensure only videos from this specific BabaPage are shown
      final finalVideos = videos.where((video) {
        // Only include videos that belong to this specific BabaPage
        return video.uploadedBy == page.id || video.username == page.name;
      }).toList();
      
      print('BabaProfileUiDemo: Final filtered videos for page ${page.id} (${page.name}): ${finalVideos.length}');
      
      // Update UI with filtered videos
      if (mounted) {
        setState(() {
          _videos = finalVideos;
          _loadingVideos = false;
        });
      }
      print('BabaProfileUiDemo: Loaded ${finalVideos.length} videos for ${page.name}');
      print('BabaProfileUiDemo: Videos data: ${finalVideos.map((v) => '${v.mediaId}: ${v.secureUrl} (${v.username})').join(', ')}');
      
    } catch (e) {
      print('Error fetching videos: $e');
      if (mounted) {
        setState(() => _loadingVideos = false);
      }
    }
  }

  Future<void> _fetchStories(BabaPage page) async {
    if (_loadingStories) return; // Prevent multiple simultaneous calls
    
    try {
      if (mounted) {
        setState(() => _loadingStories = true);
      }
      
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.authToken;
      
      if (token != null) {
        print('BabaProfileUiDemo: Fetching stories from server for page ${page.id}');
        
        // Fetch stories from server using BabaPageStoryService
        final stories = await BabaPageStoryService.getBabaPageStories(
          babaPageId: page.id,
          token: token,
          page: 1,
          limit: 20,
        );
        
        print('BabaProfileUiDemo: Server returned ${stories.length} stories');
        
        // Update UI with stories
        if (mounted) {
          setState(() {
            _stories = stories;
            _loadingStories = false;
          });
        }
        
        print('BabaProfileUiDemo: Loaded ${stories.length} stories');
        if (stories.isNotEmpty) {
          print('BabaProfileUiDemo: Stories data: ${stories.map((s) => '${s.id}: "${s.content.substring(0, s.content.length > 20 ? 20 : s.content.length)}..." (${s.media.type})').join(', ')}');
        } else {
          print('BabaProfileUiDemo: No stories returned from API');
        }
      } else {
        print('BabaProfileUiDemo: No auth token found');
        if (mounted) {
          setState(() => _loadingStories = false);
        }
      }
    } catch (e) {
      print('BabaProfileUiDemo: Error fetching stories: $e');
      if (mounted) {
        setState(() => _loadingStories = false);
      }
    }
  }

  Widget _buildVideosList() {
    if (_loadingVideos) {
      return Column(
        children: List.generate(3, (index) => _buildVideoItemSkeleton()),
      );
    }

    if (_videos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No videos uploaded yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload your first video to get started',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 columns for grid layout
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 0.8, // Balanced aspect ratio to match first image
      ),
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        return _buildVideoItem(_videos[index]);
      },
    );
  }

  Widget _buildVideoItem(MediaData video) {
    return Container(
      key: ValueKey('video_${video.mediaId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Minimize space usage
        children: [
          // Video thumbnail container (balanced height)
          Container(
            height: 80, // Balanced height for better appearance
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: GestureDetector(
                onTap: () {
                  _playVideoWithSound(video);
                },
                child: Stack(
                  children: [
                    // Static video thumbnail
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Stack(
                            children: [
                              // Video thumbnail placeholder with gradient
                              Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.grey.shade300,
                                      Colors.grey.shade400,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              // Video file icon
                              Center(
                                child: Icon(
                                  Icons.video_file,
                                  color: Colors.grey.shade600,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Play button overlay
                    Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Video info bar (balanced for grid) - Balanced height for better appearance
          Container(
            height: 16, // Balanced height for better appearance
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.video_file,
                  size: 8,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                // Use Flexible instead of Expanded to prevent ParentDataWidget error
                Flexible(
                  child: Text(
                    'Uploaded ${_formatDate(video.uploadedAt)}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 7, // Balanced font size for better readability
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                // Delete button
                GestureDetector(
                  onTap: () {
                    _deleteVideoDirectly(video);
                  },
                  child: Icon(
                    Icons.delete_outline,
                    size: 8, // Balanced icon size for better visibility
                    color: Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Video title (balanced) - Balanced height
          if (video.fileName.isNotEmpty)
            Container(
              height: 12, // Balanced height
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                video.fileName,
                style: const TextStyle(
                  fontSize: 8, // Balanced font size
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoItemSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Caption skeleton
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Container(
              height: 16,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          
          // Video bar skeleton
          Container(
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
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesList() {
    if (_loadingStories) {
      return Column(
        children: List.generate(3, (index) => _buildStoryItemSkeleton()),
      );
    }

    if (_stories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No stories yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first story',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openCreateBottomSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Story'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade400,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 columns for grid layout
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 0.8, // Balanced aspect ratio for stories
      ),
      itemCount: _stories.length,
      itemBuilder: (context, index) {
        return _buildStoryItem(_stories[index]);
      },
    );
  }

  Widget _buildStoryItem(BabaPageStory story) {
    return Container(
      key: ValueKey('story_${story.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Minimize space usage
        children: [
          // Story thumbnail container (balanced height)
          Container(
            height: 80, // Balanced height for better appearance
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: GestureDetector(
                onTap: () => _openStoryViewer(story),
                child: Stack(
                  children: [
                    // Story media thumbnail
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: story.media.url.isNotEmpty
                            ? Image.network(
                                story.media.url,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    color: Colors.grey.shade300,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    color: Colors.grey.shade300,
                                    child: const Center(
                                      child: Icon(
                                        Icons.auto_stories,
                                        color: Colors.grey,
                                        size: 32,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: Colors.grey.shade300,
                                child: const Center(
                                  child: Icon(
                                    Icons.auto_stories,
                                    color: Colors.grey,
                                    size: 32,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    // Story icon overlay
                    Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_stories,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Story info bar (balanced for grid) - Balanced height for better appearance
          Container(
            height: 16, // Balanced height for better appearance
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_stories,
                  size: 8,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                // Use Flexible instead of Expanded to prevent ParentDataWidget error
                Flexible(
                  child: Text(
                    'Views ${story.viewsCount}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 7, // Balanced font size for better readability
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                // Delete button
                GestureDetector(
                  onTap: () => _showDeleteStoryConfirmation(story),
                  child: Icon(
                    Icons.delete_outline,
                    size: 8, // Balanced icon size for better visibility
                    color: Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Story title (balanced) - Balanced height
          if (story.content.isNotEmpty)
            Container(
              height: 12, // Balanced height
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                story.content,
                style: const TextStyle(
                  fontSize: 8, // Balanced font size
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  // Convert BabaPageStory to Story format for story viewer
  Story _convertBabaPageStoryToStory(BabaPageStory babaStory) {
    return Story(
      id: babaStory.id,
      authorId: widget.babaPage?.id ?? '',
      authorName: widget.babaPage?.name ?? 'Babaji',
      authorUsername: widget.babaPage?.name ?? 'babaji',
      authorAvatar: widget.babaPage?.avatar,
      media: babaStory.media.url,
      mediaId: babaStory.id,
      type: babaStory.media.type,
      mentions: [],
      hashtags: [],
      isActive: babaStory.isActive,
      views: [],
      viewsCount: babaStory.viewsCount,
      expiresAt: babaStory.expiresAt,
      createdAt: babaStory.createdAt,
      updatedAt: babaStory.updatedAt,
    );
  }

  // Open story viewer for a specific story
  void _openStoryViewer(BabaPageStory story) {
    // Convert all stories to Story format
    final allStories = _stories.map((s) => _convertBabaPageStoryToStory(s)).toList();
    final currentStory = _convertBabaPageStoryToStory(story);
    final initialIndex = _stories.indexOf(story);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewerScreen(
          story: currentStory,
          allStories: allStories,
          initialIndex: initialIndex >= 0 ? initialIndex : 0,
        ),
      ),
    );
  }

  Widget _buildStoryItemSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      height: 12,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      height: 12,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 12,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.event_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No events scheduled',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Schedule your first live session',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _getVideoCaption(MediaData video) {
    // Generate caption similar to "demo by dhani"
    final username = video.username.isNotEmpty ? video.username : 'User';
    
    // Sample captions for different video types
    final captions = [
      'spiritual moment by $username',
      'peaceful thoughts by $username',
      'meditation by $username',
      'wisdom by $username',
      'blessing by $username',
      'guidance by $username',
      'inspiration by $username',
    ];
    
    // Use video ID to consistently pick the same caption for the same video
    final index = video.mediaId.hashCode.abs() % captions.length;
    return captions[index];
  }


  /// Play video with sound in full screen
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
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  Navigator.pop(context);
                  _deleteVideoDirectly(video);
                },
              ),
            ],
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

  void _showDeleteVideoDialog(MediaData video) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Video'),
          content: Text('Are you sure you want to delete "${video.fileName}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteVideo(video);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteVideoDirectly(MediaData video) async {
    try {
      // Show confirmation dialog first
      final bool? shouldDelete = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Delete Video'),
            content: Text('Are you sure you want to delete "${video.fileName}"? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );

      if (shouldDelete != true) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Delete from server first
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.authToken;
      
      if (token != null && widget.babaPage != null) {
        try {
          // Use BabaPageReelService to delete the video
          final response = await BabaPageReelService.deleteBabaPageReel(
            reelId: video.mediaId,
            babaPageId: widget.babaPage!.id,
            token: token,
          );

          // Close loading dialog
          if (mounted) Navigator.pop(context);

          if (response['success'] == true) {
            // Remove from current list
            setState(() {
              _videos.removeWhere((v) => v.mediaId == video.mediaId);
            });
            
            // Also delete from local storage
            try {
              await LocalStorageService.deleteReel(video.mediaId);
            } catch (e) {
              print('Error deleting from local storage: $e');
            }
            
            // Show success message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Video deleted successfully'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } else {
            // Show error message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(response['message'] ?? 'Failed to delete video'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        } catch (e) {
          // Close loading dialog
          if (mounted) Navigator.pop(context);
          
          print('Error deleting video from server: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error deleting video: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        // Close loading dialog
        if (mounted) Navigator.pop(context);
        
        // Fallback: delete from local storage only
        setState(() {
          _videos.removeWhere((v) => v.mediaId == video.mediaId);
        });
        
        try {
          await LocalStorageService.deleteReel(video.mediaId);
        } catch (e) {
          print('Error deleting from local storage: $e');
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video deleted from local storage'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      print('Error in delete video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting video: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _deleteVideo(MediaData video) async {
    try {
      // Delete from local storage
      await LocalStorageService.deleteReel(video.mediaId);
      
      // Remove from current list
      setState(() {
        _videos.removeWhere((v) => v.mediaId == video.mediaId);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting video: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDPUploadOptions(BuildContext context) {
    final page = widget.babaPage;
    if (page == null) {
      _showSnackBar('Please select a Baba Ji page first', Colors.orange);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Change Profile Picture',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.blue),
              ),
              title: const Text('Take Photo'),
              subtitle: const Text('Use camera to take a new photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library, color: Colors.green),
              ),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select photo from your gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            if ((_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty) || page.avatar.isNotEmpty)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.red),
                ),
                title: const Text('Remove Current Photo'),
                subtitle: const Text('Delete your current profile picture'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteCurrentDP();
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadDP(File(image.path));
      }
    } catch (e) {
      _showSnackBar('Error taking photo: $e', Colors.red);
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadDP(File(image.path));
      }
    } catch (e) {
      _showSnackBar('Error selecting image: $e', Colors.red);
    }
  }

  Future<void> _uploadDP(File imageFile) async {
    final page = widget.babaPage;
    if (page == null) {
      _showSnackBar('Please select a Baba Ji page first', Colors.orange);
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.authToken;
    if (token == null || token.isEmpty) {
      _showSnackBar('Please login first', Colors.red);
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      print('BabaProfileUiDemoScreen: Starting DP upload for page ${page.id}');
      
      final response = await BabaPageDPService.uploadBabaPageDP(
        imageFile: imageFile,
        babaPageId: page.id,
        token: token,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (response['success'] == true) {
        final data = response['data'];
        final avatarUrl = data['avatarUrl'] as String?;
        
        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          // Update local state with new avatar URL
          setState(() {
            _currentAvatarUrl = avatarUrl;
          });
          
          // The local state will handle the display, and the server has the updated avatar
          // The parent screens will get the updated avatar when they refresh their data
          
          _showSnackBar('Baba Ji page display picture uploaded successfully!', Colors.green);
        } else {
          _showSnackBar('Upload successful but no image URL returned', Colors.orange);
        }
      } else {
        _showSnackBar(
          response['message'] ?? 'Failed to upload display picture',
          Colors.red,
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      print('BabaProfileUiDemoScreen: DP upload error: $e');
      _showSnackBar('Error uploading display picture: $e', Colors.red);
    }
  }

  Future<void> _deleteCurrentDP() async {
    final page = widget.babaPage;
    if (page == null) {
      _showSnackBar('Please select a Baba Ji page first', Colors.orange);
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.authToken;
    if (token == null || token.isEmpty) {
      _showSnackBar('Please login first', Colors.red);
      return;
    }

    // Show confirmation dialog
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Display Picture'),
          content: const Text('Are you sure you want to delete this display picture? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      print('BabaProfileUiDemoScreen: Starting DP delete for page ${page.id}');
      
      final response = await BabaPageDPService.deleteBabaPageDP(
        babaPageId: page.id,
        token: token,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (response['success'] == true) {
        // Update local state
        setState(() {
          _currentAvatarUrl = '';
        });
        
        _showSnackBar('Display picture deleted successfully!', Colors.green);
      } else {
        _showSnackBar(
          response['message'] ?? 'Failed to delete display picture',
          Colors.red,
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      print('BabaProfileUiDemoScreen: DP delete error: $e');
      _showSnackBar('Error deleting display picture: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showPostFullScreen(BabaPagePost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              'Post',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  Navigator.pop(context);
                  _showDeletePostDialog(post);
                },
              ),
            ],
          ),
          body: Center(
            child: post.media.isNotEmpty
                ? InteractiveViewer(
                    child: Image.network(
                      post.media.first.url,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      },
                    ),
                  )
                : const Center(
                    child: Text(
                      'No media available',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _showDeletePostDialog(BabaPagePost post) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Post'),
          content: Text('Are you sure you want to delete this post? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
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
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePost(BabaPagePost post) async {
    final page = widget.babaPage;
    if (page == null) {
      _showSnackBar('Please select a Baba Ji page first', Colors.orange);
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.authToken;
    if (token == null || token.isEmpty) {
      _showSnackBar('Please login first', Colors.red);
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      print('BabaProfileUiDemoScreen: Starting post delete for post ${post.id}');
      
      final response = await BabaPagePostService.deleteBabaPagePost(
        postId: post.id,
        babaPageId: page.id,
        token: token,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (response.success) {
        // Remove from current list
        setState(() {
          _posts.removeWhere((p) => p.id == post.id);
        });
        
        _showSnackBar('Post deleted successfully!', Colors.green);
      } else {
        _showSnackBar(
          response.message ?? 'Failed to delete post',
          Colors.red,
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      print('BabaProfileUiDemoScreen: Post delete error: $e');
      _showSnackBar('Error deleting post: $e', Colors.red);
    }
  }

  /// Show delete confirmation dialog for Babaji story
  void _showDeleteStoryConfirmation(BabaPageStory story) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Babaji Story'),
        content: const Text('Are you sure you want to delete this Babaji story? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteBabajiStory(story);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Delete a Babaji story
  Future<void> _deleteBabajiStory(BabaPageStory story) async {
    try {
      print('BabaProfileUiDemo: Deleting Babaji story ${story.id}');
      
      // Get auth token
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to delete stories'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deleting Babaji story...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      // Delete the story using BabaPageStoryService
      final success = await BabaPageStoryService.deleteBabaPageStory(
        storyId: story.id,
        babaPageId: story.babaPageId,
        token: token,
      );
      
      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Babaji story deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh the stories list
        if (widget.babaPage != null) {
          _fetchStories(widget.babaPage!);
        }
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete Babaji story'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
    } catch (e) {
      print('Error deleting Babaji story: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting Babaji story: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
      _followers = page.followersCount;
      print('_FollowButton: Initial followers count: $_followers');
      
      // Load follow state from SharedPreferences first, then check server
      _loadFollowStateFromPrefs();
    }
  }

  /// Load follow state from SharedPreferences
  Future<void> _loadFollowStateFromPrefs() async {
    final page = widget.page;
    if (page == null) return;
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userProfile?.id;
      
      if (userId != null) {
        final isFollowing = await FollowStateService.getFollowState(
          userId: userId,
          pageId: page.id,
          serverState: page.isFollowing,
        );
        
        if (mounted) {
          setState(() {
            _isFollowing = isFollowing;
          });
          print('_FollowButton: Loaded follow state from prefs: $_isFollowing');
        }
      } else {
        if (mounted) {
          setState(() {
            _isFollowing = page.isFollowing;
          });
        }
      }
      
      // Also check follow status from server to ensure consistency
      _checkFollowStatus();
    } catch (e) {
      print('_FollowButton: Error loading follow state from preferences: $e');
      if (mounted) {
        setState(() {
          _isFollowing = page.isFollowing;
        });
      }
      _checkFollowStatus();
    }
  }

  /// Save follow state to SharedPreferences
  Future<void> _saveFollowState(bool isFollowing) async {
    final page = widget.page;
    if (page == null) return;
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userProfile?.id;
      
      if (userId != null) {
        await FollowStateService.saveFollowState(
          userId: userId,
          pageId: page.id,
          isFollowing: isFollowing,
        );
      }
    } catch (e) {
      print('_FollowButton: Error saving follow state: $e');
    }
  }

  Future<void> _checkFollowStatus() async {
    final page = widget.page;
    if (page == null) return;
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.authToken;
    
    if (token == null) return;
    
    try {
      print('_FollowButton: Checking follow status for page ${page.id}');
      
      // Get the current Baba page data to check follow status
      final response = await BabaPageService.getBabaPages(token: token, page: 1, limit: 50);
      if (response.success) {
        final currentPage = response.pages.firstWhere(
          (p) => p.id == page.id,
          orElse: () => page,
        );
        
        // Use FollowStateService to get the correct follow state
        final userId = auth.userProfile?.id;
        bool serverFollowState = currentPage.isFollowing;
        
        if (userId != null) {
          serverFollowState = await FollowStateService.getFollowState(
            userId: userId,
            pageId: page.id,
            serverState: currentPage.isFollowing,
          );
        }
        
        if (mounted) {
          setState(() {
            _isFollowing = serverFollowState;
            _followers = currentPage.followersCount;
          });
          print('_FollowButton: Updated follow status: $_isFollowing, followers: $_followers');
        }
      } else {
        print('_FollowButton: Failed to get pages list: ${response.message}');
        // If we can't get the pages list, try to get individual page
        try {
          final individualResponse = await BabaPageService.getBabaPageById(
            pageId: page.id,
            token: token,
          );
          if (individualResponse.success && individualResponse.data != null) {
            // Use FollowStateService to get the correct follow state
            final userId = auth.userProfile?.id;
            bool serverFollowState = individualResponse.data!.isFollowing;
            
            if (userId != null) {
              serverFollowState = await FollowStateService.getFollowState(
                userId: userId,
                pageId: page.id,
                serverState: individualResponse.data!.isFollowing,
              );
            }
            
            if (mounted) {
              setState(() {
                _isFollowing = serverFollowState;
                _followers = individualResponse.data!.followersCount;
              });
              print('_FollowButton: Updated follow status from individual page: $_isFollowing, followers: $_followers');
            }
          }
        } catch (e) {
          print('_FollowButton: Error getting individual page: $e');
        }
      }
    } catch (e) {
      print('_FollowButton: Error checking follow status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRealData = widget.page != null;
    
    // Determine button colors based on follow state
    final backgroundColor = _isFollowing ? Colors.blue.shade600 : Colors.white;
    final textColor = _isFollowing ? Colors.white : Colors.blue.shade800;
    final borderColor = _isFollowing ? Colors.blue.shade600 : Colors.blue.shade200;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adjust padding and font size based on available width
        final horizontalPadding = constraints.maxWidth < 200 ? 16.0 : 20.0;
        final fontSize = constraints.maxWidth < 200 ? 12.0 : 14.0;
        
        return ElevatedButton(
          onPressed: !_loading && hasRealData ? _toggleFollow : null,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            backgroundColor: backgroundColor,
            elevation: _isFollowing ? 2 : 0,
            side: BorderSide(color: borderColor, width: 1.5),
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10),
            animationDuration: const Duration(milliseconds: 200),
          ),
          child: _loading 
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Flexible(
                child: Text(
                  _isFollowing ? 'Following ($_followers)' : 'Follow ($_followers)',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
        );
      },
    );
  }

  Future<void> _toggleFollow() async {
    final page = widget.page!;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.authToken;
    
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _loading = true);
    
    try {
      print('_FollowButton: Toggling follow status. Current: $_isFollowing');
      if (_isFollowing) {
        // Unfollow the Baba Ji page
        print('_FollowButton: Unfollowing page ${page.id}');
        final resp = await BabaPageService.unfollowBabaPage(pageId: page.id, token: token);
        print('_FollowButton: Unfollow response: ${resp.success}, ${resp.message}');
        
        if (resp.success) {
          // Save follow state to SharedPreferences
          await _saveFollowState(false);
          
          setState(() {
            _isFollowing = false;
            _followers = (_followers - 1).clamp(0, 1 << 31);
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Unfollowed ${page.name}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
            
            // Trigger feed refresh to update home screen content
            FeedRefreshService().refreshFeed();
          }
        } else {
          // Handle specific error cases
          String errorMessage = resp.message;
          if (errorMessage.toLowerCase().contains('not following') || 
              errorMessage.toLowerCase().contains('not found')) {
            // If we're not actually following, update UI to reflect this
            await _saveFollowState(false);
            setState(() {
              _isFollowing = false;
            });
            errorMessage = 'You are not following this page';
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to unfollow: $errorMessage'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        // Follow the Baba Ji page
        print('_FollowButton: Following page ${page.id}');
        final resp = await BabaPageService.followBabaPage(pageId: page.id, token: token);
        print('_FollowButton: Follow response: ${resp.success}, ${resp.message}');
        
        if (resp.success) {
          // Save follow state to SharedPreferences
          await _saveFollowState(true);
          
          setState(() {
            _isFollowing = true;
            _followers = _followers + 1;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Following ${page.name}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
            
            // Trigger feed refresh to update home screen content
            FeedRefreshService().refreshFeed();
          }
        } else {
          // Handle specific error cases
          String errorMessage = resp.message;
          if (errorMessage.toLowerCase().contains('already following')) {
            // If we're already following, update UI to reflect this
            await _saveFollowState(true);
            setState(() {
              _isFollowing = true;
            });
            errorMessage = 'You are already following this page';
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to follow: $errorMessage'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Follow/Unfollow error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

}

/// Simple video player widget with minimal controls (like the second image)
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
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isDisposed = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (_isInitialized) {
      player.dispose();
    }
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      MediaKit.ensureInitialized();
      player = Player();
      videoController = VideoController(player);

      // Set up event listeners
      player.stream.playing.listen((playing) {
        if (mounted && !_isDisposed) {
          setState(() {
            _isPlaying = playing;
          });
        }
      });

      player.stream.duration.listen((duration) {
        if (mounted && !_isDisposed) {
          setState(() {
            _duration = duration;
          });
        }
      });

      player.stream.position.listen((position) {
        if (mounted && !_isDisposed) {
          setState(() {
            _position = position;
          });
        }
      });

      await player.open(Media(widget.videoUrl));
      
      if (mounted && !_isDisposed) {
        setState(() {
          _isInitialized = true;
        });
        // Auto-play the video
        player.play();
      }
    } catch (e) {
      print('SimpleVideoPlayer: Error initializing: $e');
    }
  }

  void _togglePlayPause() {
    if (!_isInitialized) return;
    
    if (_isPlaying) {
      player.pause();
    } else {
      player.play();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Stack(
        children: [
          // Video player
          if (_isInitialized)
            Video(
              controller: videoController,
              controls: NoVideoControls, // No built-in controls
            )
          else
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),

          // Simple custom controls overlay
          if (_showControls)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Column(
                  children: [
                    // Spacer to push controls to bottom
                    const Spacer(),
                    
                    // Play/Pause button in center
                    GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Progress bar at bottom
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Colors.white,
                                inactiveTrackColor: Colors.white.withOpacity(0.3),
                                thumbColor: Colors.white,
                                overlayColor: Colors.white.withOpacity(0.2),
                                trackHeight: 2,
                              ),
                              child: Slider(
                                value: _duration.inMilliseconds > 0
                                    ? _position.inMilliseconds / _duration.inMilliseconds
                                    : 0.0,
                                onChanged: (value) {
                                  if (_isInitialized) {
                                    final newPosition = Duration(
                                      milliseconds: (value * _duration.inMilliseconds).round(),
                                    );
                                    player.seek(newPosition);
                                  }
                                },
                              ),
                            ),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}


