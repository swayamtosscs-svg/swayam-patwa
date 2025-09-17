import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/baba_page_post_model.dart';
import '../services/baba_page_post_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/post_counter_widget.dart';
import 'package:provider/provider.dart';

class BabaJiPostsSliderScreen extends StatefulWidget {
  final String babaPageId;
  final String babaPageName;
  final int initialIndex;

  const BabaJiPostsSliderScreen({
    super.key,
    required this.babaPageId,
    required this.babaPageName,
    this.initialIndex = 0,
  });

  @override
  State<BabaJiPostsSliderScreen> createState() => _BabaJiPostsSliderScreenState();
}

class _BabaJiPostsSliderScreenState extends State<BabaJiPostsSliderScreen> {
  late PageController _pageController;
  List<BabaPagePost> _posts = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _loadPosts();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;
      
      if (token == null) return;

      final response = await BabaPagePostService.getBabaPagePosts(
        babaPageId: widget.babaPageId,
        token: token,
        page: 1,
        limit: 100, // Fetch all posts
      );

      if (response.success && mounted) {
        setState(() {
          _posts = response.posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading Baba Ji posts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
            
            // Posts Slider
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    )
                  : _posts.isEmpty
                      ? const Center(
                          child: Text(
                            'No posts found',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        )
                      : PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                          itemCount: _posts.length,
                          itemBuilder: (context, index) {
                            final post = _posts[index];
                            return _buildPostSlide(post, index);
                          },
                        ),
            ),
            
            // Bottom Indicator
            if (!_isLoading && _posts.isNotEmpty) _buildBottomIndicator(),
          ],
        ),
      ),
    );
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
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.babaPageName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!_isLoading && _posts.isNotEmpty)
                  Text(
                    '${_currentIndex + 1} of ${_posts.length}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          
          // Share Button
          GestureDetector(
            onTap: () {
              // TODO: Implement share functionality
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.share,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostSlide(BabaPagePost post, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Post Image(s)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildPostMedia(post),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Post Content
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post Text
                if (post.content.isNotEmpty)
                  Text(
                    post.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                
                const SizedBox(height: 12),
                
                // Post Stats
                Row(
                  children: [
                    _buildStat(Icons.favorite, '${post.likesCount}'),
                    const SizedBox(width: 20),
                    _buildStat(Icons.comment, '${post.commentsCount}'),
                    const SizedBox(width: 20),
                    _buildStat(Icons.share, '${post.sharesCount}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostMedia(BabaPagePost post) {
    if (post.media.isEmpty) {
      return Container(
        color: Colors.grey[800],
        child: const Center(
          child: Icon(
            Icons.image_not_supported,
            color: Colors.white,
            size: 64,
          ),
        ),
      );
    }

    if (post.media.length == 1) {
      // Single image
      return Image.network(
        post.media.first.url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[800],
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[800],
            child: const Center(
              child: Icon(
                Icons.image_not_supported,
                color: Colors.white,
                size: 64,
              ),
            ),
          );
        },
      );
    } else {
      // Multiple images - show in a grid
      return GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: post.media.length > 2 ? 2 : post.media.length,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: post.media.length,
        itemBuilder: (context, index) {
          return Image.network(
            post.media[index].url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[800],
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              );
            },
          );
        },
      );
    }
  }

  Widget _buildStat(IconData icon, String count) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.7),
          size: 20,
        ),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _posts.length,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == _currentIndex
                  ? Colors.white
                  : Colors.white.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }
}
