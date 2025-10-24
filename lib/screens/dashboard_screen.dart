import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'baba_pages_screen.dart';
import '../profile_ui.dart';
import 'live_stream_screen.dart';
import '../widgets/app_loader.dart';

class DashboardScreen extends StatefulWidget {
  DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTabIndex = 0;
  
  // Example static video URLs for each religion (using sample videos)
  final Map<String, List<Map<String, String>>> religionVideos = {
    'Hinduism': [
      {
        'title': 'Bhagavad Gita Explained',
        'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        'description': 'Learn about the sacred Hindu scripture',
        'likes': '1.2K',
        'comments': '234',
      },
      {
        'title': 'Hinduism Documentary',
        'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
        'description': 'Explore the rich history of Hinduism',
        'likes': '856',
        'comments': '123',
      },
      {
        'title': 'Vedic Chants',
        'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
        'description': 'Ancient Vedic mantras and chants',
        'likes': '2.1K',
        'comments': '445',
      },
    ],
    'Christianity': [
      {
        'title': 'The Story of Jesus',
        'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
        'description': 'The life and teachings of Jesus Christ',
        'likes': '1.8K',
        'comments': '312',
      },
      {
        'title': 'Christianity Explained',
        'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
        'description': 'Understanding Christian faith and practices',
        'likes': '945',
        'comments': '167',
      },
    ],
    'Islam': [
      {
        'title': 'What is Islam?',
        'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
        'description': 'Introduction to Islamic faith and culture',
        'likes': '1.5K',
        'comments': '289',
      },
      {
        'title': 'Islamic History',
        'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
        'description': 'The historical development of Islam',
        'likes': '1.1K',
        'comments': '198',
      },
    ],
    'Buddhism': [
      {
        'title': 'Buddha Documentary',
        'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4',
        'description': 'The life and teachings of Buddha',
        'likes': '1.3K',
        'comments': '245',
      },
    ],
    'Sikhism': [
      {
        'title': 'Sikhism Basics',
        'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMobsters.mp4',
        'description': 'Understanding Sikh faith and traditions',
        'likes': '876',
        'comments': '134',
      },
    ],
    'Judaism': [
      {
        'title': 'Judaism Explained',
        'url': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerScenes.mp4',
        'description': 'Introduction to Jewish faith and culture',
        'likes': '1.0K',
        'comments': '178',
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    final String selectedReligion =
        ModalRoute.of(context)?.settings.arguments as String? ?? 'Hinduism';
    final videos = religionVideos[selectedReligion] ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'rupesh@toss.in',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Profile Header Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Profile Picture
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.purple, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 38,
                        backgroundColor: Colors.grey[200],
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Statistics
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn('${videos.length}', 'Posts'),
                          _buildStatColumn('1,018', 'Followers'),
                          _buildStatColumn('712', 'Following'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Name and Bio
                const Text(
                  'Rupesh',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Spiritual content creator • $selectedReligion',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Followed by spiritual_guide and faith_community',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {},
                        child: const Text(
                          'Follow',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {},
                        child: const Text('Message'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_add, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Tab Bar
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTab(0, Icons.grid_on, ''),
                ),
                Expanded(
                  child: _buildTab(1, Icons.person_pin, ''),
                ),
              ],
            ),
          ),
          // Content Area
          Expanded(
            child: _selectedTabIndex == 0
                ? _buildVideoGrid(videos)
                : _buildTaggedContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildTab(int index, IconData icon, String label) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.black : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.black : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildVideoGrid(List<Map<String, String>> videos) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        childAspectRatio: 1,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return GestureDetector(
          onTap: () {
            _showVideoModal(context, video);
          },
          child: Container(
            color: Colors.grey[200],
            child: Stack(
              children: [
                VideoPlayerWidget(videoUrl: video['url']!),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaggedContent() {
    return const Center(
      child: Text(
        'No tagged content',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  void _showVideoModal(BuildContext context, Map<String, String> video) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Video player
            AspectRatio(
              aspectRatio: 16 / 9,
              child: VideoPlayerWidget(videoUrl: video['url']!),
            ),
            // Video info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video['title']!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    video['description']!,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.red[400]),
                      const SizedBox(width: 8),
                      Text(video['likes']!),
                      const SizedBox(width: 16),
                      const Icon(Icons.comment, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(video['comments']!),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() async {
    _controller = VideoPlayerController.network(
      widget.videoUrl,
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: false,
      ),
    );
    try {
      await _controller!.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              const Text(
                'Loading video...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        VideoPlayer(_controller!),
        FloatingActionButton(
          onPressed: () {
            setState(() {
              _controller!.value.isPlaying
                  ? _controller!.pause()
                  : _controller!.play();
            });
          },
          child: Icon(
            _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
          ),
        ),
      ],
    );
  }
}