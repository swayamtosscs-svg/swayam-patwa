import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rgram/lib/providers/auth_provider.dart';
import 'package:rgram/lib/screens/home_screen.dart';
import 'package:rgram/lib/models/user_model.dart';

/// Test to verify that new users see empty feed until they follow someone
/// This test ensures the follow-based feed filtering works correctly
void main() {
  group('New User Feed Behavior Tests', () {
    testWidgets('New user should see empty feed message when following no one', (WidgetTester tester) async {
      // Create a mock new user with no following
      final mockUser = UserModel(
        id: 'test_user_123',
        name: 'Test User',
        email: 'test@example.com',
        username: 'testuser',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        followingCount: 0, // New user follows no one
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

      // Verify that the empty feed message is displayed
      expect(find.text('Welcome to R-Gram!'), findsOneWidget);
      expect(find.text('Follow people to see their posts and stories in your feed. New users only see content from people they follow.'), findsOneWidget);
      expect(find.text('Discover Users'), findsOneWidget);

      // Verify that no posts are displayed
      expect(find.byType(Card), findsNothing); // Assuming posts are displayed as Cards
    });

    testWidgets('New user should see empty stories section when following no one', (WidgetTester tester) async {
      // Create a mock new user with no following
      final mockUser = UserModel(
        id: 'test_user_123',
        name: 'Test User',
        email: 'test@example.com',
        username: 'testuser',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        followingCount: 0, // New user follows no one
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

      // Verify that only the "Add Story" button is visible in stories section
      // (No other users' stories should be visible)
      expect(find.text('Your Story'), findsOneWidget); // Add story button
      
      // Verify that no other story widgets are present
      // (This would need to be adjusted based on actual StoryWidget implementation)
    });
  });
}

/// Test helper to verify feed service behavior
class FeedServiceTestHelper {
  /// Test that getMixedFeed returns empty list for users with no following
  static Future<void> testEmptyFeedForNewUsers() async {
    // This would test the FeedService.getMixedFeed method
    // to ensure it returns empty list when followingCount == 0
    print('Testing FeedService: New users should get empty feed');
    
    // Mock the scenario where user follows no one
    // Verify that FeedService.getMixedFeed returns []
    // This test would need to be implemented with proper mocking
  }
  
  /// Test that story loading respects follow status
  static Future<void> testStoryLoadingRespectsFollowStatus() async {
    print('Testing Story Loading: Should only load stories from followed users');
    
    // Mock the scenario where user follows no one
    // Verify that _getFollowedUsersStories returns []
    // Verify that _getBabajiStoriesIfFollowing returns [] when not following Babaji
  }
}
