import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../models/baba_page_model.dart';
import '../services/baba_page_service.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../services/theme_service.dart';
import 'baba_page_detail_screen.dart';
import 'baba_profile_ui_demo.dart';
import 'baba_page_creation_screen.dart';
import 'baba_page_edit_screen.dart';

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
    if (refresh) {
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

      final response = await BabaPageService.getBabaPages(
        token: token,
        page: _currentPage,
        limit: 10,
        search: _searchQuery,
        religion: _selectedReligion == 'All' ? null : _selectedReligion,
      );

      if (response.success) {
        setState(() {
          if (refresh) {
            _babaPages = response.pages;
          } else {
            _babaPages.addAll(response.pages);
          }
          _isLoading = false;
          
          if (response.pagination != null) {
            _hasMorePages = _currentPage < response.pagination!.totalPages;
          } else {
            _hasMorePages = response.pages.length >= 10;
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
                                  color: Colors.white, // White like second image
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
                                    color: Colors.white, // White like second image
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
                                  color: Colors.white, // White like second image
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
                                  color: Colors.white, // White like second image
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
            );
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
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/babji_dp_bg_frame.jpg'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Profile Picture
                      Positioned(
                        top: 18,
                        left: 17,
                        child: CircleAvatar(
                          radius: 23,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 23,
                            backgroundImage: NetworkImage(babaPage.avatar),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Text Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          babaPage.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              babaPage.location,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5DC), // Creamy beige background
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            babaPage.religion,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFBD9C7C), // Golden-brown text color
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          babaPage.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Statistics Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(Icons.people, babaPage.followersCount.toString(), 'Followers'),
                            _buildStatItem(Icons.grid_view, babaPage.postsCount.toString(), 'Posts'),
                            _buildStatItem(Icons.play_circle, babaPage.videosCount.toString(), 'Videos'),
                            _buildStatItem(Icons.book, babaPage.storiesCount.toString(), 'Stories'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Right side buttons (Follow + Menu)
                  Column(
                    children: [
                      // Follow Button (gradient + compact, avoids overflow)
                      FittedBox(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFC2D6D6), Color(0xFFBDD5D3)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: GestureDetector(
                            onTap: () {
                              print('Follow button pressed for: ${babaPage.name}');
                            },
                            child: const Text(
                              'Follow',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.more_vert,
                            color: Colors.grey,
                            size: 20,
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: const Color(0xFF6B7280), // Muted purple-grey color
        ),
        const SizedBox(width: 4),
        Text(
          count,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280), // Muted purple-grey color
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280), // Muted purple-grey color
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Color _getReligionColor(String religion, ThemeService themeService) {
    switch (religion.toLowerCase()) {
      case 'hinduism':
        return ThemeService.hinduSaffronOrange;
      case 'islam':
        return ThemeService.islamDarkGreen;
      case 'christianity':
        return ThemeService.christianDeepBlue;
      case 'sikhism':
        return ThemeService.sikhSaffron;
      case 'buddhism':
        return ThemeService.buddhistMonkOrange;
      case 'jainism':
        return ThemeService.jainDeepRed;
      case 'judaism':
        return ThemeService.jewishDeepBlue;
      case 'bahai':
        return ThemeService.bahaiWarmOrange;
      case 'taoism':
        return ThemeService.taoBlack;
      case 'indigenous':
        return ThemeService.indigenousEarthBrown;
      default:
        return themeService.primaryColor;
    }
  }
}

