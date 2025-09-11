import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/baba_page_model.dart';
import '../services/baba_page_service.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../services/theme_service.dart';
import 'baba_page_detail_screen.dart';
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
          backgroundColor: themeService.backgroundColor,
          appBar: AppBar(
            title: Text(
              'Baba Ji Pages',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: themeService.onPrimaryColor,
              ),
            ),
            backgroundColor: themeService.primaryColor,
            foregroundColor: themeService.onPrimaryColor,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8.0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                print('Back button pressed in BabaPagesScreen');
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  print('Cannot pop - no previous route');
                  // If we can't pop, try to go to home or dashboard
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BabaPageCreationScreen(),
                ),
              ).then((_) {
                // Refresh the list when returning from creation screen
                _loadBabaPages(refresh: true);
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Status Bar
          if (_searchQuery != null || _selectedReligion != 'All')
            Container(
              padding: const EdgeInsets.all(16),
              color: themeService.primaryColor.withOpacity(0.1),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_searchQuery != null)
                          Text(
                            'Search: "$_searchQuery"',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: themeService.primaryColor,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        if (_selectedReligion != 'All')
                          Text(
                            'Religion: $_selectedReligion',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: themeService.primaryColor,
                              fontFamily: 'Poppins',
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: themeService.primaryColor,
                    ),
                    onPressed: _clearSearch,
                    tooltip: 'Clear filters',
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
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          color: themeService.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BabaPageDetailScreen(babaPage: babaPage),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: themeService.primaryColor.withOpacity(0.1),
                        child: babaPage.avatar.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  babaPage.avatar,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    Icons.self_improvement,
                                    size: 30,
                                    color: themeService.primaryColor,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.self_improvement,
                                size: 30,
                                color: themeService.primaryColor,
                              ),
                      ),
                      const SizedBox(width: 12),
                      // Name and Location
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              babaPage.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: themeService.onSurfaceColor,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: themeService.onSurfaceColor.withOpacity(0.6),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    babaPage.location,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: themeService.onSurfaceColor.withOpacity(0.6),
                                      fontFamily: 'Poppins',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getReligionColor(babaPage.religion, themeService).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                babaPage.religion,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _getReligionColor(babaPage.religion, themeService),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Follow Button
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Implement follow functionality
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeService.primaryColor,
                            foregroundColor: themeService.onPrimaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: const Size(80, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Follow',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                      // Menu button
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BabaPageEditScreen(babaPage: babaPage),
                                ),
                              ).then((_) {
                                // Refresh the list when returning from edit screen
                                _loadBabaPages(refresh: true);
                              });
                              break;
                            case 'delete':
                              _showDeleteConfirmation(babaPage);
                              break;
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        child: Icon(
                          Icons.more_vert,
                          color: themeService.onSurfaceColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Description
                  Text(
                    babaPage.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: themeService.onSurfaceColor.withOpacity(0.8),
                      fontFamily: 'Poppins',
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Stats
                  Row(
                    children: [
                      _buildStatItem(
                        Icons.people,
                        '${babaPage.followersCount}',
                        'Followers',
                        themeService,
                      ),
                      const SizedBox(width: 16),
                      _buildStatItem(
                        Icons.grid_on,
                        '${babaPage.postsCount}',
                        'Posts',
                        themeService,
                      ),
                      const SizedBox(width: 16),
                      _buildStatItem(
                        Icons.play_circle_outline,
                        '${babaPage.videosCount}',
                        'Videos',
                        themeService,
                      ),
                      const SizedBox(width: 16),
                      _buildStatItem(
                        Icons.auto_stories,
                        '${babaPage.storiesCount}',
                        'Stories',
                        themeService,
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

  Widget _buildStatItem(IconData icon, String count, String label, ThemeService themeService) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: themeService.onSurfaceColor.withOpacity(0.6),
        ),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: themeService.onSurfaceColor,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: themeService.onSurfaceColor.withOpacity(0.6),
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

