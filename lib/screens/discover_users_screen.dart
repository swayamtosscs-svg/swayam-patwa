import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../screens/user_profile_screen.dart';

class DiscoverUsersScreen extends StatefulWidget {
  const DiscoverUsersScreen({super.key});

  @override
  State<DiscoverUsersScreen> createState() => _DiscoverUsersScreenState();
}

class _DiscoverUsersScreenState extends State<DiscoverUsersScreen> {
  List<Map<String, dynamic>> _usersWithPosts = [];
  bool _isLoading = false;
  Map<String, bool> _followingStatus = {};
  Map<String, bool> _isProcessingFollow = {};

  @override
  void initState() {
    super.initState();
    _loadUsersWithPosts();
    _checkFollowingStatus();
  }

  Future<void> _loadUsersWithPosts() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Sample users for demonstration
    final List<Map<String, dynamic>> sampleUsers = [
      {
        '_id': 'user1',
        'username': 'spiritual_guide',
        'fullName': 'Spiritual Guide',
        'bio': 'Sharing wisdom and spiritual insights',
        'avatar': '',
        'followersCount': 150,
        'followingCount': 45,
        'postsCount': 23,
        'isPrivate': false,
      },
      {
        '_id': 'user2',
        'username': 'meditation_master',
        'fullName': 'Meditation Master',
        'bio': 'Teaching meditation and mindfulness',
        'avatar': '',
        'followersCount': 89,
        'followingCount': 32,
        'postsCount': 18,
        'isPrivate': false,
      },
      {
        '_id': 'user3',
        'username': 'yoga_teacher',
        'fullName': 'Yoga Teacher',
        'bio': 'Yoga poses and spiritual practices',
        'avatar': '',
        'followersCount': 234,
        'followingCount': 67,
        'postsCount': 31,
        'isPrivate': false,
      },
      {
        '_id': 'user4',
        'username': 'wisdom_seeker',
        'fullName': 'Wisdom Seeker',
        'bio': 'Exploring ancient wisdom and modern spirituality',
        'avatar': '',
        'followersCount': 67,
        'followingCount': 23,
        'postsCount': 12,
        'isPrivate': false,
      },
    ];

    if (mounted) {
      setState(() {
        _usersWithPosts = sampleUsers;
        _isLoading = false;
      });
    }
  }

  // Check the real following status from API
  Future<void> _checkFollowingStatus() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;
      final currentUserId = authProvider.userProfile?.id;

      if (token == null || currentUserId == null) return;

      // For demo users, we'll simulate checking following status
      // In a real app, you would check each user's following status individually
      for (final user in _usersWithPosts) {
        final userId = user['_id'];
        if (userId != null) {
          // For demo purposes, randomly set some users as followed
          // In real implementation, check actual API status
          final isFollowing = _followingStatus[userId] ?? false;
          if (!isFollowing) {
            // Simulate checking from API - in real app, call checkRGramFollowStatus
            setState(() {
              _followingStatus[userId] = false; // Default to not following
            });
          }
        }
      }
    } catch (e) {
      print('Error checking following status: $e');
    }
  }

  Future<void> _toggleFollow(String userId, String username) async {
    if (_isProcessingFollow[userId] == true) return; // Prevent multiple clicks
    
    setState(() {
      _isProcessingFollow[userId] = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;
      final currentUserId = authProvider.userProfile?.id;

      if (token == null || currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to follow users'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final isCurrentlyFollowing = _followingStatus[userId] ?? false;
      
      if (isCurrentlyFollowing) {
        // Unfollow user
        final response = await ApiService.unfollowRGramUser(
          targetUserId: userId,
          token: token,
        );

        if (response['success'] == true) {
          setState(() {
            _followingStatus[userId] = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unfollowed $username'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to unfollow: ${response['message'] ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Follow user
        final response = await ApiService.followRGramUser(
          targetUserId: userId,
          token: token,
        );

        if (response['success'] == true) {
          setState(() {
            _followingStatus[userId] = true;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Started following $username'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to follow: ${response['message'] ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingFollow[userId] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text(
          'Discover Users',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6366F1),
        ),
      );
    }

    return Column(
      children: [
        // Demo notice
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: const Color(0xFF6366F1),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Real Follow/Unfollow: Tap Follow to start following users and see their posts in your feed!',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF6366F1),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Users list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _usersWithPosts.length,
            itemBuilder: (context, index) {
              final user = _usersWithPosts[index];
              return _buildUserCard(user);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final username = user['username'] ?? 'Unknown';
    final fullName = user['fullName'] ?? 'No Name';
    final bio = user['bio'] ?? '';
    final followersCount = user['followersCount'] ?? 0;
    final followingCount = user['followingCount'] ?? 0;
    final postsCount = user['postsCount'] ?? 0;
    final userId = user['_id'] ?? '';
    final isFollowing = _followingStatus[userId] ?? false;
    final isProcessing = _isProcessingFollow[userId] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                  child: _buildDefaultAvatar(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      if (username.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '@$username',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  width: 100,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: isProcessing ? null : () => _toggleFollow(userId, username),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing ? Colors.grey[200] : const Color(0xFF6366F1),
                      foregroundColor: isFollowing ? Colors.grey[700] : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            isFollowing ? 'Following' : 'Follow',
                            style: const TextStyle(fontSize: 12),
                          ),
                  ),
                ),
              ],
            ),
            
            if (bio.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                bio,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Posts', postsCount.toString(), Icons.photo_library),
                FutureBuilder<Map<String, int>>(
                  future: userId.isNotEmpty ? Provider.of<AuthProvider>(context, listen: false).getUserCounts(userId) : Future.value({'followers': 0, 'following': 0}),
                  builder: (context, snapshot) {
                    int realFollowersCount = followersCount;
                    int realFollowingCount = followingCount;
                    if (snapshot.hasData && userId.isNotEmpty) {
                      realFollowersCount = snapshot.data!['followers'] ?? followersCount;
                      realFollowingCount = snapshot.data!['following'] ?? followingCount;
                    }
                    return Row(
                      children: [
                        _buildStatItem('Followers', realFollowersCount.toString(), Icons.people),
                        const SizedBox(width: 16),
                        _buildStatItem('Following', realFollowingCount.toString(), Icons.person_add),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return const Icon(
      Icons.person,
      size: 30,
      color: Color(0xFF6366F1),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF6366F1), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
            fontFamily: 'Poppins',
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF999999),
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}
