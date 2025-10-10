import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/custom_http_client.dart';
// Removed Cloudinary dependency
import '../utils/app_theme.dart';

class StoryWidget extends StatelessWidget {
  final String storyId;
  final String userId;
  final String userName;
  final String? userImage;
  final String? storyImage;
  final bool isViewed;
  final VoidCallback onTap;
  final String? currentUserId; // Add current user ID to check if story can be deleted
  final VoidCallback? onDelete; // Add delete callback
  final String? storyType; // Add story type to show video indicator

  const StoryWidget({
    super.key,
    required this.storyId,
    required this.userId,
    required this.userName,
    this.userImage,
    this.storyImage,
    required this.isViewed,
    required this.onTap,
    this.currentUserId,
    this.onDelete,
    this.storyType,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Responsive sizing based on screen size
    double storySize = 70;
    double containerWidth = 80;
    double fontSize = 12;
    double spacing = 8;
    
    if (screenWidth < 600) { // Small screens
      storySize = 60;
      containerWidth = 70;
      fontSize = 11;
      spacing = 6;
    } else if (screenWidth < 1200) { // Medium screens
      storySize = 65;
      containerWidth = 75;
      fontSize = 12;
      spacing = 7;
    }
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: containerWidth,
        margin: EdgeInsets.only(right: screenWidth < 600 ? 8 : 12),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Prevent overflow
          children: [
            // Story Circle with Three-Dot Menu
            Stack(
              children: [
                Container(
                  width: storySize,
                  height: storySize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Only show story circle gradient when there's actually a story
                    gradient: (storyImage != null && storyImage!.isNotEmpty && storyImage != 'null')
                        ? (isViewed
                            ? null
                            : const LinearGradient(
                                colors: AppTheme.primaryGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ))
                        : null,
                    color: (storyImage != null && storyImage!.isNotEmpty && storyImage != 'null')
                        ? (isViewed ? Colors.grey.withOpacity(0.3) : null)
                        : null,
                  ),
                  child: Container(
                    margin: EdgeInsets.all(screenWidth < 600 ? 2 : 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: _buildStoryContent(context),
                  ),
                ),
                
                // Video indicator overlay - only show when there's a story
                if (storyType?.toLowerCase() == 'video' && 
                    storyImage != null && storyImage!.isNotEmpty && storyImage != 'null')
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
            
            SizedBox(height: spacing),
            
            // User Name - Use Flexible to prevent overflow
            Flexible(
              child: Text(
                userName,
                style: TextStyle(
                  fontSize: fontSize,
                  color: isViewed 
                      ? Colors.grey.withOpacity(0.7)
                      : AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
                maxLines: 2, // Allow 2 lines to prevent overflow
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent(BuildContext context) {
    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    double storySize = 70;
    if (screenWidth < 600) {
      storySize = 60;
    } else if (screenWidth < 1200) {
      storySize = 65;
    }
    
    // Always show user's DP as the main content
    Widget mainContent;
    
    if (userImage != null && userImage!.isNotEmpty && userImage != 'null') {
      // Show user's DP as the main content
      mainContent = ClipRRect(
        borderRadius: BorderRadius.circular(storySize / 2),
        child: _buildUserDP(userImage!),
      );
    } else {
      // Fallback to default content if no DP
      mainContent = _buildDefaultStoryContent();
    }
    
    // If we have a story, show it as an overlay with DP in background
    if (storyImage != null && storyImage!.isNotEmpty && storyImage != 'null') {
      return Stack(
        children: [
          // User's DP as background (smaller)
          Positioned(
            top: storySize * 0.15,
            left: storySize * 0.15,
            child: Container(
              width: storySize * 0.7,
              height: storySize * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(storySize * 0.35),
                child: userImage != null && userImage!.isNotEmpty && userImage != 'null'
                    ? _buildUserDP(userImage!)
                    : _buildDefaultStoryContent(),
              ),
            ),
          ),
          // Story image as main content
          ClipRRect(
            borderRadius: BorderRadius.circular(storySize / 2),
            child: _buildStoryMedia(storyImage!, storyType),
          ),
        ],
      );
    }
    
    // If no story, just show DP without any overlay
    return mainContent;
  }

  Widget _buildUserDP(String dpUrl) {
    return CachedNetworkImage(
      imageUrl: dpUrl,
      fit: BoxFit.cover,
      httpHeaders: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      },
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) {
        print('StoryWidget: Error loading user DP: $error for URL: $dpUrl');
        return _buildDefaultStoryContent();
      },
      memCacheWidth: 200,
      memCacheHeight: 200,
    );
  }

  Widget _buildStoryMedia(String mediaUrl, String? mediaType) {
    print('StoryWidget: Building media for URL: $mediaUrl, type: $mediaType');
    
    // Check if this is a video story
    if (mediaType?.toLowerCase() == 'video') {
      return _buildVideoThumbnail(mediaUrl);
    } else {
      return _buildStoryImage(mediaUrl);
    }
  }

  Widget _buildVideoThumbnail(String videoUrl) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.8),
            const Color(0xFF8B5CF6).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.play_circle_outline,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  Widget _buildStoryImage(String imageUrl) {
    print('StoryWidget: Building image for URL: $imageUrl');
    
    // Use CachedNetworkImage for better performance
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      httpHeaders: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      },
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) {
        print('StoryWidget: CachedNetworkImage error: $error for URL: $imageUrl');
        return _buildDefaultStoryContent();
      },
      memCacheWidth: 200, // Optimize memory usage
      memCacheHeight: 200,
    );
  }
  
  Widget _buildAlternativeImage(String imageUrl) {
    // Try loading with custom HTTP client as fallback
    return FutureBuilder<Uint8List?>(
      future: _loadImageBytes(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          );
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('StoryWidget: Error displaying alternative image: $error');
              return _buildDefaultStoryContent();
            },
          );
        }
        
        // If all methods fail, show default content
        return _buildDefaultStoryContent();
      },
    );
  }
  
  /// Load image bytes with custom HTTP client to handle SSL issues
  Future<Uint8List?> _loadImageBytes(String imageUrl) async {
    try {
      final response = await CustomHttpClient.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      print('StoryWidget: Error loading image bytes: $e');
    }
    return null;
  }

  Widget _buildDefaultStoryContent() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.person,
        color: AppTheme.primaryColor,
        size: 30,
      ),
    );
  }
  

}

class StoryViewer extends StatefulWidget {
  final List<StoryWidget> stories;
  final int initialIndex;

  const StoryViewer({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Story Content
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.stories.length,
            itemBuilder: (context, index) {
              return _buildStoryPage(widget.stories[index]);
            },
          ),
          
          // Top Bar
          _buildTopBar(),
          
          // Bottom Controls
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildStoryPage(StoryWidget story) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.8),
            const Color(0xFF8B5CF6).withOpacity(0.8),
            const Color(0xFFEC4899).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Story Image or Default Content
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
                                child: story.storyImage != null
                  ? ClipOval(
                      child: Image.network(
                        story.storyImage!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const CircularProgressIndicator();
                        },
                        errorBuilder: (context, error, stackTrace) => _buildDefaultStoryContent(),
                      ),
                    )
                  : _buildDefaultStoryContent(),
            ),
            
            const SizedBox(height: 24),
            
            // Story Text
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: Text(
                'Spiritual journey of ${story.userName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultStoryContent() {
    return const Icon(
      Icons.self_improvement,
      color: Colors.white,
      size: 80,
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Close Button
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            
            const Spacer(),
            
            // Story Progress
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentIndex + 1} / ${widget.stories.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Previous Button
              if (_currentIndex > 0)
                GestureDetector(
                  onTap: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              
              const Spacer(),
              
              // Next Button
              if (_currentIndex < widget.stories.length - 1)
                GestureDetector(
                  onTap: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 