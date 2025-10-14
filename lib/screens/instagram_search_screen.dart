import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/theme_service.dart';
import '../models/post_model.dart';
import '../widgets/post_widget.dart';
import '../screens/user_profile_screen.dart';
import '../services/feed_service.dart';
import '../services/user_search_service.dart';
import '../widgets/user_search_result_widget.dart';
import '../models/user_model.dart';

class InstagramSearchScreen extends StatefulWidget {
  const InstagramSearchScreen({super.key});

  @override
  State<InstagramSearchScreen> createState() => _InstagramSearchScreenState();
}

class _InstagramSearchScreenState extends State<InstagramSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Post> _searchResults = [];
  List<Post> _babaJiPosts = []; // Store Baba Ji posts for grid display
  List<String> _recentSearches = [];
  List<UserSearchResult> _userSearchResults = []; // Store user search results
  bool _isLoading = false;
  bool _hasSearched = false;
  String _lastQuery = '';
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _loadBabaJiPosts(); // Load Baba Ji posts for grid display
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadRecentSearches() {
    // Load recent searches from shared preferences or local storage
    _recentSearches = [
      'happy teachers day',
      'spiritual quotes',
      'nature photography',
      'meditation',
    ];
  }

  void _addToRecentSearches(String query) {
    if (query.trim().isNotEmpty && !_recentSearches.contains(query.trim())) {
      setState(() {
        _recentSearches.insert(0, query.trim());
        if (_recentSearches.length > 10) {
          _recentSearches = _recentSearches.take(10).toList();
        }
      });
    }
  }

  void _removeRecentSearch(String query) {
    setState(() {
      _recentSearches.remove(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _userSearchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _lastQuery = query.trim();
    });

    // Add to recent searches
    _addToRecentSearches(query);

    // Perform user search
    await _searchUsers(query);
  }

  Future<void> _searchUsers(String query) async {
    try {
      // Get auth token
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;
      
      if (token == null) {
        print('No auth token available for user search');
        setState(() {
          _userSearchResults = [];
        });
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Search for real users using the new service
      final users = await UserSearchService.searchUsersWithFallback(
        query: query,
        token: token,
        page: 1,
        limit: 20,
      );

      setState(() {
        _userSearchResults = users;
        _isLoading = false;
        _hasSearched = true;
      });

      print('Found ${users.length} users for query: $query');
    } catch (e) {
      print('Error searching users: $e');
      setState(() {
        _userSearchResults = [];
        _isLoading = false;
      });
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

  Future<void> _loadBabaJiPosts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get auth token from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;
      
      if (token == null) {
        print('No auth token available for loading Baba Ji posts');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Use FeedService to get Baba Ji posts
      final posts = await FeedService.getBabaJiPosts(
        token: token,
        page: 1,
        limit: 50, // Load more posts for the grid
      );
      
      setState(() {
        _babaJiPosts = posts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading Baba Ji posts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF0EBE1), // Same as login page
          body: SafeArea(
            child: Column(
              children: [
                // Search Header
                _buildSearchHeader(),
                
                // Search Content
                Expanded(
                  child: _hasSearched
                      ? _buildSearchResults() // Show search results when searched
                      : _isSearchFocused
                          ? _buildSearchInterface() // Show search interface when focused
                          : _buildBabaJiGrid(), // Show Baba Ji posts grid by default
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Back Button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Color(0xFF4A2C2A)), // Deep Brown like login page
          ),
          
          // Search Bar
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8), // Same as login page text fields
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: _onSearchSubmitted,
                onChanged: _onSearchChanged,
                onTap: () {
                  setState(() {
                    _isSearchFocused = true;
                  });
                },
                onTapOutside: (event) {
                  // Don't reset search focus when tapping outside
                  // This allows search results to stay visible
                },
                style: const TextStyle(color: Color(0xFF4A2C2A)), // Deep Brown like login page
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(color: Colors.grey[600]), // Same as login page
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF4A2C2A)), // Deep Brown
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Color(0xFF4A2C2A)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _userSearchResults = [];
                              _hasSearched = false;
                              _isSearchFocused = false;
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInterface() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches
          if (_recentSearches.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent',
                    style: TextStyle(
                      color: Color(0xFF4A2C2A), // Deep Brown like login page
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _recentSearches.clear();
                      });
                    },
                    child: const Text(
                      'Clear all',
                      style: TextStyle(color: Color(0xFFD4AF37)), // Muted Gold like login page
                    ),
                  ),
                ],
              ),
            ),
            
            // Recent Search Items
            ..._recentSearches.map((search) => ListTile(
              leading: const Icon(Icons.history, color: Color(0xFF4A2C2A)), // Deep Brown
              title: Text(
                search,
                style: const TextStyle(color: Color(0xFF4A2C2A)), // Deep Brown
              ),
              trailing: IconButton(
                onPressed: () => _removeRecentSearch(search),
                icon: const Icon(Icons.close, color: Color(0xFF4A2C2A), size: 20), // Deep Brown
              ),
              onTap: () {
                _searchController.text = search;
                _performSearch(search);
              },
            )),
          ],
          
          // Search Suggestions
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Suggested',
              style: TextStyle(
                color: Color(0xFF4A2C2A), // Deep Brown like login page
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // Suggested searches
          ...['trending', 'nature', 'spiritual', 'meditation', 'quotes'].map((suggestion) => ListTile(
            leading: const Icon(Icons.search, color: Color(0xFF4A2C2A)), // Deep Brown
            title: Text(
              suggestion,
              style: const TextStyle(color: Color(0xFF4A2C2A)), // Deep Brown
            ),
            onTap: () {
              _searchController.text = suggestion;
              _performSearch(suggestion);
            },
          )),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    print('Building search results: ${_userSearchResults.length} users found');
    print('Has searched: $_hasSearched');
    print('Is loading: $_isLoading');
    
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4A2C2A)), // Deep Brown
      );
    }

    if (_userSearchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              color: Color(0xFF4A2C2A), // Deep Brown
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'No users found',
              style: TextStyle(
                color: Color(0xFF4A2C2A), // Deep Brown
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching for a different name',
              style: TextStyle(
                color: Colors.grey[600], // Same as login page
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Instagram-style user list
    return ListView.builder(
      padding: const EdgeInsets.all(0),
      itemCount: _userSearchResults.length,
      itemBuilder: (context, index) {
        final user = _userSearchResults[index];
        return UserSearchResultWidget(
          id: user.id,
          username: user.username,
          fullName: user.fullName,
          profileImageUrl: user.profileImageUrl,
          followersCount: user.followersCount,
          followingCount: user.followingCount,
          postsCount: user.postsCount,
          isVerified: user.isVerified,
          isFollowedByCurrentUser: user.isFollowedByCurrentUser,
          bio: user.bio,
          isPrivate: user.isPrivate,
        );
      },
    );
  }

  Widget _buildDefaultContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search,
            color: Colors.grey,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Search',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find posts, users, and more',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBabaJiGrid() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4A2C2A)), // Deep Brown
      );
    }

    if (_babaJiPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.image,
              color: Color(0xFF4A2C2A), // Deep Brown
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Baba Ji posts available',
              style: TextStyle(
                color: Color(0xFF4A2C2A), // Deep Brown
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for spiritual content',
              style: TextStyle(
                color: Colors.grey[600], // Same as login page
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _babaJiPosts.length,
      itemBuilder: (context, index) {
        final post = _babaJiPosts[index];
        return GestureDetector(
          onTap: () {
            // Navigate to post detail or full view
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileScreen(
                  userId: post.userId,
                  username: post.username,
                  fullName: post.username, // Use username as fallback for fullName
                  avatar: post.userAvatar,
                  bio: 'User bio', // Default bio
                  followersCount: 0,
                  followingCount: 0,
                  postsCount: 0,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8), // Same as login page text fields
            ),
            child: Stack(
              children: [
                // Image/Video
                if (post.imageUrl != null)
                  Image.network(
                    post.imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.white.withOpacity(0.8),
                        child: const Icon(
                          Icons.image,
                          color: Color(0xFF4A2C2A), // Deep Brown
                          size: 32,
                        ),
                      );
                    },
                  ),
                
                // Video/Reel indicator
                if (post.isReel || post.type == PostType.reel)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(
                      Icons.play_circle_outline,
                      color: Color(0xFF4A2C2A), // Deep Brown
                      size: 20,
                    ),
                  ),
                
                // Multiple images indicator
                if (post.imageUrls.length > 1)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(
                      Icons.layers,
                      color: Color(0xFF4A2C2A), // Deep Brown
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
