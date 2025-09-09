import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/user_profile_screen.dart';

class FollowersScreen extends StatefulWidget {
  final String? userId; // Optional userId, if null use current user
  
  const FollowersScreen({super.key, this.userId});

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  List<Map<String, dynamic>> _followers = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      List<Map<String, dynamic>> followers;
      if (widget.userId != null) {
        // Fetch followers for a specific user
        followers = await authProvider.getFollowersForUser(widget.userId!);
      } else {
        // Fetch followers for current user
        followers = await authProvider.getFollowers();
      }
      
      if (mounted) {
        setState(() {
          _followers = followers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load followers: $e';
          _isLoading = false;
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
          'Followers',
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
        actions: [
          IconButton(
            onPressed: _loadFollowers,
            icon: const Icon(Icons.refresh, color: Color(0xFF6366F1)),
          ),
        ],
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

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF999999),
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFollowers,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_followers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'No followers yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'When other users follow you, they\'ll appear here',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF999999),
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFollowers,
      color: const Color(0xFF6366F1),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _followers.length,
        itemBuilder: (context, index) {
          final userData = _followers[index];
          return _buildUserCard(userData);
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> userData) {
    final username = userData['username'] ?? 'Unknown';
    final fullName = userData['fullName'] ?? 'No Name';
    final avatar = userData['avatar'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
          child: avatar.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    avatar,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
                  ),
                )
              : _buildDefaultAvatar(),
        ),
        title: Text(
          fullName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
            fontFamily: 'Poppins',
          ),
        ),
        subtitle: Text(
          '@$username',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
            fontFamily: 'Poppins',
          ),
        ),
        trailing: IconButton(
          onPressed: () {
            // Navigate to user profile
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileScreen(
                  userId: userData['_id'] ?? '',
                  username: username,
                  fullName: fullName,
                  avatar: avatar,
                  bio: '',
                  followersCount: 0,
                  followingCount: 0,
                  postsCount: 0,
                  isPrivate: userData['isPrivate'] ?? false,
                ),
              ),
            );
          },
          icon: const Icon(
            Icons.visibility,
            color: Color(0xFF6366F1),
          ),
        ),
        onTap: () {
          // Navigate to user profile
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfileScreen(
                userId: userData['_id'] ?? '',
                username: username,
                fullName: fullName,
                avatar: avatar,
                bio: '',
                followersCount: 0,
                followingCount: 0,
                postsCount: 0,
                isPrivate: userData['isPrivate'] ?? false,
              ),
            ),
          );
        },
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
}
