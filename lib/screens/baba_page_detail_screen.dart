import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/baba_page_model.dart';
import '../models/baba_page_post_model.dart';
import '../services/baba_page_post_service.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import 'baba_page_post_creation_screen.dart';
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
  bool _isLoadingPosts = false;
  String? _postsErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadPosts();
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
        babaPageId: widget.babaPage.id,
        token: token,
      );

      if (response.success) {
        setState(() {
          _posts = response.posts;
          _isLoadingPosts = false;
        });
      } else {
        setState(() {
          _postsErrorMessage = response.message;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      setState(() {
        _postsErrorMessage = 'Error loading posts: $e';
        _isLoadingPosts = false;
      });
    }
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
                widget.babaPage.name,
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
                    if (widget.babaPage.coverImage.isNotEmpty)
                      Positioned.fill(
                        child: Image.network(
                          widget.babaPage.coverImage,
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
                    // Avatar
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            child: widget.babaPage.avatar.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      widget.babaPage.avatar,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Icon(
                                        Icons.self_improvement,
                                        size: 40,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.self_improvement,
                                    size: 40,
                                    color: AppTheme.primaryColor,
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                            Text(
                              widget.babaPage.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
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
                                Text(
                                  widget.babaPage.location,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                      color: _getReligionColor(widget.babaPage.religion).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getReligionColor(widget.babaPage.religion).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      widget.babaPage.religion,
                      style: TextStyle(
                        color: _getReligionColor(widget.babaPage.religion),
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
                    widget.babaPage.description,
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
                  if (widget.babaPage.website.isNotEmpty) _buildWebsiteSection(),
                  const SizedBox(height: 24),
                  // Created Date
                  _buildInfoSection(
                    'Created',
                    _formatDate(widget.babaPage.createdAt),
                    Icons.calendar_today,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoSection(
                    'Last Updated',
                    _formatDate(widget.babaPage.updatedAt),
                    Icons.update,
                  ),
                ],
              ),
            ),
          ),
          // Posts Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Posts',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          print('Create Post button pressed');
                          // Show immediate feedback
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Opening post creation...'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BabaPagePostCreationScreen(
                                babaPage: widget.babaPage,
                              ),
                            ),
                          ).then((_) {
                            print('Returned from post creation screen');
                            // Refresh posts when returning from creation screen
                            _loadPosts();
                          });
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
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 18, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Create Post',
                                style: TextStyle(
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
                  _buildPostsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: GestureDetector(
        onTap: () {
          print('Floating Action Button pressed');
          // Show immediate feedback
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Creating new post...'),
              duration: Duration(seconds: 1),
            ),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BabaPagePostCreationScreen(
                babaPage: widget.babaPage,
              ),
            ),
          ).then((_) {
            print('Returned from post creation screen via FAB');
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
                '${widget.babaPage.followersCount}',
                'Followers',
                AppTheme.primaryColor,
              ),
              _buildStatCard(
                Icons.grid_on,
                '${widget.babaPage.postsCount}',
                'Posts',
                Colors.green,
              ),
              _buildStatCard(
                Icons.play_circle_outline,
                '${widget.babaPage.videosCount}',
                'Videos',
                Colors.orange,
              ),
              _buildStatCard(
                Icons.auto_stories,
                '${widget.babaPage.storiesCount}',
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
            onTap: () => _launchWebsite(widget.babaPage.website),
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
                    widget.babaPage.website,
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
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
              _postsErrorMessage!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPosts,
              child: const Text('Retry'),
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
                        widget.babaPage.name,
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
                _buildPostStat(Icons.comment, '${post.commentsCount}'),
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
        babaPageId: widget.babaPage.id,
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

