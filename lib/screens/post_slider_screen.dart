import 'package:flutter/material.dart';
import '../models/post_model.dart';
import 'post_full_view_screen.dart';

class PostSliderScreen extends StatefulWidget {
  final List<Post> posts;
  final int initialIndex;

  const PostSliderScreen({
    super.key,
    required this.posts,
    required this.initialIndex,
  });

  @override
  State<PostSliderScreen> createState() => _PostSliderScreenState();
}

class _PostSliderScreenState extends State<PostSliderScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    // Show swipe hint after a short delay
    if (widget.posts.length > 1) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _showSwipeHint();
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateToPost(int index) {
    if (index >= 0 && index < widget.posts.length) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showSwipeHint() {
    if (widget.posts.length > 1 && _currentIndex == 0) {
      // Show a subtle hint for first-time users
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Swipe left or right to navigate between posts'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.black87,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            _buildTopBar(),
            
            // Post Content with PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: widget.posts.length,
                physics: const BouncingScrollPhysics(), // Add bounce effect
                itemBuilder: (context, index) {
                  final post = widget.posts[index];
                  return PostFullViewScreen(
                    post: post,
                    showNavigationControls: true, // Show controls so user can like/comment
                  );
                },
              ),
            ),
            
            // Bottom Navigation Indicators
            _buildBottomIndicators(),
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
          
          const Spacer(),
          
          // Post Counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_currentIndex + 1} / ${widget.posts.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (widget.posts.length > 1) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.swipe,
                    color: Colors.white70,
                    size: 16,
                  ),
                ],
              ],
            ),
          ),
          
          const Spacer(),
          
        ],
      ),
    );
  }

  Widget _buildBottomIndicators() {
    return const SizedBox.shrink();
  }
}
