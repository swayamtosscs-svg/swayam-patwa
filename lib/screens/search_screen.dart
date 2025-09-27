import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/theme_service.dart';
import '../services/chat_service.dart';
// Removed unused imports
import '../screens/user_profile_screen.dart';
import '../screens/chat_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _lastQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _lastQuery = query.trim();
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final results = await authProvider.searchUsers(query.trim());
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
          _hasSearched = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSearchSubmitted(String query) {
    _performSearch(query);
  }

  void _onSearchChanged(String query) {
    // Debounce search - only search after user stops typing
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == query) {
        _performSearch(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Signup page bg.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Custom App Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Search Users',
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        // Search Bar
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final screenWidth = constraints.maxWidth;
                            final isSmallScreen = screenWidth < 400;
                            
                            return Container(
                              margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.8),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                onSubmitted: _onSearchSubmitted,
                                onChanged: _onSearchChanged,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontFamily: 'Poppins',
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search for users...',
                                  hintStyle: const TextStyle(
                                    color: Colors.black54,
                                    fontFamily: 'Poppins',
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Colors.black,
                                  ),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {
                                              _searchResults = [];
                                              _hasSearched = false;
                                            });
                                          },
                                          icon: const Icon(
                                            Icons.clear,
                                            color: Colors.black54,
                                          ),
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 16 : 20,
                                    vertical: isSmallScreen ? 12 : 15,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // Search Results
                        Expanded(
                          child: _buildSearchResults(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        if (_isLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: themeService.primaryColor,
            ),
          );
        }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.black.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Search for users',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter a username or name to find other accounts',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: Colors.black.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No users found for "$_lastQuery"',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 400;
        
        return ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 16,
          ),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final userData = _searchResults[index];
            return _buildUserCard(userData, isSmallScreen);
          },
        );
      },
    );
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> userData, bool isSmallScreen) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final username = userData['username'] ?? 'Unknown';
        final fullName = userData['fullName'] ?? 'No Name';
        final bio = userData['bio'] ?? '';
        final avatar = userData['avatar'] ?? '';
        final userId = userData['_id'] ?? '';
        final followersCount = userData['followersCount'] ?? 0;
        final followingCount = userData['followingCount'] ?? 0;
        final postsCount = userData['postsCount'] ?? 0;

        return Container(
          margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
      child: ListTile(
        contentPadding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        leading: CircleAvatar(
          radius: 25,
                       backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
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
        title: Row(
          children: [
            Expanded(
              child: Text(
                fullName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  fontFamily: 'Poppins',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (username.isNotEmpty)
              Text(
                '@$username',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontFamily: 'Poppins',
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bio.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                bio,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontFamily: 'Poppins',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatItem('Posts', postsCount.toString()),
                SizedBox(width: isSmallScreen ? 12 : 16),
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
                        _buildStatItem('Followers', realFollowersCount.toString()),
                        SizedBox(width: isSmallScreen ? 12 : 16),
                        _buildStatItem('Following', realFollowingCount.toString()),
                      ],
                    );
                  },
                ),
              ],
            ),
            
            // Action Buttons
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Message Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Add conversation to local storage
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      if (authProvider.userProfile != null) {
                        await ChatService.addConversation(
                          currentUserId: authProvider.userProfile!.id,
                          otherUserId: userData['_id'] ?? '',
                          otherUsername: username,
                          otherFullName: fullName,
                          otherAvatar: avatar,
                        );
                      }
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            recipientUserId: userData['_id'] ?? '',
                            recipientUsername: username,
                            recipientFullName: fullName,
                            recipientAvatar: avatar,
                            threadId: null, // New conversation
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.message, size: 18),
                    label: const Text('Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          // Navigate to user profile screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfileScreen(
                userId: userData['_id'] ?? '',
                username: username,
                fullName: fullName,
                avatar: avatar,
                bio: bio,
                followersCount: followersCount,
                followingCount: followingCount,
                postsCount: postsCount,
                isPrivate: userData['isPrivate'] ?? false,
              ),
            ),
          );
        },
      ),
        );
      },
    );
  }

  Widget _buildDefaultAvatar() {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Icon(
          Icons.person,
          size: 30,
          color: Colors.black,
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontFamily: 'Poppins',
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}
