import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/story_model.dart';
import '../models/highlight_model.dart';
// Removed Cloudinary dependency
import '../services/story_service.dart';
import '../services/highlight_service.dart';
import '../services/baba_page_story_service.dart'; // Added for Babaji story deletion
import '../providers/auth_provider.dart';
import '../widgets/video_player_widget.dart';
import 'create_highlight_screen.dart';
import 'user_profile_screen.dart';

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

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late PageController _pageController;
  bool _isFullScreen = false;
  late AnimationController _progressController;
  final Set<String> _viewedStoryIds = <String>{};
  int _lastIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _lastIndex = _currentIndex;
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _handleStoryCompleted();
        }
      });

    _startTimerForCurrentStory();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
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
                // Mark previous story as viewed when leaving it
                final prevStory = widget.allStories[_currentIndex];
                _viewedStoryIds.add(prevStory.id);
                _lastIndex = _currentIndex;
                _currentIndex = index;
              });
              _startTimerForCurrentStory();
            },
            itemCount: widget.allStories.length,
            itemBuilder: (context, index) {
              final story = widget.allStories[index];
              return _buildStoryPage(story);
            },
          ),
          
          // Progress Bar - Always show for navigation
          Positioned(
            top: 8,
            left: 12,
            right: 12,
            child: SafeArea(
              bottom: false,
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, _) {
                  final indices = _getCurrentAuthorStoryIndices();
                  final currentWithin = indices.indexOf(_currentIndex);
                  return Row(
                    children: List.generate(indices.length, (i) {
                      final isCurrent = i == currentWithin;
                      final storyIndex = indices[i];
                      final isViewed = _viewedStoryIds.contains(widget.allStories[storyIndex].id);
                      final value = i < currentWithin
                          ? 1.0
                          : isCurrent
                              ? _progressController.value
                              : 0.0;
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 2),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: value,
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isCurrent
                                    ? const Color(0xFFFFD700) // gold for current
                                    : isViewed
                                        ? Colors.white // white for viewed
                                        : const Color(0xFFFFD700), // gold for new
                              ),
                              minHeight: 3,
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ),
          
          // Top Bar - Always show for navigation
          _buildTopBar(),
          
          // Bottom Controls - Only show for image stories
          if (widget.allStories.isNotEmpty && 
              widget.allStories[_currentIndex].type.toLowerCase() != 'video')
            _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildStoryPage(Story story) {
    return GestureDetector(
      onTapUp: (details) {
        print('StoryViewerScreen: Tap detected at position: ${details.localPosition.dx}');
        final screenWidth = MediaQuery.of(context).size.width;
        final dx = details.localPosition.dx;
        
        if (dx < screenWidth * 0.33) {
          print('StoryViewerScreen: Left tap - going to previous story');
          _goToPreviousInAuthor();
        } else if (dx > screenWidth * 0.66) {
          print('StoryViewerScreen: Right tap - going to next story');
          _goToNextInAuthor();
        } else {
          print('StoryViewerScreen: Center tap - no action');
        }
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
            
            // Story Info Overlay - Only show for image stories
            if (story.type.toLowerCase() != 'video' && !_isFullScreen) 
              _buildStoryInfoOverlay(story),
            
            // Invisible tap zones for navigation (only for video stories)
            if (story.type.toLowerCase() == 'video') ...[
              // Left tap zone
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: MediaQuery.of(context).size.width * 0.33,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
              // Right tap zone
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: MediaQuery.of(context).size.width * 0.33,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStoryMedia(Story story) {
    print('StoryViewerScreen: Building story media for story: ${story.id}');
    print('StoryViewerScreen: Media URL: ${story.media}');
    print('StoryViewerScreen: Story type: ${story.type}');
    
    if (story.type.toLowerCase() == 'video') {
      // For video stories, show actual video player
      print('StoryViewerScreen: Creating video player for video story');
      return _buildVideoPlayer(story);
    } else {
      // For image stories, use Image.network
      print('StoryViewerScreen: Creating image widget for image story');
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
            // Removed duplicate author info row (now shown in top bar)
            Row(
              children: [
                // Author details removed to avoid duplication
              ],
            ),
            // Removed media type pill (e.g., IMAGE/VIDEO)
            
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
            
            const SizedBox(width: 12),
            // Current story author info
            Builder(
              builder: (context) {
                final story = widget.allStories[_currentIndex];
                return Expanded(
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _navigateToUserProfile(story),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: story.authorAvatar != null
                              ? ClipOval(
                                  child: Image.network(
                                    story.authorAvatar!,
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      Icons.person,
                                      color: Colors.grey[600],
                                      size: 18,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  color: const Color(0xFF6366F1),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _navigateToUserProfile(story),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                story.authorName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '@${story.authorUsername}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _relativeTime(story.createdAt),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            // Story Progress
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Builder(
                builder: (context) {
                  final indices = _getCurrentAuthorStoryIndices();
                  final currentWithin = indices.indexOf(_currentIndex);
                  return Text(
                    '${currentWithin + 1} / ${indices.length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
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
                    _startTimerForCurrentStory();
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
                    _startTimerForCurrentStory();
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
            
            // Add to Highlight option - only show for story owner
            if (isOwner) ...[
              ListTile(
                leading: const Icon(Icons.collections_bookmark, color: Colors.blue),
                title: const Text(
                  'Add to Highlight',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showAddToHighlightDialog(context);
                },
              ),
              
              const SizedBox(height: 8),
            ],
            
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
  
  /// Show add to highlight dialog
  void _showAddToHighlightDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddToHighlightDialog(
        story: widget.allStories[_currentIndex],
        token: Provider.of<AuthProvider>(context, listen: false).authToken ?? '',
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
    print('StoryViewerScreen: Building video player for story: ${story.id}');
    print('StoryViewerScreen: Video URL: ${story.media}');
    print('StoryViewerScreen: Story type: ${story.type}');
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: VideoPlayerWidget(
        videoUrl: story.media,
        autoPlay: true,
        looping: false, // Don't loop stories - play once
        muted: false, // Allow sound for stories
        showControls: false, // Remove all video controls
      ),
    );
  }
  
  void _startTimerForCurrentStory() {
    _progressController.stop();
    _progressController.reset();
    _progressController.forward();
  }

  void _handleStoryCompleted() {
    // Mark current as viewed when time completes
    final currentStory = widget.allStories[_currentIndex];
    _viewedStoryIds.add(currentStory.id);
    final indices = _getCurrentAuthorStoryIndices();
    final currentWithin = indices.indexOf(_currentIndex);
    if (currentWithin < indices.length - 1) {
      // Next story of same author
      final nextIndex = indices[currentWithin + 1];
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    } else {
      // Move to first story of next author, or close if none
      final nextAuthorFirstIndex = _getFirstIndexOfNextAuthor();
      if (nextAuthorFirstIndex != null) {
        _pageController.animateToPage(
          nextAuthorFirstIndex,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      } else {
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  String _relativeTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    final weeks = (diff.inDays / 7).floor();
    if (weeks < 4) return '${weeks}w';
    final months = (diff.inDays / 30).floor();
    if (months < 12) return '${months}mo';
    final years = (diff.inDays / 365).floor();
    return '${years}y';
  }

  // Grouping & ordering utilities
  List<int> _getAuthorStoryIndicesSorted(String authorId) {
    if (widget.allStories.isEmpty) return const [];
    final pairs = <MapEntry<int, DateTime>>[];
    for (var i = 0; i < widget.allStories.length; i++) {
      final s = widget.allStories[i];
      if (s.authorId == authorId) {
        pairs.add(MapEntry(i, s.createdAt));
      }
    }
    pairs.sort((a, b) => a.value.compareTo(b.value)); // oldest first
    return pairs.map((e) => e.key).toList(growable: false);
  }

  List<int> _getCurrentAuthorStoryIndices() {
    if (widget.allStories.isEmpty) return const [];
    final currentAuthorId = widget.allStories[_currentIndex].authorId;
    return _getAuthorStoryIndicesSorted(currentAuthorId);
  }

  int? _getFirstIndexOfNextAuthor() {
    if (widget.allStories.isEmpty) return null;
    final currentAuthorId = widget.allStories[_currentIndex].authorId;
    // Find next author's id scanning forward
    String? nextAuthorId;
    for (var i = _currentIndex + 1; i < widget.allStories.length; i++) {
      final aId = widget.allStories[i].authorId;
      if (aId != currentAuthorId) {
        nextAuthorId = aId;
        break;
      }
    }
    if (nextAuthorId == null) return null;
    final indices = _getAuthorStoryIndicesSorted(nextAuthorId);
    return indices.isEmpty ? null : indices.first;
  }

  int? _getLastIndexOfPreviousAuthor() {
    if (widget.allStories.isEmpty) return null;
    final currentAuthorId = widget.allStories[_currentIndex].authorId;
    // Find previous author's id scanning backward
    String? prevAuthorId;
    for (var i = _currentIndex - 1; i >= 0; i--) {
      final aId = widget.allStories[i].authorId;
      if (aId != currentAuthorId) {
        prevAuthorId = aId;
        break;
      }
    }
    if (prevAuthorId == null) return null;
    final indices = _getAuthorStoryIndicesSorted(prevAuthorId);
    return indices.isEmpty ? null : indices.last;
  }

  void _goToNextInAuthor() {
    final indices = _getCurrentAuthorStoryIndices();
    final pos = indices.indexOf(_currentIndex);
    if (pos < 0) return;
    if (pos < indices.length - 1) {
      _pageController.animateToPage(
        indices[pos + 1],
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    } else {
      final nextFirst = _getFirstIndexOfNextAuthor();
      if (nextFirst != null) {
        _pageController.animateToPage(
          nextFirst,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _goToPreviousInAuthor() {
    final indices = _getCurrentAuthorStoryIndices();
    final pos = indices.indexOf(_currentIndex);
    if (pos < 0) return;
    if (pos > 0) {
      _pageController.animateToPage(
        indices[pos - 1],
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    } else {
      final prevLast = _getLastIndexOfPreviousAuthor();
      if (prevLast != null) {
        _pageController.animateToPage(
          prevLast,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _navigateToUserProfile(Story story) {
    print('Navigating to profile for user: ${story.authorId}, username: ${story.authorUsername}');
    
    try {
      // Navigate to regular user profile screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(
            userId: story.authorId,
            username: story.authorUsername,
            fullName: story.authorName,
            avatar: story.authorAvatar ?? '',
            bio: '', // Default empty bio
            followersCount: 0, // Default value
            followingCount: 0, // Default value
            postsCount: 0, // Default value
            isPrivate: false, // Default to public, will be updated when user profile is loaded
          ),
        ),
      );
    } catch (e) {
      print('Error navigating to profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Dialog for adding a story to highlights
class AddToHighlightDialog extends StatefulWidget {
  final Story story;
  final String token;

  const AddToHighlightDialog({
    Key? key,
    required this.story,
    required this.token,
  }) : super(key: key);

  @override
  State<AddToHighlightDialog> createState() => _AddToHighlightDialogState();
}

class _AddToHighlightDialogState extends State<AddToHighlightDialog> {
  List<Highlight> _highlights = [];
  bool _isLoading = true;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadHighlights();
  }

  Future<void> _loadHighlights() async {
    try {
      print('AddToHighlightDialog: Loading highlights...');
      final response = await HighlightService.getHighlights(
        token: widget.token,
        page: 1,
        limit: 100,
      );

      print('AddToHighlightDialog: Highlights response - success: ${response.success}, count: ${response.highlights.length}');
      
      if (response.success) {
        setState(() {
          _highlights = response.highlights;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        print('AddToHighlightDialog: Failed to load highlights: ${response.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load highlights: ${response.message}')),
        );
      }
    } catch (e) {
      print('AddToHighlightDialog: Error loading highlights: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading highlights: $e')),
      );
    }
  }

  Future<void> _addToHighlight(Highlight highlight) async {
    setState(() {
      _isAdding = true;
    });

    try {
      final response = await HighlightService.addStoryToHighlight(
        highlightId: highlight.id,
        storyId: widget.story.id,
        token: widget.token,
      );

      if (response.success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Story added to "${highlight.name}"')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add story: ${response.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding story: $e')),
      );
    } finally {
      setState(() {
        _isAdding = false;
      });
    }
  }

  Future<void> _createNewHighlight() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateHighlightScreen(
          preselectedStoryId: widget.story.id,
        ),
      ),
    );

    if (result == true) {
      await _loadHighlights();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add to Highlight'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _highlights.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.collections_bookmark_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text('No highlights yet'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _createNewHighlight,
                          child: const Text('Create Highlight'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _highlights.length,
                    itemBuilder: (context, index) {
                      final highlight = _highlights[index];
                      final isStoryInHighlight = highlight.stories.any(
                        (story) => story.id == widget.story.id,
                      );

                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[200],
                          ),
                          child: highlight.stories.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    highlight.stories.first.media,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.collections_bookmark);
                                    },
                                  ),
                                )
                              : const Icon(Icons.collections_bookmark),
                        ),
                        title: Text(highlight.name),
                        subtitle: Text('${highlight.storiesCount} stories'),
                        trailing: isStoryInHighlight
                            ? const Icon(Icons.check, color: Colors.green)
                            : _isAdding
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.add),
                        onTap: isStoryInHighlight
                            ? null
                            : () => _addToHighlight(highlight),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _createNewHighlight,
          child: const Text('Create New'),
        ),
      ],
    );
  }
}


