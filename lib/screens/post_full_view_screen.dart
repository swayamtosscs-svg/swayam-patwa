import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/post_model.dart';

class PostFullViewScreen extends StatefulWidget {
  final Post post;

  const PostFullViewScreen({
    super.key,
    required this.post,
  });

  @override
  State<PostFullViewScreen> createState() => _PostFullViewScreenState();
}

class _PostFullViewScreenState extends State<PostFullViewScreen> {
  bool _isLiked = false;
  bool _isSaved = false;
  bool _isFavourite = false;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _isSaved = widget.post.isSaved;
    // Initialize video after a short delay to ensure UI is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeVideo();
    });
  }

  @override
  void dispose() {
    // Remove listener before disposing
    _videoController?.removeListener(_videoListener);
    // Dispose video controller properly
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    // Check if this is a video/reel post
    if (widget.post.isReel && widget.post.videoUrl != null && widget.post.videoUrl!.isNotEmpty) {
      print('PostFullViewScreen: Initializing video: ${widget.post.videoUrl}');
      try {
        _videoController = VideoPlayerController.network(
          widget.post.videoUrl!,
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: true,
            allowBackgroundPlayback: false,
          ),
        );
        
        await _videoController!.initialize();
        await _videoController!.setLooping(true);
        
        // Add listener for video state changes
        _videoController!.addListener(_videoListener);
        
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
        }
        
        // Auto-play the video with a delay to ensure UI is ready
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted && _videoController != null) {
          await _videoController!.play();
          print('PostFullViewScreen: Video started playing');
          
          // Retry if video doesn't start playing
          await Future.delayed(const Duration(milliseconds: 1000));
          if (mounted && _videoController != null && !_videoController!.value.isPlaying) {
            print('PostFullViewScreen: Retrying video play');
            await _videoController!.play();
          }
        }
      } catch (e) {
        print('PostFullViewScreen: Error initializing video: $e');
        if (mounted) {
          setState(() {
            _isVideoInitialized = false;
          });
        }
      }
    } else {
      print('PostFullViewScreen: Not a video post or no video URL');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(),
            
            // Post Content
            Expanded(
              child: _buildPostContent(),
            ),
            
            // Bottom Actions
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  void _videoListener() {
    if (mounted && _videoController != null) {
      setState(() {
        _isPlaying = _videoController!.value.isPlaying;
      });
      
      // If video stopped unexpectedly, restart it
      if (!_videoController!.value.isPlaying && _videoController!.value.position.inMilliseconds > 0) {
        print('PostFullViewScreen: Video stopped unexpectedly, restarting...');
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _videoController != null) {
            _videoController!.play();
          }
        });
      }
    }
  }

  Widget _buildMediaContent() {
    // Check if this is a video/reel post
    if (widget.post.isReel && widget.post.videoUrl != null && widget.post.videoUrl!.isNotEmpty) {
      print('PostFullViewScreen: Building video content, initialized: $_isVideoInitialized');
      
      if (_isVideoInitialized && _videoController != null) {
        return Stack(
          fit: StackFit.expand,
          children: [
            VideoPlayer(_videoController!),
            // Play/Pause overlay - only show when not playing
            if (!_isPlaying)
              Center(
                child: GestureDetector(
                  onTap: () {
                    print('PostFullViewScreen: Play button tapped');
                    if (_videoController!.value.isPlaying) {
                      _videoController!.pause();
                    } else {
                      _videoController!.play();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
          ],
        );
      } else {
        // Show loading or thumbnail while video initializes
        return Container(
          color: Colors.black,
          child: Stack(
            children: [
              // Show thumbnail if available
              if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty)
                Image.network(
                  widget.post.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.black,
                      child: const Center(
                        child: Icon(
                          Icons.video_library,
                          size: 64,
                          color: Colors.white54,
                        ),
                      ),
                    );
                  },
                ),
              // Loading indicator
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      }
    } else {
      // Handle image posts
      return Image.network(
        widget.post.imageUrl ?? 'https://via.placeholder.com/400x600/6366F1/FFFFFF?text=Post',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: const Color(0xFF1A1A1A),
            child: const Center(
              child: Icon(
                Icons.image_not_supported,
                size: 64,
                color: Colors.white54,
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // User Info
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                  child: Text(
                    widget.post.userAvatar,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.post.username,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      _getTimeAgo(widget.post.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Three Dots Menu
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
            onSelected: (value) {
              _handleMenuSelection(value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'save',
                child: Row(
                  children: [
                    Icon(
                      _isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: _isSaved ? const Color(0xFF6366F1) : const Color(0xFF666666),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isSaved ? 'Saved' : 'Save',
                      style: TextStyle(
                        color: _isSaved ? const Color(0xFF6366F1) : const Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'favourite',
                child: Row(
                  children: [
                    Icon(
                      _isFavourite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavourite ? Colors.red : const Color(0xFF666666),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isFavourite ? 'Favourited' : 'Add to Favourite',
                      style: TextStyle(
                        color: _isFavourite ? Colors.red : const Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'hide',
                child: Row(
                  children: [
                    Icon(Icons.visibility_off, color: Color(0xFF666666), size: 20),
                    SizedBox(width: 8),
                    Text('Hide'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report, color: Color(0xFF666666), size: 20),
                    SizedBox(width: 8),
                    Text('Report'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF666666), size: 20),
                    SizedBox(width: 8),
                    Text('About this Account'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image/Video
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.6,
            child: ClipRRect(
              child: _buildMediaContent(),
            ),
          ),
          
          // Caption
          if (widget.post.caption != null && widget.post.caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.post.caption!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  height: 1.4,
                ),
              ),
            ),
          
          // Hashtags
          if (widget.post.hashtags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: widget.post.hashtags.map((hashtag) {
                  return Text(
                    '#$hashtag',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6366F1),
                      fontFamily: 'Poppins',
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Like Button
          GestureDetector(
            onTap: () {
              setState(() {
                _isLiked = !_isLiked;
              });
            },
            child: Row(
              children: [
                Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  'Like',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _isLiked ? Colors.red : Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 24),
          
          // Comment Button
          GestureDetector(
            onTap: () {
              // Handle comment
            },
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 24),
          
          // Share Button
          GestureDetector(
            onTap: () {
              // Handle share
            },
            child: Row(
              children: [
                const Icon(
                  Icons.share_outlined,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Share',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Post Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_isLiked ? 1 : 0} likes',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
              const Text(
                '0 comments',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'save':
        setState(() {
          _isSaved = !_isSaved;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isSaved ? 'Post saved!' : 'Post removed from saved'),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'favourite':
        setState(() {
          _isFavourite = !_isFavourite;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavourite ? 'Added to favourites!' : 'Removed from favourites'),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'hide':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post hidden'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case 'report':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post reported'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case 'about':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('About this account'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
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
}
