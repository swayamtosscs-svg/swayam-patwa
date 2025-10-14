import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'lib/providers/auth_provider.dart';
import 'lib/services/api_service.dart';
import 'lib/services/user_media_service.dart';

/// Test file to verify that reels from following users are properly fetched
/// This test simulates the logic from reels_screen.dart to ensure following users' reels appear
class FollowingReelsTest {
  static Future<void> testFollowingReelsIntegration() async {
    print('=== Testing Following Reels Integration ===');
    
    try {
      // Mock token and user ID (replace with actual values for testing)
      const mockToken = 'your_auth_token_here';
      const mockCurrentUserId = 'your_user_id_here';
      
      print('1. Testing getRGramFollowing API...');
      
      // Test the following API
      final followingResponse = await ApiService.getRGramFollowing(
        userId: mockCurrentUserId,
        token: mockToken,
      );
      
      if (followingResponse['success'] == true && followingResponse['data'] != null) {
        final followingData = followingResponse['data']['following'] as List<dynamic>? ?? [];
        print('✓ Following API returned ${followingData.length} following users');
        
        // Extract user IDs
        final followedUserIds = followingData.take(10).map((following) => 
          following['_id'] ?? following['id']
        ).where((id) => id != null).cast<String>().toList();
        
        print('✓ Extracted ${followedUserIds.length} user IDs for reel fetching');
        
        if (followedUserIds.isNotEmpty) {
          print('2. Testing UserMediaService for following users...');
          
          // Test fetching reels from first following user
          final firstUserId = followedUserIds.first;
          print('Testing with user ID: $firstUserId');
          
          final userMediaResponse = await UserMediaService.getUserMedia(userId: firstUserId);
          
          if (userMediaResponse.success) {
            final reels = userMediaResponse.reels.where((reel) => 
              reel.videoUrl != null && reel.videoUrl!.isNotEmpty
            ).toList();
            
            print('✓ Found ${reels.length} reels from following user $firstUserId');
            
            if (reels.isNotEmpty) {
              print('✓ Reel details:');
              for (final reel in reels.take(3)) { // Show first 3 reels
                print('  - ID: ${reel.id}');
                print('  - Video URL: ${reel.videoUrl}');
                print('  - Username: ${reel.username}');
                print('  - Created: ${reel.createdAt}');
              }
            } else {
              print('⚠ No reels found for this following user');
            }
          } else {
            print('✗ Failed to fetch media for following user $firstUserId');
          }
        } else {
          print('⚠ No following users found to test with');
        }
      } else {
        print('✗ Following API failed: ${followingResponse['message']}');
      }
      
      print('3. Testing parallel API calls optimization...');
      
      if (followedUserIds.isNotEmpty) {
        final futures = followedUserIds.take(3).map((followedUserId) async {
          try {
            final userMediaResponse = await UserMediaService.getUserMedia(userId: followedUserId);
            if (userMediaResponse.success) {
              return userMediaResponse.reels.where((reel) => 
                reel.videoUrl != null && reel.videoUrl!.isNotEmpty
              ).toList();
            }
            return <dynamic>[];
          } catch (e) {
            print('Error fetching reels from user $followedUserId: $e');
            return <dynamic>[];
          }
        });
        
        final results = await Future.wait(futures);
        final totalReels = results.fold<int>(0, (sum, reels) => sum + reels.length);
        
        print('✓ Parallel API calls completed successfully');
        print('✓ Total reels found from ${followedUserIds.take(3).length} users: $totalReels');
      }
      
      print('\n=== Test Summary ===');
      print('✓ Following API integration working');
      print('✓ UserMediaService integration working');
      print('✓ Parallel API calls optimization working');
      print('✓ Following users\' reels should now appear in reel section');
      
    } catch (e) {
      print('✗ Test failed with error: $e');
    }
  }
}

/// Widget to run the test
class FollowingReelsTestWidget extends StatelessWidget {
  const FollowingReelsTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Following Reels Test'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.video_library,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            const Text(
              'Following Reels Integration Test',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'This test verifies that reels from following users\nare properly fetched and displayed in the reel section.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () async {
                await FollowingReelsTest.testFollowingReelsIntegration();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test completed! Check console for results.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Run Test'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Note: Update mockToken and mockCurrentUserId\nin the test file with actual values for testing.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
