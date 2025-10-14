import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
import '../models/baba_page_reel_model.dart';
import '../utils/app_theme.dart';
import '../screens/fullscreen_reel_viewer_screen.dart';

class SimpleVideoWidget extends StatefulWidget {
  final BabaPageReel reel;
  final bool showFullDetails;
  final VoidCallback? onTap;

  const SimpleVideoWidget({
    Key? key,
    required this.reel,
    this.showFullDetails = true,
    this.onTap,
  }) : super(key: key);

  @override
  State<SimpleVideoWidget> createState() => _SimpleVideoWidgetState();
}

class _SimpleVideoWidgetState extends State<SimpleVideoWidget> {
  bool _isHovered = false;

  void _openFullScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenReelViewerScreen(
          reel: widget.reel,
        ),
      ),
    );
  }

  void _openInBrowser() async {
    try {
      final url = Uri.parse(widget.reel.video.url);
      // if (await canLaunchUrl(url)) {
        // await launchUrl(url, mode: LaunchMode.externalApplication);
      // } else {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text('Could not open video in browser'),
      //       backgroundColor: AppTheme.errorColor,
      //     ),
      //   );
      // }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening video: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ?? _openFullScreen,
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 9 / 16, // Vertical video aspect ratio
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Video Thumbnail
                Image.network(
                  widget.reel.thumbnail.url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey.shade300,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(
                          Icons.video_library,
                          color: Colors.grey,
                          size: 50,
                        ),
                      ),
                    );
                  },
                ),


                // Video Info Overlay
                if (widget.showFullDetails) ...[
                  // Top gradient
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom gradient
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Title
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Text(
                      widget.reel.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Stats
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Row(
                      children: [
                        _buildStatItem(Icons.visibility, widget.reel.viewsCount),
                        const SizedBox(width: 16),
                        _buildStatItem(Icons.favorite, widget.reel.likesCount),
                        const SizedBox(width: 16),
                        _buildStatItem(Icons.comment, widget.reel.commentsCount),
                        const Spacer(),
                        // Open in browser button
                        GestureDetector(
                          onTap: _openInBrowser,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.open_in_browser,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.white,
        ),
        const SizedBox(width: 4),
        Text(
          _formatCount(count),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
}



