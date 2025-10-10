import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/story_model.dart';
// Removed Cloudinary dependency
import '../services/story_service.dart';
import '../services/baba_page_story_service.dart'; // Added for Babaji story deletion
import '../providers/auth_provider.dart';
import '../widgets/video_player_widget.dart';

class StoryViewerScreen extends StatefulWidget {
  final Story story;
  final List<Story> allStories;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.story,
    required this.allStories,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  late int _currentIndex;
  late PageController _pageController;
  bool _isFullScreen = false;

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
            itemCount: widget.allStories.length,
            itemBuilder: (context, index) {
              final story = widget.allStories[index];
              return _buildStoryPage(story);
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

  Widget _buildStoryPage(Story story) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isFullScreen = !_isFullScreen;
        });
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Story Image/Video
            if (story.media.isNotEmpty && story.media != 'null')
              _buildStoryMedia(story)
            else
              _buildDefaultStoryContent(),
            
            // Story Info Overlay
            if (!_isFullScreen) _buildStoryInfoOverlay(story),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryMedia(Story story) {
    if (story.type.toLowerCase() == 'video') {
      // For video stories, show actual video player
      return _buildVideoPlayer(story);
    } else {
      // For image stories, use Image.network
      return Image.network(
        story.media,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.black,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 80,
                ),
                SizedBox(height: 16),
                Text(
                  'Failed to load image',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildDefaultStoryContent() {
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
            Icon(
              Icons.self_improvement,
              color: Colors.white,
              size: 80,
            ),
            SizedBox(height: 24),
            Text(
              'Spiritual Journey',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryInfoOverlay(Story story) {
    return Positioned(
      bottom: 100,
      left: 20,
      right: 20,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  child: story.authorAvatar != null
                      ? ClipOval(
                          child: Image.network(
                            story.authorAvatar!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.person,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: Color(0xFF6366F1),
                        ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.authorName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '@${story.authorUsername}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (story.type.isNotEmpty) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF6366F1).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  story.type.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            
            // Story Caption/Description
            if (story.caption != null && story.caption!.isNotEmpty) ...[
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  story.caption!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(16),
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
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            
            Spacer(),
            
            // Story Progress
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentIndex + 1} / ${widget.allStories.length}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Three-dot menu for story options (only for user's own stories)
            if (_isCurrentUserStory())
              GestureDetector(
                onTap: () => _showStoryOptions(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 24,
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
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Previous Button
              if (_currentIndex > 0)
                GestureDetector(
                  onTap: () {
                    _pageController.previousPage(
                      duration: Duration(milliseconds: 300),
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
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              
              Spacer(),
              
              // Next Button
              if (_currentIndex < widget.allStories.length - 1)
                GestureDetector(
                  onTap: () {
                    _pageController.nextPage(
                      duration: Duration(milliseconds: 300),
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
                    child: Icon(
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
  
  /// Check if the current story belongs to the current user
  bool _isCurrentUserStory() {
    // Get the current story and check if it belongs to the current user
    final currentStory = widget.allStories[_currentIndex];
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.userProfile;
    
    // Only show delete option if current user is the owner of the story
    return currentUser != null && currentUser.id == currentStory.authorId;
  }
  
  /// Show story options menu (delete, etc.)
  void _showStoryOptions(BuildContext context) {
    // Check if current user is the owner of the story
    final currentStory = widget.allStories[_currentIndex];
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.userProfile;
    final isOwner = currentUser != null && currentUser.id == currentStory.authorId;
    
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
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Delete option - only show for story owner
            if (isOwner) ...[
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete Story',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context);
                },
              ),
              
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Show delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Story'),
        content: const Text('Are you sure you want to delete this story? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCurrentStory();
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
  
  /// Delete the current story
  Future<void> _deleteCurrentStory() async {
    try {
      final currentStory = widget.allStories[_currentIndex];
      
      // Get auth token and current user from provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;
      final currentUser = authProvider.userProfile;
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to delete stories'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Check if current user is the owner of the story
      if (currentUser == null || currentUser.id != currentStory.authorId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can only delete your own stories'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deleting story...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      bool deleteSuccess = false;
      String deleteMessage = '';
      
      // Check if this is a Babaji story (author name is "Baba Ji")
      if (currentStory.authorName == 'Baba Ji') {
        print('StoryViewerScreen: Deleting Babaji story ${currentStory.id}');
        
        // Delete using BabaPageStoryService
        deleteSuccess = await BabaPageStoryService.deleteBabaPageStory(
          storyId: currentStory.id,
          babaPageId: currentStory.authorId, // For Babaji stories, authorId is the babaPageId
          token: token,
        );
        
        deleteMessage = deleteSuccess ? 'Babaji story deleted successfully' : 'Failed to delete Babaji story';
        print('StoryViewerScreen: Babaji story delete result: $deleteSuccess');
        
      } else {
        print('StoryViewerScreen: Deleting regular user story ${currentStory.id}');
        
        // Delete using regular StoryService
        final result = await StoryService.deleteStory(
          currentStory.id,
          currentStory.authorId,
          token,
        );
        
        deleteSuccess = result['success'] == true;
        deleteMessage = result['message'] ?? (deleteSuccess ? 'Story deleted successfully' : 'Failed to delete story');
        print('StoryViewerScreen: Regular story delete result: $deleteSuccess');
      }
      
      if (deleteSuccess) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(deleteMessage),
            backgroundColor: Colors.green,
          ),
        );
        
        // Close the story viewer
        Navigator.of(context).pop();
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(deleteMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
      
    } catch (e) {
      print('Error deleting story: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting story: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildVideoPlayer(Story story) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: VideoPlayerWidget(
        videoUrl: story.media,
        autoPlay: true,
        looping: true,
        muted: false, // Allow sound for stories
      ),
    );
  }
}
