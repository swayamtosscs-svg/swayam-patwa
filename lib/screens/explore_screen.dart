import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../widgets/post_widget.dart';
import '../utils/app_theme.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedReligionIndex = 0;
  
  final List<String> _religions = [
    'All',
    'Hinduism',
    'Islam', 
    'Christianity',
    'Buddhism',
    'Sikhism',
    'Judaism',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // App Bar
          _buildAppBar(),
          
          // Religion Filter
          _buildReligionFilter(),
          
          // Tab Bar
          _buildTabBar(),
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTrendingTab(),
                _buildRecentTab(),
                _buildPopularTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppTheme.borderColor,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.explore,
            color: Color(0xFF6366F1),
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            'Explore',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
              fontFamily: 'Poppins',
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              // Search functionality
            },
            icon: const Icon(
              Icons.search,
              color: Color(0xFF666666),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReligionFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _religions.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedReligionIndex == index;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedReligionIndex = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6366F1) : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected 
                      ? const Color(0xFF6366F1)
                      : const Color(0xFFE5E7EB),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (index > 0) ...[
                    Text(
                      _getReligionSymbol(index - 1),
                      style: TextStyle(
                        fontSize: 16,
                        color: isSelected ? Colors.white : _getReligionColor(index - 1),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    _religions[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF666666),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF6366F1),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF666666),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'Poppins',
        ),
        tabs: const [
          Tab(text: 'Trending'),
          Tab(text: 'Recent'),
          Tab(text: 'Popular'),
        ],
      ),
    );
  }

  Widget _buildTrendingTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        final post = _getMockTrendingPost(index);
        return PostWidget(
          post: post,
          onLike: () {
            // Handle like
          },
          onComment: () {
            // Handle comment
          },
          onShare: () {
            // Handle share
          },
          onUserTap: () {
            // Navigate to user profile
          },
        );
      },
    );
  }

  Widget _buildRecentTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        final post = _getMockRecentPost(index);
        return PostWidget(
          post: post,
          onLike: () {
            // Handle like
          },
          onComment: () {
            // Handle comment
          },
          onShare: () {
            // Handle share
          },
          onUserTap: () {
            // Navigate to user profile
          },
        );
      },
    );
  }

  Widget _buildPopularTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        final post = _getMockPopularPost(index);
        return PostWidget(
          post: post,
          onLike: () {
            // Handle like
          },
          onComment: () {
            // Handle comment
          },
          onShare: () {
            // Handle share
          },
          onUserTap: () {
            // Navigate to user profile
          },
        );
      },
    );
  }

  // Helper methods
  String _getReligionSymbol(int index) {
    final symbols = ['ॐ', '☪', '✝', '☸', '☬', '✡', '🕉'];
    return symbols[index];
  }

  Color _getReligionColor(int index) {
    final colors = [
      Colors.orange,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.amber,
      Colors.indigo,
      Colors.grey,
    ];
    return colors[index];
  }

  Post _getMockTrendingPost(int index) {
    return Post(
      id: 'trending_post_$index',
      userId: 'trending_user_$index',
      username: 'trending_user_$index',
      userAvatar: '🔥',
      caption: 'This is a trending post #trending #viral #content',
      imageUrl: 'https://picsum.photos/400/400?random=${index + 400}',
      type: PostType.image,
      likes: (index + 1) * 100,
      comments: (index + 1) * 20,
      shares: (index + 1) * 10,
      createdAt: DateTime.now().subtract(Duration(hours: index)),
      hashtags: ['trending', 'viral', 'content'],
    );
  }

  Post _getMockRecentPost(int index) {
    return Post(
      id: 'recent_post_$index',
      userId: 'recent_user_$index',
      username: 'recent_user_$index',
      userAvatar: '🆕',
      caption: 'This is a recent post #recent #new #content',
      imageUrl: 'https://picsum.photos/400/400?random=${index + 500}',
      type: PostType.image,
      likes: (index + 1) * 50,
      comments: (index + 1) * 10,
      shares: (index + 1) * 5,
      createdAt: DateTime.now().subtract(Duration(minutes: index * 30)),
      hashtags: ['recent', 'new', 'content'],
    );
  }

  Post _getMockPopularPost(int index) {
    return Post(
      id: 'popular_post_$index',
      userId: 'popular_user_$index',
      username: 'popular_user_$index',
      userAvatar: '⭐',
      caption: 'This is a popular post #popular #famous #content',
      imageUrl: 'https://picsum.photos/400/400?random=${index + 600}',
      type: PostType.image,
      likes: (index + 1) * 200,
      comments: (index + 1) * 40,
      shares: (index + 1) * 20,
      createdAt: DateTime.now().subtract(Duration(days: index)),
      hashtags: ['popular', 'famous', 'content'],
    );
  }

  Religion? _getMockReligion(int index) {
    final religions = [
      Religion.hinduism,
      Religion.islam,
      Religion.christianity,
      Religion.buddhism,
      Religion.sikhism,
      Religion.judaism,
      Religion.other,
    ];
    return religions[index % religions.length];
  }

  String _getMockLocation(int index) {
    final locations = [
      'Golden Temple, Amritsar',
      'Mecca, Saudi Arabia',
      'Vatican City, Rome',
      'Bodh Gaya, India',
      'Harmandir Sahib, Amritsar',
      'Western Wall, Jerusalem',
      'Sacred Grove, Varanasi',
    ];
    return locations[index % locations.length];
  }
} 