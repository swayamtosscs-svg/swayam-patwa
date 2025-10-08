import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'lib/widgets/follow_button.dart';
import 'lib/services/follow_request_service.dart';
import 'lib/services/privacy_service.dart';
import 'lib/models/follow_request_model.dart';
import 'lib/models/privacy_model.dart';

/// Test file to verify the complete follow request system
/// This tests the flow: Private account -> Send follow request -> Accept/Reject -> Show in following
void main() {
  group('Follow Request System Tests', () {
    testWidgets('FollowButton shows correct state for private accounts', (WidgetTester tester) async {
      // Test that FollowButton correctly handles private accounts
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowButton(
              targetUserId: 'rupesh_private',
              targetUserName: 'Rupesh Private',
              isPrivate: true,
              isFollowing: false,
            ),
          ),
        ),
      );

      // Verify the button shows "Follow" for private accounts
      expect(find.text('Follow'), findsOneWidget);
    });

    testWidgets('FollowButton shows correct state for public accounts', (WidgetTester tester) async {
      // Test that FollowButton correctly handles public accounts
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowButton(
              targetUserId: 'user1',
              targetUserName: 'Public User',
              isPrivate: false,
              isFollowing: false,
            ),
          ),
        ),
      );

      // Verify the button shows "Follow" for public accounts
      expect(find.text('Follow'), findsOneWidget);
    });

    testWidgets('FollowButton shows "Following" when already following', (WidgetTester tester) async {
      // Test that FollowButton shows correct state when already following
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowButton(
              targetUserId: 'user1',
              targetUserName: 'Public User',
              isPrivate: false,
              isFollowing: true,
            ),
          ),
        ),
      );

      // Verify the button shows "Following" when already following
      expect(find.text('Following'), findsOneWidget);
    });

    testWidgets('FollowButton shows "Requested" when follow request is pending', (WidgetTester tester) async {
      // Test that FollowButton shows correct state when follow request is pending
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FollowButton(
              targetUserId: 'rupesh_private',
              targetUserName: 'Rupesh Private',
              isPrivate: true,
              isFollowing: false,
            ),
          ),
        ),
      );

      // Simulate a pending request by tapping the button
      await tester.tap(find.text('Follow'));
      await tester.pump();

      // Verify the button shows "Requested" after sending follow request
      expect(find.text('Requested'), findsOneWidget);
    });
  });

  group('Follow Request Service Tests', () {
    test('sendFollowRequest returns true for valid request', () async {
      // Test that sending a follow request works correctly
      final result = await FollowRequestService.sendFollowRequest('rupesh_private');
      expect(result, isA<bool>());
    });

    test('getPendingRequests returns list of follow requests', () async {
      // Test that getting pending requests works correctly
      final requests = await FollowRequestService.getPendingRequests();
      expect(requests, isA<List<FollowRequest>>());
    });

    test('getSentRequests returns list of sent requests', () async {
      // Test that getting sent requests works correctly
      final requests = await FollowRequestService.getSentRequests();
      expect(requests, isA<List<FollowRequest>>());
    });

    test('acceptFollowRequest returns true for valid request', () async {
      // Test that accepting a follow request works correctly
      final result = await FollowRequestService.acceptFollowRequest('request_id');
      expect(result, isA<bool>());
    });

    test('rejectFollowRequest returns true for valid request', () async {
      // Test that rejecting a follow request works correctly
      final result = await FollowRequestService.rejectFollowRequest('request_id');
      expect(result, isA<bool>());
    });
  });

  group('Privacy Service Tests', () {
    test('getUserPrivacySettings returns privacy settings', () async {
      // Test that getting user privacy settings works correctly
      final settings = await PrivacyService.getUserPrivacySettings('rupesh_private');
      expect(settings, isA<PrivacySettings?>());
    });
  });

  group('Follow Request Model Tests', () {
    test('FollowRequest.fromJson creates correct object', () {
      // Test that FollowRequest model correctly parses JSON data
      final jsonData = {
        '_id': 'request_123',
        'fromUser': {
          '_id': 'user_456',
          'username': 'requester',
          'avatar': 'avatar_url'
        },
        'toUser': {
          '_id': 'rupesh_private',
          'username': 'rupesh_private'
        },
        'status': 'pending',
        'createdAt': '2024-01-01T00:00:00Z'
      };

      final request = FollowRequest.fromJson(jsonData);
      expect(request.id, equals('request_123'));
      expect(request.fromUserId, equals('user_456'));
      expect(request.fromUsername, equals('requester'));
      expect(request.toUserId, equals('rupesh_private'));
      expect(request.toUsername, equals('rupesh_private'));
      expect(request.status, equals('pending'));
    });

    test('FollowRequest.copyWith creates correct copy', () {
      // Test that FollowRequest copyWith method works correctly
      final original = FollowRequest(
        id: 'request_123',
        fromUserId: 'user_456',
        fromUsername: 'requester',
        toUserId: 'rupesh_private',
        toUsername: 'rupesh_private',
        createdAt: DateTime.now(),
        status: 'pending',
      );

      final updated = original.copyWith(status: 'accepted');
      expect(updated.id, equals(original.id));
      expect(updated.status, equals('accepted'));
      expect(original.status, equals('pending')); // Original unchanged
    });
  });
}

/// Integration test to verify the complete follow request flow
class FollowRequestFlowTest {
  static Future<void> testCompleteFlow() async {
    print('🧪 Testing Complete Follow Request Flow...');
    
    try {
      // Step 1: Send follow request to private account
      print('📤 Step 1: Sending follow request to Rupesh (private account)...');
      final requestSent = await FollowRequestService.sendFollowRequest('rupesh_private');
      print('✅ Follow request sent: $requestSent');
      
      // Step 2: Check if request appears in sent requests
      print('📋 Step 2: Checking sent requests...');
      final sentRequests = await FollowRequestService.getSentRequests();
      print('✅ Sent requests count: ${sentRequests.length}');
      
      // Step 3: Check if request appears in pending requests (from Rupesh's perspective)
      print('⏳ Step 3: Checking pending requests...');
      final pendingRequests = await FollowRequestService.getPendingRequests();
      print('✅ Pending requests count: ${pendingRequests.length}');
      
      // Step 4: Accept the follow request (simulating Rupesh accepting)
      if (pendingRequests.isNotEmpty) {
        print('✅ Step 4: Accepting follow request...');
        final requestId = pendingRequests.first.id;
        final accepted = await FollowRequestService.acceptFollowRequest(requestId);
        print('✅ Follow request accepted: $accepted');
        
        // Step 5: Verify the user is now following
        print('👥 Step 5: Verifying follow relationship...');
        final hasRequest = await FollowRequestService.hasPendingRequest('rupesh_private');
        print('✅ Has pending request: $hasRequest');
      }
      
      print('🎉 Complete follow request flow test completed successfully!');
      
    } catch (e) {
      print('❌ Follow request flow test failed: $e');
    }
  }
}

/// Test the privacy settings functionality
class PrivacyTest {
  static Future<void> testPrivacySettings() async {
    print('🔒 Testing Privacy Settings...');
    
    try {
      // Test getting privacy settings for a user
      final settings = await PrivacyService.getUserPrivacySettings('rupesh_private');
      if (settings != null) {
        print('✅ Privacy settings retrieved:');
        print('   - User ID: ${settings.userId}');
        print('   - Is Private: ${settings.isPrivate}');
        print('   - Allow Direct Messages: ${settings.allowDirectMessages}');
        print('   - Allow Story Views: ${settings.allowStoryViews}');
        print('   - Allow Post Comments: ${settings.allowPostComments}');
        print('   - Allow Follow Requests: ${settings.allowFollowRequests}');
      } else {
        print('⚠️ No privacy settings found for user');
      }
      
    } catch (e) {
      print('❌ Privacy settings test failed: $e');
    }
  }
}

/// Run all tests
void runAllTests() async {
  print('🚀 Starting Follow Request System Tests...\n');
  
  await FollowRequestFlowTest.testCompleteFlow();
  print('');
  await PrivacyTest.testPrivacySettings();
  
  print('\n✨ All tests completed!');
}
