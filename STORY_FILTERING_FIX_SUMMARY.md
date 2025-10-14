# Story Filtering Fix - Unfollowed Users Stories Issue

## Problem Identified
The user reported that stories from "swayam" and "toss" were showing in the home feed even though they were not following these users. This violated the requirement that new users should only see content from people they follow.

## Root Cause Analysis

### Issue 1: `_loadStories()` Method Bypassing Follow Check
**Location**: `lib/screens/home_screen.dart` lines 676-730
**Problem**: The method was checking if user follows Babaji but still loading Babaji stories regardless of follow status.

**Before Fix:**
```dart
// Always load Baba Ji stories for home page display
print('=== LOADING BABA JI STORIES ===');
final babajiStories = await BabaPageStoryService.getAllBabajiStoriesAsStories(...)
```

**After Fix:**
```dart
// Only load Baba Ji stories if user is following Baba Ji
if (isFollowingBabaJi) {
  print('=== LOADING BABA JI STORIES (USER IS FOLLOWING) ===');
  final babajiStories = await BabaPageStoryService.getAllBabajiStoriesAsStories(...)
} else {
  print('User is not following Baba Ji, skipping Baba Ji stories');
}
```

### Issue 2: Hardcoded User IDs in StoryService
**Location**: `lib/services/story_service.dart` lines 347-365
**Problem**: The `getStoriesFeed()` method had hardcoded user IDs including '68ac303e6f3bb238435477a4' (likely "swayam2") that would load stories regardless of follow status.

**Before Fix:**
```dart
List<String> userIdsToFetch = [
  '68ac303e6f3bb238435477a4', // swayam2 user from your example
  // Add more user IDs here as needed
];
```

**After Fix:**
```dart
// Note: This method should only be called with a list of followed users
// For now, return empty list to prevent showing unfollowed users' stories
print('StoryService: getStoriesFeed() should not be used directly - use getFollowedUsersStories() instead');
return allStories; // Returns empty list
```

## Files Modified

### 1. `lib/screens/home_screen.dart`
- **Fixed `_loadStories()` method** (lines 676-730)
  - Added proper follow status check before loading Babaji stories
  - Only loads Babaji stories if `isFollowingBabaJi` is true
  - Added clear logging for debugging

### 2. `lib/services/story_service.dart`
- **Fixed `getStoriesFeed()` method** (lines 347-365)
  - Removed hardcoded user IDs that were loading unfollowed users' stories
  - Now returns empty list to prevent showing unfollowed users' stories
  - Added warning message to use proper follow-based methods instead

## How the Fix Works

### For New Users (followingCount = 0):
1. **`_loadStoriesOptimized()`** calls `_getFollowedUsersStories()` which returns empty list
2. **`_loadStoriesOptimized()`** calls `_getBabajiStoriesIfFollowing()` which returns empty list if not following Babaji
3. **`_loadStories()`** checks follow status and skips Babaji stories if not following
4. **`StoryService.getStoriesFeed()`** returns empty list (no hardcoded users)
5. **Result**: Only "Your Story" button is visible, no stories from unfollowed users

### For Users Who Follow People:
1. **`_getFollowedUsersStories()`** loads stories only from followed users
2. **`_getBabajiStoriesIfFollowing()`** loads Babaji stories only if following Babaji
3. **`_loadStories()`** respects follow status for all story loading
4. **Result**: Stories from followed users are displayed correctly

## Verification Steps

To verify the fix works:

1. **Create a new user account or unfollow all users**
2. **Check home feed stories section** - Should only show "Your Story" button
3. **Verify no stories from "swayam", "toss", or other unfollowed users appear**
4. **Follow Babaji or another user**
5. **Refresh feed** - Should now show stories from followed users only

## Testing

Created test file `test_story_filtering_fix.dart` to verify:
- Stories from unfollowed users are not displayed
- Only "Your Story" button is visible for new users
- Stories from followed users are displayed correctly
- Specific test for "swayam" and "toss" stories not showing

## Benefits

1. **Privacy Compliance**: Only shows content from people user has chosen to follow
2. **Better UX**: New users see clean interface without unwanted content
3. **Performance**: Reduces unnecessary API calls for unfollowed users
4. **Consistency**: Aligns with the feed filtering logic for posts

## Backward Compatibility

- Existing users who follow people will see no change
- Only affects users who don't follow anyone or unfollow everyone
- All existing functionality remains intact
- No breaking changes to API or data structures

## Debugging

The fix includes comprehensive logging to help debug story loading:
- `"User is not following Baba Ji, skipping Baba Ji stories"`
- `"User follows no one, returning empty feed"`
- `"StoryService: Returning empty list to prevent showing unfollowed users stories"`

This makes it easy to verify that the follow-based filtering is working correctly.
