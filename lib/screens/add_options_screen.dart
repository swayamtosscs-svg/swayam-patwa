import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'story_upload_screen.dart';
import 'post_upload_screen.dart';
import 'reel_upload_screen.dart';
import 'baba_page_creation_screen.dart';

class AddOptionsScreen extends StatelessWidget {
  const AddOptionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Content',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Get screen dimensions for responsive design
            final screenHeight = constraints.maxHeight;
            final isSmallScreen = screenHeight < 600;
            
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: isSmallScreen ? 16.0 : 24.0,
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: isSmallScreen ? 20 : 40),
                      
                      // Header text
                      Text(
                        'What would you like to create?',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A1A),
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      
                      Text(
                        'Choose from the options below to share your spiritual journey',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: const Color(0xFF666666),
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: isSmallScreen ? 30 : 60),
                      
                      // Upload Story Option
                      _buildOptionCard(
                        context,
                        icon: Icons.auto_stories,
                        title: 'Upload Story',
                        subtitle: 'Share a moment from your spiritual journey',
                        color: const Color(0xFF6366F1),
                        onTap: () => _navigateToStoryUpload(context),
                        isCompact: isSmallScreen,
                      ),
                      
                      SizedBox(height: isSmallScreen ? 16 : 24),
                      
                      // Add Post Option
                      _buildOptionCard(
                        context,
                        icon: Icons.grid_on,
                        title: 'Add Post',
                        subtitle: 'Share an image or thought with your community',
                        color: const Color(0xFF10B981),
                        onTap: () => _navigateToPostUpload(context),
                        isCompact: isSmallScreen,
                      ),
                      
                      SizedBox(height: isSmallScreen ? 16 : 24),
                      
                      // Add Reel Option
                      _buildOptionCard(
                        context,
                        icon: Icons.play_circle_outline,
                        title: 'Add Reel',
                        subtitle: 'Create a short video to inspire others',
                        color: const Color(0xFFF59E0B),
                        onTap: () => _navigateToReelUpload(context),
                        isCompact: isSmallScreen,
                      ),
                      
                      SizedBox(height: isSmallScreen ? 16 : 24),
                      
                      // Create Baba Ji Page Option
                      _buildOptionCard(
                        context,
                        icon: Icons.self_improvement,
                        title: 'Create Baba Ji Page',
                        subtitle: 'Create a spiritual page for a spiritual leader',
                        color: const Color(0xFF8B5CF6),
                        onTap: () => _navigateToBabaPageCreation(context),
                        isCompact: isSmallScreen,
                      ),
                      
                      SizedBox(height: isSmallScreen ? 30 : 60),
                      
                      // Footer text
                      Text(
                        'All content will be shared with your spiritual community',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: const Color(0xFF999999),
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: isSmallScreen ? 16 : 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isCompact = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isCompact ? 16 : 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: isCompact ? 50 : 60,
              height: isCompact ? 50 : 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: isCompact ? 24 : 28,
              ),
            ),
            
            SizedBox(width: isCompact ? 16 : 20),
            
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isCompact ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isCompact ? 2 : 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isCompact ? 12 : 14,
                      color: const Color(0xFF666666),
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Arrow icon
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: isCompact ? 14 : 16,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToStoryUpload(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.authToken != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StoryUploadScreen(
            token: authProvider.authToken!,
          ),
        ),
      );
    } else {
      _showErrorSnackBar(context, 'Please login to upload stories');
    }
  }

  void _navigateToPostUpload(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.authToken != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostUploadScreen(
            token: authProvider.authToken!,
          ),
        ),
      );
    } else {
      _showErrorSnackBar(context, 'Please login to create posts');
    }
  }

  void _navigateToReelUpload(BuildContext context) {
    print('AddOptionsScreen: Navigating to reel upload');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.authToken != null) {
      print('AddOptionsScreen: Auth token exists, navigating...');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ReelUploadScreen(),
        ),
      ).then((_) {
        print('AddOptionsScreen: Returned from reel upload screen');
      });
    } else {
      print('AddOptionsScreen: No auth token, showing error');
      _showErrorSnackBar(context, 'Please login to upload reels');
    }
  }

  void _navigateToBabaPageCreation(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.authToken != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const BabaPageCreationScreen(),
        ),
      );
    } else {
      _showErrorSnackBar(context, 'Please login to create Baba Ji pages');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
