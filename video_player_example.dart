import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize media_kit
  MediaKit.ensureInitialized();
  
  runApp(const VideoPlayerExampleApp());
}

class VideoPlayerExampleApp extends StatelessWidget {
  const VideoPlayerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Kit Video Player Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const VideoPlayerExampleScreen(),
    );
  }
}

class VideoPlayerExampleScreen extends StatefulWidget {
  const VideoPlayerExampleScreen({super.key});

  @override
  State<VideoPlayerExampleScreen> createState() => _VideoPlayerExampleScreenState();
}

class _VideoPlayerExampleScreenState extends State<VideoPlayerExampleScreen> {
  late final Player player;
  late final VideoController videoController;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Your test video URL
  final String testVideoUrl = 'http://103.14.120.163:8081/uploads/users/68c98967a921a001da9787b3/stories/68c98967a921a001da9787b3_1758711452094_negrlwpom_RGRAM_App_Video_Generation.mp4';

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      print('Initializing media_kit player: $testVideoUrl');
      
      // Initialize player
      player = Player();
      videoController = VideoController(player);

      // Set up player event listeners
      player.stream.error.listen((error) {
        print('Player error: $error');
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Player error: $error';
          });
        }
      });

      player.stream.buffering.listen((buffering) {
        print('Buffering: $buffering');
      });

      player.stream.playing.listen((playing) {
        print('Playing: $playing');
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _hasError = false;
          });
        }
      });

      player.stream.completed.listen((completed) {
        print('Video completed');
        if (mounted) {
          // Restart the video when it completes
          player.seek(Duration.zero);
          player.play();
        }
      });

      // Load the video
      await player.open(Media(testVideoUrl));

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });

        // Auto-play the video
        print('Starting autoplay...');
        await player.play();
      }
    } catch (e) {
      print('Error initializing player: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Error initializing player: $e';
        });
      }
    }
  }

  void _togglePlayPause() {
    if (player.state.playing) {
      player.pause();
    } else {
      player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Media Kit Video Player'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(player.state.playing ? Icons.pause : Icons.play_arrow),
            onPressed: _togglePlayPause,
          ),
        ],
      ),
      body: _hasError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading video',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                        _isInitialized = false;
                        _errorMessage = '';
                      });
                      _initializePlayer();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : !_isInitialized
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : GestureDetector(
                  onTap: _togglePlayPause,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Video Player
                      Video(
                        controller: videoController,
                        controls: AdaptiveVideoControls,
                      ),
                      
                      // Play/Pause overlay - only show when not playing
                      if (!player.state.playing)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 60,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
