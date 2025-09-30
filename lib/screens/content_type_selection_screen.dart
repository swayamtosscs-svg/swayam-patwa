import 'package:flutter/material.dart';
import 'story_upload_screen.dart';
import 'post_upload_screen.dart';
import 'reel_upload_screen.dart';

class ContentTypeSelectionScreen extends StatelessWidget {
  const ContentTypeSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Content',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'What would you like to create?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Content Type Buttons Row
              Row(
                children: [
                  // Post Button
                  Expanded(
                    child: _buildContentTypeButton(
                      context: context,
                      icon: Icons.tag,
                      title: 'Post',
                      backgroundColor: const Color(0xFFE3F2FD),
                      iconColor: const Color(0xFF1976D2),
                      textColor: const Color(0xFF1976D2),
                      onTap: () => _navigateToPostUpload(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Reel Button
                  Expanded(
                    child: _buildContentTypeButton(
                      context: context,
                      icon: Icons.videocam,
                      title: 'Reel',
                      backgroundColor: const Color(0xFFE8F5E8),
                      iconColor: const Color(0xFF2E7D32),
                      textColor: const Color(0xFF2E7D32),
                      onTap: () => _navigateToReelUpload(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Story Button
                  Expanded(
                    child: _buildContentTypeButton(
                      context: context,
                      icon: Icons.auto_stories,
                      title: 'Story',
                      backgroundColor: const Color(0xFFFFF3E0),
                      iconColor: const Color(0xFFF57C00),
                      textColor: const Color(0xFFF57C00),
                      onTap: () => _navigateToStoryUpload(context),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Description Text
              const Text(
                'Choose the type of content you want to share with your community',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentTypeButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color backgroundColor,
    required Color iconColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 28,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPostUpload(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PostUploadScreen(),
      ),
    );
  }

  void _navigateToReelUpload(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReelUploadScreen(),
      ),
    );
  }

  void _navigateToStoryUpload(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StoryUploadScreen(),
      ),
    );
  }
}
