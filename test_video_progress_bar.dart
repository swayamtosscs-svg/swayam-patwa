import 'package:flutter/material.dart';
import 'lib/widgets/video_player_widget.dart';

void main() {
  runApp(const VideoProgressBarTestApp());
}

class VideoProgressBarTestApp extends StatelessWidget {
  const VideoProgressBarTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Progress Bar Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const VideoProgressBarTestScreen(),
    );
  }
}

class VideoProgressBarTestScreen extends StatefulWidget {
  const VideoProgressBarTestScreen({Key? key}) : super(key: key);

  @override
  State<VideoProgressBarTestScreen> createState() => _VideoProgressBarTestScreenState();
}

class _VideoProgressBarTestScreenState extends State<VideoProgressBarTestScreen> {
  final String testVideoUrl = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Video Progress Bar Test'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Video Progress Bar Test',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'This test verifies that the progress bar appears at the bottom of the video player',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              width: 300,
              height: 400,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: VideoPlayerWidget(
                  videoUrl: testVideoUrl,
                  autoPlay: false,
                  looping: true,
                  muted: false,
                  showControls: true,
                  videoId: 'test_video',
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Features to test:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '• Progress bar should appear at the bottom\n'
              '• Time stamps should show current/total duration\n'
              '• Dragging the slider should seek the video\n'
              '• Progress should update as video plays\n'
              '• Controls should be visible when tapping the video',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
    );
  }
}
