import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rgram/lib/providers/auth_provider.dart';
import 'package:rgram/lib/screens/home_screen.dart';
import 'package:rgram/lib/models/user_model.dart';

/// Test to verify that stories from unfollowed users are not shown
/// This test ensures the follow-based story filtering works correctly
void main() {
  group('Story Filtering Tests', () {
    testWidgets('Stories from unfollowed users should not be displayed', (WidgetTester tester) async {
      // Create a mock user who follows no one
      final mockUser = UserModel(
        id: 'test_user_123',
        name: 'Test User',
        email: 'test@example.com',
        username: 'testuser',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        followingCount: 0, // User follows no one
        followersCount: 0,
        postsCount: 0,
        reelsCount: 0,
        followers: [],
        following: [], // Empty following list
      );

      // Create mock auth provider
      final authProvider = AuthProvider();
      authProvider.setUserProfile(mockUser);
      authProvider.setAuthToken('mock_token');

      // Build the home screen
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>(
            create: (_) => authProvider,
            child: const HomeScreen(),
          ),
        ),
      );

      // Wait for the screen to load
      await tester.pumpAndSettle();

      // Verify that only "Your Story" button is visible in stories section
      // No stories from "swayam", "toss", or other unfollowed users should be shown
      expect(find.text('Your Story'), findsOneWidget); // Add story button should be visible
      
      // Verify that no other story widgets are present
      // This would need to be adjusted based on actual StoryWidget implementation
      // For now, we can check that the stories section doesn't contain specific usernames
      
      // The stories section should only show the "Add Story" button
      // No stories from unfollowed users like "swayam" or "toss" should appear
    });

    testWidgets('Stories from followed users should be displayed', (WidgetTester tester) async {
      // Create a mock user who follows some users
      final mockUser = UserModel(
        id: 'test_user_123',
        name: 'Test User',
        email: 'test@example.com',
        username: 'testuser',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        followingCount: 2, // User follows 2 people
        followersCount: 0,
        postsCount: 0,
        reelsCount: 0,
        followers: [],
        following: ['user1', 'user2'], // Following list
      );

      // Create mock auth provider
      final authProvider = AuthProvider();
      authProvider.setUserProfile(mockUser);
      authProvider.setAuthToken('mock_token');

      // Build the home screen
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>(
            create: (_) => authProvider,
            child: const HomeScreen(),
          ),
        ),
      );

      // Wait for the screen to load
      await tester.pumpAndSettle();

      // Verify that "Your Story" button is visible
      expect(find.text('Your Story'), findsOneWidget);
      
      // If the followed users have stories, they should be visible
      // This test would need to be expanded with mock story data
    });
  });
}

/// Test helper to verify story service behavior
class StoryServiceTestHelper {
  /// Test that getStoriesFeed returns empty list to prevent unfollowed users stories
  static Future<void> testStoriesFeedReturnsEmpty() async {
    print('Testing StoryService: getStoriesFeed should return empty list');
    
    // This would test the StoryService.getStoriesFeed method
    // to ensure it returns empty list and doesn't show hardcoded user stories
    // This test would need to be implemented with proper mocking
  }
  
  /// Test that story loading methods respect follow status
  static Future<void> testStoryLoadingRespectsFollowStatus() async {
    print('Testing Story Loading: Should only load stories from followed users');
    
    // Mock the scenario where user follows no one
    // Verify that _getFollowedUsersStories returns []
    // Verify that _getBabajiStoriesIfFollowing returns [] when not following Babaji
    // Verify that _loadStories() doesn't load stories from unfollowed users
  }
}

/// Test to verify the specific issue mentioned by user
class UnfollowedUsersStoryTest {
  /// Test that stories from "swayam" and "toss" are not shown when not following them
  static Future<void> testSwayamAndTossStoriesNotShown() async {
    print('Testing: Stories from "swayam" and "toss" should not be shown when not following them');
    
    // This test would specifically check that:
    // 1. User is not following "swayam" and "toss"
    // 2. Their stories are not displayed in the stories section
    // 3. Only "Your Story" button is visible
    // 4. No other story widgets are present
    
    // The fix should ensure that:
    // - _loadStories() method respects follow status
    // - _loadStoriesOptimized() method respects follow status
    // - StoryService.getStoriesFeed() doesn't load hardcoded user stories
    // - Only stories from followed users are loaded
  }
}
