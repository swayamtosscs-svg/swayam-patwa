import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoFeedScreen extends StatefulWidget {
  final String selectedReligion;
  
  const VideoFeedScreen({
    super.key,
    required this.selectedReligion,
  });

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  final PageController _pageController = PageController();
  int _currentVideoIndex = 0;
  late List<Map<String, dynamic>> videos;
  late List<Map<String, dynamic>> stories;

  // Use user's YouTube Shorts links for reels
  final List<String> _sampleVideoUrls = const [
    'https://youtube.com/shorts/C3zomZ4asvo',
    'https://youtube.com/shorts/umxuR0EoZWc',
    
    'https://youtube.com/shorts/3_USzU79944',
    'https://youtube.com/shorts/Wyou5RlzJHw',
    'https://youtube.com/shorts/VM0JnDHYzKI',
    // Add some sample MP4 URLs for testing (these are public domain sample videos)
    'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
    'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
  ];

  List<Map<String, dynamic>> _attachUrls(List<Map<String, dynamic>> list) {
    for (int i = 0; i < list.length; i++) {
      final url = _sampleVideoUrls[i % _sampleVideoUrls.length];
      list[i]['url'] = url;
      list[i]['isYoutube'] = _isYouTubeUrl(url);
      list[i]['ytId'] = _extractYouTubeId(url);
    }
    return list;
  }

  bool _isYouTubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  String? _extractYouTubeId(String url) {
    // Shorts: youtube.com/shorts/{id}
    final shorts = RegExp(r'youtube\.com/shorts/([A-Za-z0-9_-]{5,})');
    final m1 = shorts.firstMatch(url);
    if (m1 != null) return m1.group(1);
    // Watch: v= parameter
    final watch = RegExp(r'[?&]v=([A-Za-z0-9_-]{5,})');
    final m2 = watch.firstMatch(url);
    if (m2 != null) return m2.group(1);
    // youtu.be/{id}
    final short = RegExp(r'youtu\.be/([A-Za-z0-9_-]{5,})');
    final m3 = short.firstMatch(url);
    return m3?.group(1);
  }

  @override
  void initState() {
    super.initState();
    _initializeContent();
  }

  void _initializeContent() {
    final religion = widget.selectedReligion;
    
    // Initialize videos based on selected religion
    videos = _getVideosForReligion(religion);
    
    // Initialize stories based on selected religion
    stories = _getStoriesForReligion(religion);
  }

  // Deprecated simulated play/pause removed in favor of real player

  void _navigateToVideo(int index) {
    setState(() {
      _currentVideoIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showAddStoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Add Story',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.white),
                title: const Text(
                  'Video + Text',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showVideoTextDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.image, color: Colors.white),
                title: const Text(
                  'Image + Text',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showImageTextDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVideoTextDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Add Video Story',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(
                    Icons.videocam,
                    size: 50,
                    color: Colors.white54,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Add your story text...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Story added successfully!')),
                );
              },
              child: const Text('Post'),
            ),
          ],
        );
      },
    );
  }

  void _showImageTextDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Add Image Story',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(
                    Icons.image,
                    size: 50,
                    color: Colors.white54,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Add your story text...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Story added successfully!')),
                );
              },
              child: const Text('Post'),
            ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _getVideosForReligion(String religion) {
    switch (religion.toLowerCase()) {
      case 'hinduism':
        return _attachUrls([
          {
            'id': '1',
            'username': 'TejasviSen',
            'userAvatar': '👩',
            'description': 'The hype of audience says it all ✅ #dance #trending',
            'thumbnail': '🕉️',
            'title': 'What\'s my name?? 💃💃',
            'likes': '1.2K',
            'comments': '89',
            'shares': '23',
            'isLiked': true,
            'isFollowing': false,
            'isSaved': false,
            'music': 'Chuttamalle · Shilpa Rao',
            'videoBackground': Colors.red,
          },
          {
            'id': '2',
            'username': 'DivineConnect',
            'userAvatar': '🙏',
            'description': 'Sacred Ganga Aarti ceremony #Hinduism #Ganga #Aarti',
            'thumbnail': '🕯️',
            'title': 'Ganga Aarti Ritual',
            'likes': '856',
            'comments': '45',
            'shares': '12',
            'isLiked': false,
            'isFollowing': true,
            'isSaved': true,
            'music': 'Original Sound',
            'videoBackground': Colors.orange,
          },
          {
            'id': '3',
            'username': 'SpiritualJourney',
            'userAvatar': '🧘',
            'description': 'Meditation at sunrise #Hinduism #Meditation #Peace',
            'thumbnail': '🕊️',
            'title': 'Sunrise Meditation',
            'likes': '2.1K',
            'comments': '156',
            'shares': '67',
            'isLiked': true,
            'isFollowing': false,
            'isSaved': false,
            'music': 'Original Sound',
            'videoBackground': Colors.purple,
          },
        ]);
        
      case 'christianity':
        return _attachUrls([
          {
            'id': '1',
            'username': 'FaithfulHeart',
            'userAvatar': '⛪',
            'description': 'Sunday service at the cathedral #Christianity #Church #Worship',
            'thumbnail': '⛪',
            'title': 'Sunday Service',
            'likes': '1.5K',
            'comments': '120',
            'shares': '45',
            'isLiked': true,
            'isFollowing': false,
            'isSaved': false,
            'music': 'Gospel Choir · Original Sound',
            'videoBackground': Colors.blue,
          },
          {
            'id': '2',
            'username': 'DivineConnect',
            'userAvatar': '🙏',
            'description': 'Prayer circle with community #Christianity #Prayer #Community',
            'thumbnail': '🕯️',
            'title': 'Community Prayer',
            'likes': '923',
            'comments': '67',
            'shares': '23',
            'isLiked': false,
            'isFollowing': true,
            'isSaved': true,
            'music': 'Original Sound',
            'videoBackground': Colors.green,
          },
          {
            'id': '3',
            'username': 'GospelSinger',
            'userAvatar': '🎵',
            'description': 'Gospel choir performance #Christianity #Gospel #Music',
            'thumbnail': '🎵',
            'title': 'Gospel Choir',
            'likes': '3.2K',
            'comments': '234',
            'shares': '89',
            'isLiked': true,
            'isFollowing': false,
            'isSaved': false,
            'music': 'Amazing Grace · Gospel Choir',
            'videoBackground': Colors.purple,
          },
        ]);
        
      default:
        return _attachUrls([
          {
            'id': '1',
            'username': 'SpiritualSeeker',
            'userAvatar': '🌟',
            'description': 'Universal spiritual practices #Spiritual #Meditation #Peace',
            'thumbnail': '🌟',
            'title': 'Universal Spirituality',
            'likes': '1.1K',
            'comments': '78',
            'shares': '29',
            'isLiked': true,
            'isFollowing': false,
            'isSaved': false,
            'music': 'Original Sound',
            'videoBackground': Colors.indigo,
          },
          {
            'id': '2',
            'username': 'DivineConnect',
            'userAvatar': '🙏',
            'description': 'Interfaith harmony #Spiritual #Harmony #Unity',
            'thumbnail': '🕯️',
            'title': 'Interfaith Harmony',
            'likes': '756',
            'comments': '45',
            'shares': '18',
            'isLiked': false,
            'isFollowing': true,
            'isSaved': true,
            'music': 'Original Sound',
            'videoBackground': Colors.teal,
          },
          {
            'id': '3',
            'username': 'PeacefulSoul',
            'userAvatar': '🕊️',
            'description': 'Mindfulness and meditation #Spiritual #Mindfulness #Meditation',
            'thumbnail': '🕊️',
            'title': 'Mindfulness Practice',
            'likes': '1.2K',
            'comments': '92',
            'shares': '38',
            'isLiked': true,
            'isFollowing': false,
            'isSaved': false,
            'music': 'Original Sound',
            'videoBackground': Colors.cyan,
          },
        ]);
    }
  }

  List<Map<String, dynamic>> _getStoriesForReligion(String religion) {
    switch (religion.toLowerCase()) {
      case 'hinduism':
        return [
          {'id': '1', 'username': 'TejasviSen', 'avatar': '👩', 'hasNewStory': true, 'videoIndex': 0},
          {'id': '2', 'username': 'TempleDevotee', 'avatar': '🕉️', 'hasNewStory': true, 'videoIndex': 1},
          {'id': '3', 'username': 'DivineConnect', 'avatar': '🙏', 'hasNewStory': false, 'videoIndex': 2},
          {'id': '4', 'username': 'GangaBhakti', 'avatar': '🌊', 'hasNewStory': true, 'videoIndex': 0},
        ];
      default:
        return [
          {'id': '1', 'username': 'SpiritualSeeker', 'avatar': '🌟', 'hasNewStory': true, 'videoIndex': 0},
          {'id': '2', 'username': 'DivineConnect', 'avatar': '🙏', 'hasNewStory': false, 'videoIndex': 1},
          {'id': '3', 'username': 'UniversalLove', 'avatar': '💫', 'hasNewStory': true, 'videoIndex': 2},
        ];
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Row(
          children: [
            // Left Sidebar - Stories and Reels
            Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Add story button
                    _buildStoryItem(
                      avatar: '+',
                      username: 'Add',
                      hasNewStory: false,
                      isAddButton: true,
                      onTap: _showAddStoryDialog,
                    ),
                    const SizedBox(height: 20),
                    // Stories list
                    ...stories.map((story) => _buildStoryItem(
                      avatar: story['avatar'],
                      username: story['username'],
                      hasNewStory: story['hasNewStory'],
                      videoIndex: story['videoIndex'],
                      onTap: () => _navigateToVideo(story['videoIndex']),
                    )).toList(),
                    const SizedBox(height: 30),
                    // Reels thumbnails
                    ...videos.asMap().entries.map((entry) {
                      final index = entry.key;
                      final video = entry.value;
                      return _buildReelThumbnail(
                        video: video,
                        index: index,
                        isActive: index == _currentVideoIndex,
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            
            // Main Content Area
            Expanded(
              child: Column(
                children: [
                  // Top Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left corner: Empty space
                        const SizedBox.shrink(),
                        
                        // Right corner: Like and Message icons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.favorite_border,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.chat_bubble_outline,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Main scrolling feed
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      onPageChanged: (index) {
                        setState(() {
                          _currentVideoIndex = index;
                        });
                      },
                      itemCount: videos.length,
                      itemBuilder: (context, index) {
                        final video = videos[index];
                        return _buildVideoCard(video, index);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        height: 60,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey, width: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'Home', true),
            _buildNavItem(Icons.search, 'Search', false),
            _buildNavItem(Icons.add_box_outlined, 'Post', false),
            _buildNavItem(Icons.shopping_bag_outlined, 'Shop', false),
            _buildNavItem(Icons.person_outline, 'Profile', false),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryItem({
    required String avatar,
    required String username,
    required bool hasNewStory,
    bool isAddButton = false,
    int? videoIndex,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: hasNewStory
                    ? Border.all(color: Colors.orange, width: 2)
                    : Border.all(color: Colors.grey, width: 1),
                color: isAddButton ? Colors.grey[800] : Colors.transparent,
              ),
              child: Center(
                child: Text(
                  avatar,
                  style: TextStyle(
                    fontSize: isAddButton ? 20 : 24,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReelThumbnail({
    required Map<String, dynamic> video,
    required int index,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => _navigateToVideo(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isActive
                    ? Border.all(color: Colors.red, width: 2)
                    : Border.all(color: Colors.grey, width: 1),
                color: Colors.grey[800],
              ),
              clipBehavior: Clip.hardEdge,
              child: ReelFrameThumbnail(videoUrl: video['url']),
            ),
            const SizedBox(height: 5),
            Text(
              'Reel ${index + 1}',
              style: TextStyle(
                color: isActive ? Colors.red : Colors.white,
                fontSize: 8,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video, int index) {
    return Stack(
      fit: StackFit.expand,
        children: [
        // Video or YouTube thumbnail fallback (Windows)
        if (video['isYoutube'] == true)
          YouTubePlaceholder(
            videoUrl: video['url'],
            ytId: video['ytId'],
          )
        else
          ReelVideoPlayer(
            videoUrl: video['url'],
            isActive: index == _currentVideoIndex,
          ),
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black54],
                stops: [0.5, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          right: 20,
          bottom: 120,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                _buildActionButton(
                  icon: video['isLiked'] ? Icons.favorite : Icons.favorite_border,
                  label: video['likes'],
                  color: video['isLiked'] ? Colors.red : Colors.white,
                  onTap: () {
                    setState(() {
                      videos[index]['isLiked'] = !videos[index]['isLiked'];
                    });
                  },
                ),
                const SizedBox(height: 20),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: video['comments'],
                onTap: () => _showCommentDialog(context, video),
                ),
                const SizedBox(height: 20),
                _buildActionButton(
                  icon: Icons.send,
                  label: video['shares'],
                onTap: () => _showShareDialog(context, video),
                ),
                const SizedBox(height: 20),
                _buildActionButton(
                  icon: video['isSaved'] ? Icons.bookmark : Icons.bookmark_border,
                  label: 'Save',
                  color: video['isSaved'] ? Colors.yellow : Colors.white,
                  onTap: () {
                    setState(() {
                      videos[index]['isSaved'] = !videos[index]['isSaved'];
                    });
                  },
                ),
                const SizedBox(height: 20),
                _buildFollowButton(
                  isFollowing: video['isFollowing'],
                  onTap: () {
                    setState(() {
                      videos[index]['isFollowing'] = !videos[index]['isFollowing'];
                    });
                  },
                ),
              ],
            ),
          ),
        Positioned(
          bottom: 120,
          left: 20,
          right: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: Text(
                        video['userAvatar'],
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '@${video['username']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        video['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  video['description'],
                style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.music_note, color: Colors.white, size: 16),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        video['music'],
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
    );
  }

  Widget _buildPerformer(String emoji, String name) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 30),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  void _showCommentDialog(BuildContext context, Map<String, dynamic> video) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Comments (${video['comments']})',
            style: const TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      _buildCommentItem('User1', 'Amazing video! 🙏', '2m ago'),
                      _buildCommentItem('User2', 'Beautiful content!', '5m ago'),
                      _buildCommentItem('User3', 'Love this! ❤️', '10m ago'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Comment posted!')),
                        );
                      },
                      icon: const Icon(Icons.send, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommentItem(String username, String comment, String time) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(username[0]),
      ),
      title: Text(
        username,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        comment,
        style: const TextStyle(color: Colors.white70),
      ),
      trailing: Text(
        time,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
    );
  }

  void _showShareDialog(BuildContext context, Map<String, dynamic> video) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Share',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.white),
                title: const Text(
                  'Copy Link',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.white),
                title: const Text(
                  'Share to Social Media',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Shared!')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color color = Colors.white,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowButton({
    required bool isFollowing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isFollowing ? Colors.grey[600] : Colors.red,
        ),
        child: Icon(
          isFollowing ? Icons.check : Icons.add,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isSelected ? Colors.black : Colors.grey,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class ReelVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool isActive;

  const ReelVideoPlayer({super.key, required this.videoUrl, required this.isActive});

  @override
  State<ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<ReelVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isMuted = true;
  bool _isInitialized = false;
  bool _isYouTube = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant ReelVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      _init();
    }
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive && _isInitialized && !_isDisposed) {
        _controller?.play();
      } else {
        _controller?.pause();
      }
    }
  }

  Future<void> _init() async {
    if (_isDisposed) return;
    
    _isYouTube = _isYouTubeUrl(widget.videoUrl);
    
    if (_isYouTube) {
      // For YouTube URLs, we'll show a placeholder since direct playback isn't supported
      if (!_isDisposed) {
        setState(() {
          _isInitialized = true;
        });
      }
      return;
    }

    try {
      final controller = VideoPlayerController.network(
        widget.videoUrl,
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );
      if (_isDisposed) {
        controller.dispose();
        return;
      }
      
      _controller = controller;
      
      await controller.initialize();
      if (_isDisposed) return;
      
      await controller.setLooping(true);
      if (_isMuted) {
        await controller.setVolume(0.0);
      }
      if (widget.isActive) {
        await controller.play();
      }
      
      if (!mounted || _isDisposed) return;
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Video initialization error: $e');
      if (!mounted || _isDisposed) return;
      setState(() {
        _isInitialized = true;
      });
    }
  }

  bool _isYouTubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  void _disposeController() {
    if (_controller != null) {
      _controller!.pause();
      _controller!.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_isYouTube) {
      // Show YouTube placeholder with play button
      return _buildYouTubePlaceholder();
    }

    if (_controller == null) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Icon(Icons.error, color: Colors.white, size: 50),
        ),
      );
    }

    return Stack(
      children: [
        // Video player
        Positioned.fill(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          ),
        ),
        // Tap to play/pause
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              if (_controller!.value.isPlaying) {
                _controller!.pause();
              } else {
                _controller!.play();
              }
              setState(() {});
            },
            child: AnimatedOpacity(
              opacity: _controller!.value.isPlaying ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                color: Colors.black26,
                child: const Center(
                  child: Icon(Icons.play_arrow, color: Colors.white, size: 80),
                ),
              ),
            ),
          ),
        ),
        // Mute toggle
        Positioned(
          right: 16,
          top: 16,
          child: GestureDetector(
            onTap: () async {
              _isMuted = !_isMuted;
              await _controller!.setVolume(_isMuted ? 0.0 : 1.0);
              setState(() {});
            },
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYouTubePlaceholder() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_filled,
              color: Colors.white,
              size: 80,
            ),
            SizedBox(height: 16),
            Text(
              'YouTube Video',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap to open in browser',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lightweight network video thumbnail using first frame.
class ReelFrameThumbnail extends StatefulWidget {
  final String videoUrl;
  const ReelFrameThumbnail({super.key, required this.videoUrl});

  @override
  State<ReelFrameThumbnail> createState() => _ReelFrameThumbnailState();
}

class _ReelFrameThumbnailState extends State<ReelFrameThumbnail> {
  bool _isYouTube = false;
  String? _ytId;

  @override
  void initState() {
    super.initState();
    _checkUrlType();
  }

  void _checkUrlType() {
    _isYouTube = _isYouTubeUrl(widget.videoUrl);
    if (_isYouTube) {
      _ytId = _extractYouTubeId(widget.videoUrl);
    }
  }

  bool _isYouTubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  String? _extractYouTubeId(String url) {
    final shorts = RegExp(r'youtube\.com/shorts/([A-Za-z0-9_-]{5,})');
    final m1 = shorts.firstMatch(url);
    if (m1 != null) return m1.group(1);
    
    final watch = RegExp(r'[?&]v=([A-Za-z0-9_-]{5,})');
    final m2 = watch.firstMatch(url);
    if (m2 != null) return m2.group(1);
    
    final short = RegExp(r'youtu\.be/([A-Za-z0-9_-]{5,})');
    final m3 = short.firstMatch(url);
    return m3?.group(1);
  }

  @override
  Widget build(BuildContext context) {
    if (_isYouTube && _ytId != null) {
      // Show YouTube thumbnail
      return ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Image.network(
          'https://img.youtube.com/vi/$_ytId/hqdefault.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey[800],
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
          ),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[800],
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            );
          },
        ),
      );
    }

    // For non-YouTube URLs, show a simple placeholder
    return Container(
      color: Colors.grey[800],
      child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
    );
  }
}

// Lightweight placeholder for YouTube on Windows (no WebView embed here).
class YouTubePlaceholder extends StatelessWidget {
  final String videoUrl;
  final String? ytId;
  const YouTubePlaceholder({super.key, required this.videoUrl, this.ytId});

  String _thumbUrl(String? id) {
    if (id == null) return '';
    return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          _thumbUrl(ytId),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
          loadingBuilder: (c, w, p) => const ColoredBox(color: Colors.black),
        ),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, size: 48, color: Colors.white),
          ),
        ),
      ],
    );
  }
}