import 'dart:typed_data';
import 'package:flutter/material.dart';

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
                    gradient: isViewed
                        ? null
                        : const LinearGradient(
                            colors: AppTheme.primaryGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: isViewed ? Colors.grey.withOpacity(0.3) : null,
                  ),
                  child: Container(
                    margin: EdgeInsets.all(screenWidth < 600 ? 2 : 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: storyImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(storySize / 2),
                            child: _buildStoryImage(storyImage!),
                          )
                        : _buildDefaultStoryContent(),
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

  Widget _buildStoryImage(String imageUrl) {
    print('StoryWidget: Building image for URL: $imageUrl');
    
    // Use Image.network for all URLs
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
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
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('StoryWidget: Image.network error: $error for URL: $imageUrl');
        // Try alternative loading method
        return _buildAlternativeImage(imageUrl);
      },
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
            const Color(0xFF6366F1).withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.self_improvement,
        color: Color(0xFF6366F1),
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