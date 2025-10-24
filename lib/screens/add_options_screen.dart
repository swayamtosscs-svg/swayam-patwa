import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../providers/auth_provider.dart';
import 'story_upload_screen.dart';
import 'post_upload_screen.dart';
import 'reel_upload_screen.dart';
import 'baba_page_creation_screen.dart';
import 'live_stream_screen.dart';

class AddOptionsScreen extends StatelessWidget {
  const AddOptionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Navigate back to home screen using bottom navigation
            // Find the GlobalNavigationWrapper and navigate to home
            final navigator = Navigator.of(context);
            navigator.pushNamedAndRemoveUntil('/home', (route) => false);
          },
        ),
        title: const Text(
          'Create Content',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Signup page bg.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Blur effect overlay
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
              child: Container(
                color: Colors.transparent,
              ),
            ),
            SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Get screen dimensions for responsive design
            final screenHeight = constraints.maxHeight;
            final isSmallScreen = screenHeight < 600;
            
            return Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: isSmallScreen ? 16.0 : 24.0,
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: isSmallScreen ? 10 : 20),
                        
                        // Header text
                        Text(
                          'What would you like to create?',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 18 : 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        
                        Text(
                          'Choose from the options below to share your spiritual journey',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            color: Colors.black,
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: isSmallScreen ? 20 : 30),
                        
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
                        
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        
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
                        
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        
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
                        
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        
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
                        
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        
                        // Live Stream Option
                        _buildOptionCard(
                          context,
                          icon: Icons.videocam,
                          title: 'Live Stream',
                          subtitle: 'Start a live spiritual session or darshan',
                          color: const Color(0xFFEF4444),
                          onTap: () => _navigateToLiveStream(context),
                          isCompact: isSmallScreen,
                        ),
                        
                        SizedBox(height: isSmallScreen ? 8 : 12),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
            ),
          ],
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
        padding: EdgeInsets.all(isCompact ? 8 : 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: isCompact ? 40 : 50,
              height: isCompact ? 40 : 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: isCompact ? 20 : 24,
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

  void _navigateToLiveStream(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.authToken != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LiveStreamScreen(),
        ),
      );
    } else {
      _showErrorSnackBar(context, 'Please login to start live streaming');
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
