import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/baba_page_model.dart';
import '../services/baba_page_service.dart';
import '../services/follow_state_service.dart';
import '../providers/auth_provider.dart';
import '../services/theme_service.dart';
import '../utils/avatar_utils.dart';
import 'baba_profile_ui_demo.dart';
import 'baba_page_creation_screen.dart';

class BabaPagesScreen extends StatefulWidget {
  const BabaPagesScreen({super.key});

  @override
  State<BabaPagesScreen> createState() => _BabaPagesScreenState();
}

class _BabaPagesScreenState extends State<BabaPagesScreen> {
  List<BabaPage> _babaPages = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMorePages = true;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _selectedReligion = 'All';
  String? _searchQuery;
  
  // Performance optimizations
  static const int _initialLoadLimit = 5; // Load fewer items initially
  static const int _paginationLimit = 10;
  DateTime? _lastLoadTime;
  static const Duration _cacheTimeout = Duration(minutes: 5); // Cache for 5 minutes

  @override
  void initState() {
    super.initState();
    _loadBabaPages();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_hasMorePages && !_isLoading) {
        _loadMorePages();
      }
    }
  }

  Future<void> _loadBabaPages({bool refresh = false}) async {
    // Check cache timeout for non-refresh requests
    if (!refresh && _lastLoadTime != null && 
        DateTime.now().difference(_lastLoadTime!) < _cacheTimeout &&
        _babaPages.isNotEmpty) {
      print('BabaPagesScreen: Using cached data');
      return;
    }

    if (refresh) {
      // Clear service cache on refresh
      BabaPageService.clearCache();
      setState(() {
        _currentPage = 1;
        _babaPages.clear();
        _hasMorePages = true;
      });
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;

      if (token == null) {
        setState(() {
          _errorMessage = 'Please login to view Baba Ji pages';
          _isLoading = false;
        });
        return;
      }

      // Use smaller limit for initial load
      final limit = _currentPage == 1 ? _initialLoadLimit : _paginationLimit;

      final response = await BabaPageService.getBabaPages(
        token: token,
        page: _currentPage,
        limit: limit,
        search: _searchQuery,
        religion: _selectedReligion == 'All' ? null : _selectedReligion,
      );

      if (response.success) {
        // Load follow states from SharedPreferences and update the pages
        final updatedPages = await _loadFollowStatesFromPrefs(response.pages);
        
        setState(() {
          if (refresh) {
            _babaPages = updatedPages;
          } else {
            _babaPages.addAll(updatedPages);
          }
          _isLoading = false;
          _lastLoadTime = DateTime.now();
          
          if (response.pagination != null) {
            _hasMorePages = _currentPage < response.pagination!.totalPages;
          } else {
            _hasMorePages = response.pages.length >= limit;
          }
        });
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading Baba Ji pages: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMorePages() async {
    if (_isLoading || !_hasMorePages) return;

    setState(() {
      _currentPage++;
    });

    await _loadBabaPages();
  }

  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text.trim().isEmpty ? null : _searchController.text.trim();
      _currentPage = 1;
      _babaPages.clear();
      _hasMorePages = true;
    });
    _loadBabaPages(refresh: true);
  }

  void _onReligionChanged(String? religion) {
    if (religion != null) {
      setState(() {
        _selectedReligion = religion;
        _currentPage = 1;
        _babaPages.clear();
        _hasMorePages = true;
      });
      _loadBabaPages(refresh: true);
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = null;
      _currentPage = 1;
      _babaPages.clear();
      _hasMorePages = true;
    });
    _loadBabaPages(refresh: true);
  }

  /// Load follow states from SharedPreferences and update BabaPage objects
  Future<List<BabaPage>> _loadFollowStatesFromPrefs(List<BabaPage> pages) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userProfile?.id;
      
      if (userId == null) {
        return pages; // Return original pages if no user ID
      }

      return await FollowStateService.updatePagesWithFollowStates(
        pages: pages,
        userId: userId,
      );
    } catch (e) {
      print('Error loading follow states from preferences: $e');
      return pages; // Return original pages on error
    }
  }

  /// Save follow state to SharedPreferences
  Future<void> _saveFollowState(String pageId, bool isFollowing) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userProfile?.id;
      
      if (userId != null) {
        await FollowStateService.saveFollowState(
          userId: userId,
          pageId: pageId,
          isFollowing: isFollowing,
        );
      }
    } catch (e) {
      print('Error saving follow state: $e');
    }
  }

  Future<void> _handleFollowBabaPage(BabaPage babaPage) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.authToken;
    
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      print('BabaPagesScreen: Toggling follow status for ${babaPage.name}. Current: ${babaPage.isFollowing}');
      
      if (babaPage.isFollowing) {
        // Unfollow
        print('BabaPagesScreen: Unfollowing page ${babaPage.id}');
        final resp = await BabaPageService.unfollowBabaPage(pageId: babaPage.id, token: token);
        print('BabaPagesScreen: Unfollow response: ${resp.success}, ${resp.message}');
        
        if (resp.success) {
          // Save follow state to SharedPreferences
          await _saveFollowState(babaPage.id, false);
          
          setState(() {
            // Update the local list
            final index = _babaPages.indexWhere((page) => page.id == babaPage.id);
            if (index != -1) {
              _babaPages[index] = BabaPage(
                id: babaPage.id,
                name: babaPage.name,
                description: babaPage.description,
                avatar: babaPage.avatar,
                coverImage: babaPage.coverImage,
                location: babaPage.location,
                religion: babaPage.religion,
                website: babaPage.website,
                followersCount: (babaPage.followersCount - 1).clamp(0, 1 << 31),
                postsCount: babaPage.postsCount,
                videosCount: babaPage.videosCount,
                storiesCount: babaPage.storiesCount,
                isActive: babaPage.isActive,
                isFollowing: false,
                createdAt: babaPage.createdAt,
                updatedAt: babaPage.updatedAt,
              );
            }
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unfollowed ${babaPage.name}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          // Handle specific error cases
          String errorMessage = resp.message;
          if (errorMessage.toLowerCase().contains('not following') || 
              errorMessage.toLowerCase().contains('not found')) {
            // If we're not actually following, update UI to reflect this
            await _saveFollowState(babaPage.id, false);
            setState(() {
              final index = _babaPages.indexWhere((page) => page.id == babaPage.id);
              if (index != -1) {
                _babaPages[index] = BabaPage(
                  id: babaPage.id,
                  name: babaPage.name,
                  description: babaPage.description,
                  avatar: babaPage.avatar,
                  coverImage: babaPage.coverImage,
                  location: babaPage.location,
                  religion: babaPage.religion,
                  website: babaPage.website,
                  followersCount: babaPage.followersCount,
                  postsCount: babaPage.postsCount,
                  videosCount: babaPage.videosCount,
                  storiesCount: babaPage.storiesCount,
                  isActive: babaPage.isActive,
                  isFollowing: false,
                  createdAt: babaPage.createdAt,
                  updatedAt: babaPage.updatedAt,
                );
              }
            });
            errorMessage = 'You are not following this page';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to unfollow: $errorMessage'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Follow
        print('BabaPagesScreen: Following page ${babaPage.id}');
        final resp = await BabaPageService.followBabaPage(pageId: babaPage.id, token: token);
        print('BabaPagesScreen: Follow response: ${resp.success}, ${resp.message}');
        
        if (resp.success) {
          // Save follow state to SharedPreferences
          await _saveFollowState(babaPage.id, true);
          
          setState(() {
            // Update the local list
            final index = _babaPages.indexWhere((page) => page.id == babaPage.id);
            if (index != -1) {
              _babaPages[index] = BabaPage(
                id: babaPage.id,
                name: babaPage.name,
                description: babaPage.description,
                avatar: babaPage.avatar,
                coverImage: babaPage.coverImage,
                location: babaPage.location,
                religion: babaPage.religion,
                website: babaPage.website,
                followersCount: babaPage.followersCount + 1,
                postsCount: babaPage.postsCount,
                videosCount: babaPage.videosCount,
                storiesCount: babaPage.storiesCount,
                isActive: babaPage.isActive,
                isFollowing: true,
                createdAt: babaPage.createdAt,
                updatedAt: babaPage.updatedAt,
              );
            }
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Following ${babaPage.name}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          // Handle specific error cases
          String errorMessage = resp.message;
          if (errorMessage.toLowerCase().contains('already following')) {
            // If we're already following, update UI to reflect this
            await _saveFollowState(babaPage.id, true);
            setState(() {
              final index = _babaPages.indexWhere((page) => page.id == babaPage.id);
              if (index != -1) {
                _babaPages[index] = BabaPage(
                  id: babaPage.id,
                  name: babaPage.name,
                  description: babaPage.description,
                  avatar: babaPage.avatar,
                  coverImage: babaPage.coverImage,
                  location: babaPage.location,
                  religion: babaPage.religion,
                  website: babaPage.website,
                  followersCount: babaPage.followersCount,
                  postsCount: babaPage.postsCount,
                  videosCount: babaPage.videosCount,
                  storiesCount: babaPage.storiesCount,
                  isActive: babaPage.isActive,
                  isFollowing: true,
                  createdAt: babaPage.createdAt,
                  updatedAt: babaPage.updatedAt,
                );
              }
            });
            errorMessage = 'You are already following this page';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to follow: $errorMessage'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('BabaPagesScreen: Follow/Unfollow error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _deleteBabaPage(BabaPage babaPage) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;

      if (token == null) {
        _showErrorSnackBar('Please login to delete Baba Ji page');
        return;
      }

      final response = await BabaPageService.deleteBabaPage(
        pageId: babaPage.id,
        token: token,
      );

      if (response.success) {
        _showSuccessSnackBar('Baba Ji page deleted successfully!');
        // Remove from local list
        setState(() {
          _babaPages.removeWhere((page) => page.id == babaPage.id);
        });
      } else {
        _showErrorSnackBar(response.message);
      }
    } catch (e) {
      _showErrorSnackBar('Error deleting Baba Ji page: $e');
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

  void _showDeleteConfirmation(BabaPage babaPage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Baba Ji Page'),
          content: Text('Are you sure you want to delete "${babaPage.name}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteBabaPage(babaPage);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Search Baba Ji Pages'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search by name or description',
                      hintText: 'Enter search term...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedReligion,
                    decoration: const InputDecoration(
                      labelText: 'Filter by Religion',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      'All',
                      'Hinduism',
                      'Islam',
                      'Christianity',
                      'Sikhism',
                      'Buddhism',
                      'Jainism',
                      'Other',
                    ].map((String religion) {
                      return DropdownMenuItem<String>(
                        value: religion,
                        child: Text(religion),
                      );
                    }).toList(),
                    onChanged: _onReligionChanged,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _clearSearch();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Clear'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _performSearch();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Search'),
                ),
              ],
            );
          },
        );
      },
    );
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
                  // White Highlighted Search Bar (Header) - Like second image
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1), // Translucent white like second image
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.6), // Bright white highlighted border
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.6), // White glow effect
                          blurRadius: 20,
                          spreadRadius: 4,
                          offset: const Offset(0, 0),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              // Back button
                              GestureDetector(
                                onTap: () {
                                  print('Back button pressed in BabaPagesScreen');
                                  if (Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop();
                                  } else {
                                    print('Cannot pop - no previous route');
                                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                                  }
                                },
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.black, // Changed to black as requested
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Title
                              Expanded(
                                child: Text(
                                  'Global Guides for Peace',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black, // Changed to black as requested
                                    fontFamily: 'Poppins',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Search icon
                              GestureDetector(
                                onTap: () {
                                  _showSearchDialog();
                                },
                                child: const Icon(
                                  Icons.search,
                                  color: Colors.black, // Changed to black as requested
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Add icon
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const BabaPageCreationScreen(),
                                    ),
                                  ).then((_) {
                                    _loadBabaPages(refresh: true);
                                  });
                                },
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.black, // Changed to black as requested
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Search and Filter Status Bar
                  if (_searchQuery != null || _selectedReligion != 'All')
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_searchQuery != null)
                                  Text(
                                    'Search: "$_searchQuery"',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4A2C2A),
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                    ),
                                  ),
                                if (_selectedReligion != 'All')
                                  Text(
                                    'Religion: $_selectedReligion',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4A2C2A),
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: _clearSearch,
                            child: const Icon(
                              Icons.clear,
                              color: Color(0xFF4A2C2A),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Main Content
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => _loadBabaPages(refresh: true),
                      child: _buildBody(),
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

  Widget _buildBody() {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        if (_isLoading && _babaPages.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(themeService.primaryColor),
            ),
          );
        }

    if (_errorMessage != null && _babaPages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: themeService.onSurfaceColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 16,
                color: themeService.onSurfaceColor,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadBabaPages(refresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeService.primaryColor,
                foregroundColor: themeService.onPrimaryColor,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_babaPages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.self_improvement,
              size: 64,
              color: themeService.onSurfaceColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Baba Ji pages found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeService.onSurfaceColor,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to create a spiritual page',
              style: TextStyle(
                fontSize: 14,
                color: themeService.onSurfaceColor.withOpacity(0.7),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BabaPageCreationScreen(),
                  ),
                ).then((_) {
                  _loadBabaPages(refresh: true);
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Baba Ji Page'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeService.primaryColor,
                foregroundColor: themeService.onPrimaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _babaPages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _babaPages.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(themeService.primaryColor),
              ),
            ),
          );
        }

        final babaPage = _babaPages[index];
        return _buildBabaPageCard(babaPage);
      },
    );
      },
    );
  }

  Widget _buildBabaPageCard(BabaPage babaPage) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return GestureDetector(
          onTap: () {
            // Open the new profile UI demo screen for Baba Ji
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BabaProfileUiDemoScreen(babaPage: babaPage),
                          ),
                        ).then((_) {
                          // Refresh the Baba pages list when returning from profile screen
                          // This ensures any DP changes are reflected
                          _loadBabaPages(refresh: true);
                        });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9), // background हल्का white
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.6), // हल्की semi-transparent white border
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08), // बहुत subtle shadow
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Avatar/Profile Photo with Frame
                  Stack(
                    children: [
                      // Golden Frame Background
                      Container(
                        width: 70, // Reduced size to save space
                        height: 70,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/babji_dp_bg_frame.jpg'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Profile Picture
                      Positioned(
                        top: 16, // Adjusted positioning
                        left: 15,
                        child: CircleAvatar(
                          radius: 20, // Reduced radius
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundImage: AvatarUtils.isValidAvatarUrl(babaPage.avatar)
                                ? NetworkImage(AvatarUtils.getAbsoluteAvatarUrl(babaPage.avatar))
                                : null,
                            child: AvatarUtils.isValidAvatarUrl(babaPage.avatar)
                                ? null
                                : const Icon(
                                    Icons.temple_hindu,
                                    color: Colors.orange,
                                    size: 20, // Reduced icon size
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8), // Reduced spacing

                  // Text Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          babaPage.name,
                          style: const TextStyle(
                            fontSize: 16, // Reduced font size
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 12, color: Colors.grey),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                babaPage.location,
                                style: const TextStyle(
                                  fontSize: 12, // Reduced font size
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5DC), // Creamy beige background
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            babaPage.religion,
                            style: const TextStyle(
                              fontSize: 10, // Reduced font size
                              color: Color(0xFFBD9C7C), // Golden-brown text color
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          babaPage.description,
                          style: const TextStyle(
                            fontSize: 12, // Reduced font size
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2, // Allow 2 lines for description
                        ),
                        const SizedBox(height: 8),
                        // Statistics Row - Improved responsive layout to prevent overflow
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 180) {
                              // For very small cards, use 2x2 grid
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: _buildStatItem(Icons.people, babaPage.followersCount.toString(), 'Followers')),
                                      Expanded(child: _buildStatItem(Icons.grid_view, babaPage.postsCount.toString(), 'Posts')),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(child: _buildStatItem(Icons.play_circle, babaPage.videosCount.toString(), 'Videos')),
                                      Expanded(child: _buildStatItem(Icons.book, babaPage.storiesCount.toString(), 'Stories')),
                                    ],
                                  ),
                                ],
                              );
                            } else if (constraints.maxWidth < 250) {
                              // For medium cards, use 2x2 grid with more spacing
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: _buildStatItem(Icons.people, babaPage.followersCount.toString(), 'Followers')),
                                      Expanded(child: _buildStatItem(Icons.grid_view, babaPage.postsCount.toString(), 'Posts')),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(child: _buildStatItem(Icons.play_circle, babaPage.videosCount.toString(), 'Videos')),
                                      Expanded(child: _buildStatItem(Icons.book, babaPage.storiesCount.toString(), 'Stories')),
                                    ],
                                  ),
                                ],
                              );
                            } else {
                              // For normal cards, use horizontal layout with proper constraints
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(child: _buildStatItem(Icons.people, babaPage.followersCount.toString(), 'Followers')),
                                  Expanded(child: _buildStatItem(Icons.grid_view, babaPage.postsCount.toString(), 'Posts')),
                                  Expanded(child: _buildStatItem(Icons.play_circle, babaPage.videosCount.toString(), 'Videos')),
                                  Expanded(child: _buildStatItem(Icons.book, babaPage.storiesCount.toString(), 'Stories')),
                                ],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  // Right side buttons (Follow + Menu) - Compact layout
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Follow Button (gradient + compact, avoids overflow)
                      Container(
                        constraints: const BoxConstraints(maxWidth: 80), // Constrain width
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: babaPage.isFollowing 
                              ? const LinearGradient(
                                  colors: [Color(0xFF4CAF50), Color(0xFF45A049)], // Green gradient for following
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : const LinearGradient(
                                  colors: [Color(0xFFC2D6D6), Color(0xFFBDD5D3)], // Original gradient for follow
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: GestureDetector(
                            onTap: () => _handleFollowBabaPage(babaPage),
                            child: Text(
                              babaPage.isFollowing ? 'Following' : 'Follow',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 10, // Reduced font size
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // 3-dot menu button
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'delete') {
                            _showDeleteConfirmation(babaPage);
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Delete Page',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.more_vert,
                            color: Colors.grey,
                            size: 16, // Reduced icon size
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 10, // Further reduced size
                color: const Color(0xFF6B7280),
              ),
              const SizedBox(width: 1),
              Flexible(
                child: Text(
                  count,
                  style: const TextStyle(
                    fontSize: 9, // Further reduced font size
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Poppins',
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8, // Further reduced font size
              color: Color(0xFF6B7280),
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

}

