# Follow Request System Implementation

## Overview
This document describes the complete implementation of the follow request system for private accounts in the R-Gram app. The system allows users to send follow requests to private accounts, which can then be accepted or rejected by the account owner.

## Key Features

### 1. Private Account Detection
- The system automatically detects if a user account is private
- Privacy status is checked both from the widget parameter and by querying the privacy service
- Private accounts require follow requests before users can follow them

### 2. Follow Request Flow
1. **Send Request**: When a user tries to follow a private account, a follow request is sent
2. **Pending State**: The request appears in the "Sent" tab for the requester and "Pending" tab for the account owner
3. **Accept/Reject**: The account owner can accept or reject the request
4. **Following**: Once accepted, the user appears in the following list

### 3. UI Components

#### FollowButton Widget
- **Location**: `lib/widgets/follow_button.dart`
- **Features**:
  - Automatically detects private accounts
  - Shows different states: "Follow", "Requested", "Following"
  - Handles both public and private account following
  - Provides visual feedback for all actions

#### Follow Requests Screen
- **Location**: `lib/screens/follow_requests_screen.dart`
- **Features**:
  - Shows pending requests (received)
  - Shows sent requests
  - Accept/Reject functionality
  - Cancel request functionality

## Implementation Details

### Files Modified

#### 1. FollowButton Widget (`lib/widgets/follow_button.dart`)
```dart
// Key changes:
- Added privacy service import
- Added _isPrivateAccount state variable
- Added _checkAccountPrivacy() method
- Updated follow logic to handle private accounts
- Improved error handling and user feedback
```

#### 2. User Profile Screen (`lib/screens/user_profile_screen.dart`)
```dart
// Key changes:
- Updated FollowButton to use widget.isPrivate instead of hardcoded false
- Properly passes privacy status from widget parameters
```

#### 3. Profile Screen (`lib/screens/profile_screen.dart`)
```dart
// Key changes:
- Updated UserProfileScreen navigation to pass post.isPrivate
- Ensures privacy status is properly propagated
```

#### 4. Post Model (`lib/models/post_model.dart`)
```dart
// Key changes:
- Added isPrivate field to Post class
- Updated constructor, fromJson, toJson, and copyWith methods
- Ensures privacy information is available throughout the app
```

#### 5. Discover Users Screen (`lib/screens/discover_users_screen.dart`)
```dart
// Key changes:
- Replaced custom follow button with FollowButton widget
- Added private user to sample data for testing
- Removed redundant follow logic
- Improved consistency across the app
```

### API Endpoints Used

#### Follow Request Service (`lib/services/follow_request_service.dart`)
- `POST /api/follow-request/{userId}` - Send follow request
- `GET /api/follow-requests` - Get pending requests
- `GET /api/follow-requests/sent` - Get sent requests
- `PUT /api/follow-request/{requestId}` - Accept/Reject request
- `DELETE /api/follow-requests/{requestId}` - Cancel request

#### Privacy Service (`lib/services/privacy_service.dart`)
- `GET /api/privacy/{userId}` - Get user privacy settings

## Usage Examples

### 1. Following a Public Account
```dart
FollowButton(
  targetUserId: 'public_user_id',
  targetUserName: 'Public User',
  isPrivate: false,
  isFollowing: false,
  onFollowChanged: () {
    // Handle follow state change
  },
)
```

### 2. Following a Private Account
```dart
FollowButton(
  targetUserId: 'rupesh_private',
  targetUserName: 'Rupesh Private',
  isPrivate: true,
  isFollowing: false,
  onFollowChanged: () {
    // Handle follow state change
  },
)
```

### 3. Checking Follow Request Status
```dart
// Check if there's a pending request
final hasRequest = await FollowRequestService.hasPendingRequest('user_id');

// Get pending requests
final pendingRequests = await FollowRequestService.getPendingRequests();

// Get sent requests
final sentRequests = await FollowRequestService.getSentRequests();
```

## Testing

### Test File
- **Location**: `test_follow_request_system.dart`
- **Coverage**: 
  - Widget tests for FollowButton
  - Service tests for FollowRequestService
  - Privacy service tests
  - Model tests for FollowRequest
  - Integration tests for complete flow

### Manual Testing Steps
1. **Set up private account**: Create a user account and set it to private
2. **Send follow request**: Try to follow the private account from another user
3. **Check requests**: Verify the request appears in both "Sent" and "Pending" tabs
4. **Accept request**: Accept the request from the private account owner
5. **Verify following**: Check that the user now appears in the following list

## Error Handling

### Common Scenarios
1. **Network errors**: Graceful fallback with user-friendly messages
2. **Invalid requests**: Proper validation and error reporting
3. **Permission errors**: Clear messaging about access restrictions
4. **State conflicts**: Proper state management and synchronization

### User Feedback
- Loading states during API calls
- Success/error messages for all actions
- Visual indicators for different button states
- Toast notifications for important actions

## Future Enhancements

### Potential Improvements
1. **Real-time updates**: WebSocket integration for instant request updates
2. **Bulk actions**: Accept/reject multiple requests at once
3. **Request history**: Track all follow request activities
4. **Custom messages**: Allow users to add messages with follow requests
5. **Auto-accept rules**: Allow users to set automatic acceptance criteria

### Performance Optimizations
1. **Caching**: Cache privacy settings and follow states
2. **Pagination**: Implement pagination for large request lists
3. **Background sync**: Sync follow states in the background
4. **Offline support**: Handle offline scenarios gracefully

## Troubleshooting

### Common Issues

#### 1. Follow Button Not Showing Correct State
- **Cause**: Privacy service not returning correct data
- **Solution**: Check API endpoint and ensure proper authentication

#### 2. Follow Requests Not Appearing
- **Cause**: API endpoint issues or authentication problems
- **Solution**: Verify API endpoints and token validity

#### 3. Accept/Reject Not Working
- **Cause**: Incorrect request ID or API issues
- **Solution**: Check request ID format and API response

### Debug Steps
1. Check console logs for API responses
2. Verify authentication token is valid
3. Test API endpoints directly
4. Check network connectivity
5. Verify user permissions

## Conclusion

The follow request system is now fully implemented and provides a complete solution for handling private accounts. The system is robust, user-friendly, and follows best practices for mobile app development. Users can now properly interact with private accounts through the follow request mechanism, ensuring privacy and control over who can follow them.

The implementation is modular, testable, and maintainable, making it easy to extend and improve in the future.
