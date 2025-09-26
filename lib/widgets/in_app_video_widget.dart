import 'package:flutter/material.dart';
import 'video_player_widget.dart';
import '../models/baba_page_reel_model.dart';
import '../utils/app_theme.dart';

class InAppVideoWidget extends StatefulWidget {
  final BabaPageReel reel;
  final bool autoplay;
  final VoidCallback? onTap;
  final bool showFullDetails;

  const InAppVideoWidget({
    super.key,
    required this.reel,
    this.autoplay = false,
    this.onTap,
    this.showFullDetails = false,
  });

  @override
  State<InAppVideoWidget> createState() => _InAppVideoWidgetState();
}

class _InAppVideoWidgetState extends State<InAppVideoWidget> {
  bool _isPlaying = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ?? () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AspectRatio(
          aspectRatio: 9 / 16, // Vertical video aspect ratio
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video Player
              VideoPlayerWidget(
                videoUrl: widget.reel.video.url,
                autoPlay: widget.autoplay,
                looping: true,
                muted: false, // Always start unmuted (audio on)
                showControls: true, // Show video controls
              ),

              // No play button overlay needed - videos auto-play and tap handles mute/unmute

              // Caption at top
              if (_showControls)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.reel.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

            ],
          ),
        ),
      ),
    );
  }
}