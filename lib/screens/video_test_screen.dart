import 'package:flutter/material.dart';
import '../widgets/video_player_widget.dart';

class VideoTestScreen extends StatelessWidget {
  const VideoTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const testVideoUrl = 'http://103.14.120.163:8081/uploads/users/68c98967a921a001da9787b3/stories/68c98967a921a001da9787b3_1758711452094_negrlwpom_RGRAM_App_Video_Generation.mp4';
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Video Test'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: VideoPlayerWidget(
          videoUrl: testVideoUrl,
          autoPlay: true,
          looping: true,
          muted: false,
        ),
      ),
    );
  }
}
