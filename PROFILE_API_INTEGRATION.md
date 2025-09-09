# Profile API Integration for R-Gram

This document describes the implementation of the Profile Retrieval API in the R-Gram Flutter application.

## Overview

The app now integrates with the R-Gram Profile API to retrieve and display user profile information in the Account section.

## API Endpoint

- **Method**: GET
- **URL**: `https://api-rgram1.vercel.app/api/user/profile`
- **Headers**: 
  - `Content-Type: application/json`
  - `Authorization: {token}` (token is sent directly, not as Bearer)

### Profile Update API

- **Method**: PUT
- **URL**: `https://api-rgram1.vercel.app/api/user/update`
- **Headers**: 
  - `Content-Type: application/json`
  - `Authorization: {token}` (token is sent directly, not as Bearer)
- **Body**: JSON with updateable fields
  ```json
  {
    "fullName": "John Doe",
    "bio": "Software developer",
    "religion": "Christianity",
    "website": "https://johndoe.com",
    "location": "New York"
  }
  ```

## API Response Structure

```json
{
  "success": true,
  "message": "Profile retrieved successfully",
  "data": {
    "user": {
      "id": "689598c5f4141d33955a0f29",
      "email": "your@email.com",
      "username": "yourusrname",
      "fullName": "John Doe",
      "avatar": "",
      "bio": "Software developer",
      "website": "https://johndoe.com",
      "location": "New York",
      "religion": "Islam",
      "isPrivate": false,
      "isEmailVerified": false,
      "isVerified": false,
      "followersCount": 0,
      "followingCount": 0,
      "postsCount": 1,
      "reelsCount": 0,
      "createdAt": "2025-08-08T06:27:17.938Z",
      "lastActive": "2025-08-08T06:27:17.938Z"
    }
  }
}
```

### Search Users API

- **Method**: GET
- **URL**: `https://api-rgram1.vercel.app/api/search?q={query}&type=users&page={page}&limit={limit}`
- **Headers**: 
  - `Content-Type: application/json`
  - `Authorization: Bearer {token}` (token is sent as Bearer)
- **Response**: 
  ```json
  {
    "success": true,
    "message": "Users found successfully",
    "data": {
      "users": [
        {
          "_id": "68a6c4e1e1e631754d454b82",
          "username": "dhaniiiii",
          "fullName": "Test User",
          "avatar": "",
          "bio": "",
          "followersCount": 0,
          "followingCount": 0,
          "postsCount": 0
        }
      ],
      "pagination": {
        "currentPage": 1,
        "totalPages": 1,
        "totalResults": 1,
        "hasNextPage": false,
        "hasPrevPage": false
      }
    }
  }
  ```

### Follow/Unfollow API

**Follow User:**
- **Endpoint**: `POST http://api-rgram1.vercel.app/api/follow/{targetUserId}`
- **Method**: POST
- **Headers**: `Authorization: {token}`
- **Response**: `{"success": true, "message": "Successfully followed user"}`

**Unfollow User:**
- **Endpoint**: `DELETE http://api-rgram1.vercel.app/api/follow/{targetUserId}`
- **Method**: DELETE
- **Headers**: `Authorization: {token}`
- **Response**: `{"success": true, "message": "Successfully unfollowed user"}`

**Note**: The unfollow endpoint uses the same URL as follow but with DELETE method instead of POST.

**Following Status Check:**
- **NEW**: Automatically checks if the current user is following the target user when viewing their profile
- **NEW**: Button shows "Following" if already following, "Follow" if not following
- **NEW**: Button state updates automatically after follow/unfollow actions
- **NEW**: Refresh button in profile screen to manually update following status

### Get Following API

- **Method**: GET
- **URL**: `https://api-rgram1.vercel.app/api/following/{userId}`
- **Headers**: 
  - `Content-Type: application/json`
  - `Authorization: {token}` (token is sent directly, not as Bearer)
- **Response**: 
  ```json
  {
    "success": true,
    "message": "Following retrieved",
    "data": {
      "following": [
        {
          "_id": "689994652490bb8f15b58014",
          "username": "johndoe1",
          "fullName": "Updated Name",
          "avatar": ""
        }
      ]
    }
  }
  ```

### Get Followers API

- **Method**: GET
- **URL**: `https://api-rgram1.vercel.app/api/followers/{userId}`
- **Headers**: 
  - `Content-Type: application/json`
  - `Authorization: {token}` (token is sent directly, not as Bearer)
- **Response**: 
  ```json
  {
    "success": true,
    "message": "Followers retrieved",
    "data": {
      "followers": []
    }
  }
  ```

## Implementation Details

### 1. User Model Updates

The `UserModel` class has been updated to include new fields:
- `username`: User's username/handle
- `website`: User's website URL
- `reelsCount`: Number of reels created
- `isPrivate`: Whether the profile is private
- `isEmailVerified`: Email verification status
- `isVerified`: Account verification status

### 2. API Service

The `ApiService` now provides:
- **NEW**: `getRGramProfile()` and `updateRGramProfile()` for profile management
- **NEW**: `likeRGramPost()` for the new POST API endpoint
- **NEW**: `getLikedPosts()` for the new GET API endpoint to retrieve liked posts
- **NEW**: `searchRGramUsers()` for the new GET API endpoint to search users
- **NEW**: `followRGramUser()` and `unfollowRGramUser()` for the new POST/DELETE API endpoints
- **NEW**: `getRGramFollowing()` for the new GET API endpoint to retrieve following users
- **NEW**: `getRGramFollowers()` for the new GET API endpoint to retrieve followers
- Removed old follow/unfollow methods in favor of the new R-Gram API methods

### 3. Auth Provider Updates

The `AuthProvider` now:
- Automatically loads user profile from the API after successful authentication
- Provides methods to refresh profile data
- Falls back to local data if API calls fail
- Handles both new R-Gram API and legacy API formats
- **NEW**: Provides `updateUserProfile()` method to update user profile data
- **NEW**: Provides `likePost()` method to like posts using the R-Gram API
- **NEW**: Provides `getLikedPosts()` method to retrieve user's liked posts
- **NEW**: Provides `searchUsers()` method to search for other users using the R-Gram API
- **NEW**: Provides `followUser()` method to follow users using the R-Gram API
- **NEW**: Provides `unfollowUser()` method to unfollow users using the R-Gram API
- **NEW**: Provides `getFollowingUsers()` method to retrieve list of users that the current user follows
- **NEW**: Provides `getFollowers()` method to retrieve list of users that follow the current user
- **NEW**: Provides `isFollowingUser()` method to check if the current user is following a specific target user

### 4. Profile Screen Enhancements

The profile screen now displays:
- Username with @ symbol
- Website link (if available)
- Email verification status
- Reels count in statistics
- Pull-to-refresh functionality
- Manual refresh button
- Debug information (in debug mode)
- **NEW**: Edit button (pencil icon) that opens profile edit screen

### 5. Profile Edit Screen

**NEW**: A dedicated profile edit screen that allows users to:
- Edit full name, bio, website, location, and religion
- Update profile information using the R-Gram update API
- See real-time validation and error handling
- Get immediate feedback on successful updates

### 6. Search Screen

**NEW**: A dedicated search screen that allows users to:
- Search for other users by username or name
- View search results with user profiles and statistics
- See user statistics (posts, followers, following)
- Navigate to user profiles (future enhancement)

### 7. User Profile Screen

**NEW**: A dedicated user profile screen that allows users to:
- View other users' profiles when clicked from search results
- See user information (name, username, bio, avatar)
- View user statistics (posts, followers, following)
- Browse user posts in a grid layout
- Follow/unfollow users
- Navigate through different content tabs (Posts, Reels, Tagged)

### 8. Following Screen

**NEW**: A dedicated following screen that allows users to:
- View list of users that the current user follows
- See following users' basic information (name, username, avatar)
- Navigate to following users' profiles
- Refresh following list
- Handle empty states and errors gracefully

### 9. Followers Screen

**NEW**: A dedicated followers screen that allows users to:
- View list of users that follow the current user
- **NEW**: View list of users that follow any other user (when accessed from user profiles)
- See followers' basic information (name, username, avatar)
- Navigate to followers' profiles
- Refresh followers list
- Handle empty states and errors gracefully

### 10. Enhanced User Profile Screen

**NEW**: Enhanced user profile screen that now allows users to:
- View other users' profiles when clicked from search results
- See user information (name, username, bio, avatar)
- View user statistics (posts, followers, following)
- **NEW**: Click on followers count to see who follows that user
- **NEW**: Click on following count to see who that user follows
- Browse user posts in a grid layout
- Follow/unfollow users
- Navigate through different content tabs (Posts, Reels, Tagged)

## Usage

### Accessing Profile Data

1. **Navigate to Account**: Tap the Account button in the bottom navigation
2. **View Profile**: All user data from the API is automatically displayed
3. **Refresh Data**: 
   - Pull down to refresh
   - Tap the refresh button in the app bar

### Editing Profile Data

1. **Open Edit Screen**: Tap the pencil (edit) icon in the profile screen
2. **Modify Fields**: Update any of the editable fields:
   - Full Name (required)
   - Bio
   - Website
   - Location
   - Religion (required)
3. **Save Changes**: Tap the Save button to update the profile
4. **View Updates**: Return to profile screen to see updated information

### Profile Edit Screen Features

- **Form Validation**: Required fields are validated before submission
- **Real-time Updates**: Profile data is immediately updated after successful save
- **Error Handling**: Clear error messages for failed updates
- **Loading States**: Visual feedback during API calls
- **Navigation**: Seamless navigation between edit and view modes

### Refreshing Profile Data

```dart
final authProvider = Provider.of<AuthProvider>(context, listen: false);
await authProvider.refreshUserProfile();
```

### Getting Current Profile

```dart
final authProvider = Provider.of<AuthProvider>(context, listen: false);
final userProfile = authProvider.userProfile;
```

### Updating Profile Data

```dart
final authProvider = Provider.of<AuthProvider>(context, listen: false);
final success = await authProvider.updateUserProfile(
  fullName: 'John Doe',
  bio: 'Software developer',
  website: 'https://johndoe.com',
  location: 'New York',
  religion: 'Christianity',
);

if (success) {
  print('Profile updated successfully!');
} else {
  print('Failed to update profile: ${authProvider.error}');
}
```

### Refreshing Liked Posts

```dart
final authProvider = Provider.of<AuthProvider>(context, listen: false);
await authProvider.refreshLikedPosts();
```

### Searching Users

```dart
final authProvider = Provider.of<AuthProvider>(context, listen: false);
final searchResults = await authProvider.searchUsers('dhaniiiii');

print('Found ${searchResults.length} users');
for (final user in searchResults) {
  print('User: ${user['fullName']} (@${user['username']})');
}
```

### Viewing User Profiles

```dart
// Navigate to user profile from search results
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => UserProfileScreen(
      userId: userData['_id'],
      username: userData['username'],
      fullName: userData['fullName'],
      avatar: userData['avatar'],
      bio: userData['bio'],
      followersCount: userData['followersCount'],
      followingCount: userData['followingCount'],
      postsCount: userData['postsCount'],
    ),
  ),
);

// Get user posts
final userPosts = await authProvider.getUserPosts(userId);
```

### Following Users

```dart
// Get list of users that the current user follows
final authProvider = Provider.of<AuthProvider>(context, listen: false);
final followingUsers = await authProvider.getFollowingUsers();

print('Following ${followingUsers.length} users');
for (final user in followingUsers) {
  print('Following: ${user['fullName']} (@${user['username']})');
}
```

### Follow/Unfollow Users

```dart
// Follow a user
final authProvider = Provider.of<AuthProvider>(context, listen: false);
final success = await authProvider.followUser('targetUserId123');

if (success) {
  print('Successfully followed user');
} else {
  print('Failed to follow user: ${authProvider.error}');
}

// Unfollow a user
final unfollowSuccess = await authProvider.unfollowUser('targetUserId123');

if (unfollowSuccess) {
  print('Successfully unfollowed user');
} else {
  print('Failed to unfollow user: ${authProvider.error}');
}

// Check if following a user
final isFollowing = await authProvider.isFollowingUser('targetUserId123');
if (isFollowing) {
  print('Already following this user');
} else {
  print('Not following this user yet');
}
```

### Getting Followers

```dart
// Get list of users that follow the current user
final authProvider = Provider.of<AuthProvider>(context, listen: false);
final followers = await authProvider.getFollowers();

print('You have ${followers.length} followers');
for (final user in followers) {
  print('Follower: ${user['fullName']} (@${user['username']})');
}

// Get list of users that follow a specific user
final otherUserFollowers = await authProvider.getFollowersForUser('otherUserId123');
print('Other user has ${otherUserFollowers.length} followers');
```

### Getting Following of Other Users

```dart
// Get list of users that a specific user follows
final authProvider = Provider.of<AuthProvider>(context, listen: false);
final otherUserFollowing = await authProvider.getFollowingUsersForUser('otherUserId123');

print('Other user follows ${otherUserFollowing.length} users');
for (final user in otherUserFollowing) {
  print('Following: ${user['fullName']} (@${user['username']})');
}
```

## Error Handling

The implementation includes comprehensive error handling:
- API failures fall back to local data
- Network errors are displayed to users
- Loading states prevent multiple simultaneous requests
- Graceful degradation when fields are missing

## Testing

To test the API integration:

1. **Login/Signup**: Use valid credentials to authenticate
2. **Check Profile**: Navigate to Account section
3. **Verify Data**: Ensure all API fields are displayed correctly
4. **Test Refresh**: Use pull-to-refresh or refresh button
5. **Check Debug Info**: Verify API response data in debug mode

### 1. **Profile Retrieval Test**
1. Login/signup to the app
2. Navigate to Account section
3. Verify all user data is displayed correctly
4. Test pull-to-refresh functionality
5. Check debug information (if in debug mode)

### 2. **Profile Update Test**
1. In Account section, tap the pencil (edit) icon
2. Modify any field (e.g., change bio from "Software developer" to "Full-stack developer")
3. Change religion from "Islam" to "Christianity"
4. Add a website: "https://johndoe.com"
5. Update location to "New York"
6. Tap Save button
7. Verify success message appears
8. Return to profile screen and confirm changes are visible

### 3. **Post Like Test**
1. In Account section, navigate to any tab (Posts, Liked, or Saved)
2. Tap the like button (heart icon) on any post
3. Verify success message appears
4. Check that the like count increases
5. Verify the heart icon changes to filled (red) state
6. Test liking multiple posts to ensure API works consistently

### 4. **Search Users Test**
1. In Home screen, tap the Search button (magnifying glass icon)
2. Enter a search query (e.g., "dhaniiiii")
3. Verify search results are displayed
4. Check that user information is correct (name, username, bio, stats)
5. Test with different search queries
6. Verify error handling with invalid queries

### 5. **User Profile Viewing Test**
1. In Search screen, tap on any user result
2. Verify user profile screen opens
3. Check that user information is displayed correctly
4. Verify profile statistics (posts, followers, following)
5. Test the Follow/Unfollow button functionality
6. Navigate through different tabs (Posts, Reels, Tagged)
7. Test viewing user posts in grid layout
8. Verify back navigation works correctly

### 6. **Following List Test**
1. In Account section, tap on the "Following" stat
2. Verify Following screen opens
3. Check that following users list is displayed correctly
4. Verify user information (name, username, avatar) is shown
5. Test tapping on a following user to view their profile
6. Test refresh functionality
7. Test error handling and empty states
8. Verify back navigation works correctly

### 7. **Followers List Test**
1. In Account section, tap on the "Followers" stat
2. Verify Followers screen opens
3. Check that followers list is displayed correctly
4. Verify user information (name, username, avatar) is shown
5. Test tapping on a follower to view their profile
6. Test refresh functionality
7. Test error handling and empty states
8. Verify back navigation works correctly

### 8. **Follow/Unfollow Test**
1. In Search screen, search for a user and open their profile
2. Tap the Follow button
3. Verify success message appears
4. Check that button changes to "Following" state
5. Return to Account section and verify following count increased
6. Go back to user profile and tap Unfollow
7. Verify success message appears
8. Check that button changes back to "Follow" state
9. Return to Account section and verify following count decreased

### 9. **Viewing Other Users' Followers/Following Test**
1. In Search screen, search for a user and open their profile
2. Tap on the "Followers" count to see who follows that user
3. Verify Followers screen opens showing that user's followers
4. Tap on the "Following" count to see who that user follows
5. Verify Following screen opens showing that user's following list
6. Test navigation between different users' followers/following lists
7. Verify back navigation works correctly

### 10. **Validation Test**
1. Try to save with empty full name (should show error)
2. Try to save with invalid website URL (should show error)
3. Try to save without selecting religion (should show error)
4. Test unsaved changes warning when going back

### 10. **Error Handling Test**
1. Test with invalid API token
2. Test with network disconnection
3. Verify fallback behavior works correctly

## Troubleshooting

### Common Issues

1. **Profile Not Loading**: Check authentication token and network connectivity
2. **Missing Fields**: Verify API response structure matches expected format
3. **Refresh Fails**: Check API endpoint availability and token validity
4. **Search Not Working**: Verify search API endpoint and token format (Bearer)

### Debug Information

In debug mode, the profile screen shows:
- User ID
- Creation date
- Last active time
- Privacy settings
- Other technical details

## Future Enhancements

- Profile editing capabilities
- Real-time profile updates
- Profile privacy controls
- Enhanced verification features
- Profile analytics and insights
- User profile navigation from search results
- Advanced search filters

## Complete Implementation Summary

The R-Gram app now has full profile management and search capabilities:

### ✅ **Profile Retrieval**
- Automatic profile loading after authentication
- Real-time data from R-Gram API
- Fallback to local data if API fails
- Pull-to-refresh functionality

### ✅ **Profile Display**
- Complete user information display
- Religion-based theming and symbols
- Statistics (Posts, Reels, Followers, Following)
- Verification status indicators
- Debug information in development mode
- **NEW**: Functional like buttons on all posts
- **NEW**: Real-time like count updates
- **NEW**: Real liked posts display in Liked tab (not mock data)
- **NEW**: Automatic refresh of liked posts when posts are liked
- **IMPORTANT**: Only posts that users manually like (by tapping the heart icon) appear in the Liked tab
- **NO CLOUDINARY POSTS**: Liked section only shows posts that users have explicitly liked, not posts from external sources

### ✅ **Profile Editing**
- Dedicated edit screen with form validation
- Update full name, bio, website, location, and religion
- Real-time API updates
- Change detection and unsaved changes warning
- Immediate UI updates after successful edits

### ✅ **Search Functionality**
- **NEW**: Dedicated search screen accessible from home navigation
- **NEW**: Search users by username or name using R-Gram API
- **NEW**: Real-time search with debouncing
- **NEW**: Display search results with user profiles and statistics
- **NEW**: Clean and intuitive search interface
- **NEW**: Click on search results to view user profiles
- **NEW**: User profile screen with posts, reels, and tagged content tabs

### ✅ **API Integration**
- Profile retrieval: `GET /api/user/profile`
- Profile update: `PUT /api/user/update`
- **NEW**: Post like: `POST /api/feed/like/{postId}`
- **NEW**: Get liked posts: `GET /api/user/liked-posts`
- **NEW**: Search users: `GET /api/search?q={query}&type=users`
- **NEW**: Follow user: `POST /api/follow/{targetUserId}`
- **NEW**: Unfollow user: `DELETE /api/follow/{targetUserId}`
- **NEW**: Get following users: `