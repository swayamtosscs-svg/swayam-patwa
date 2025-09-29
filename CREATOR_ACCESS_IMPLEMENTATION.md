# Creator-Only Access Control Implementation

## Overview
This document describes the implementation of creator-only access control for Baba Ji pages, ensuring that only the user who created a page can delete it or create posts for it.

## Changes Made

### 1. Updated BabaPage Model
**File**: `lib/models/baba_page_model.dart`

- Added `creatorId` field to track the page creator
- Updated constructor, `fromJson`, `toJson`, and `copyWith` methods to include the creator field
- The model now supports both `creatorId` and `creator` field names for backward compatibility

```dart
class BabaPage {
  final String creatorId; // Added creator field
  // ... other fields
}
```

### 2. Enhanced BabaPageService
**File**: `lib/services/baba_page_service.dart`

#### Added JWT Token Parsing
- `_extractUserIdFromToken()` method to decode JWT tokens and extract user ID
- Supports standard JWT format with proper base64 decoding

#### Updated Delete Method
- `deleteBabaPage()` now verifies creator access before deletion
- Fetches page details to check `creatorId`
- Compares with user ID from JWT token
- Returns appropriate error messages for unauthorized access

```dart
// Check if current user is the creator
if (pageResponse.data!.creatorId != userId) {
  return BabaPageResponse(
    success: false,
    message: 'Only the page creator can delete this page',
  );
}
```

### 3. Enhanced BabaPagePostService
**File**: `lib/services/baba_page_post_service.dart`

#### Added Creator Verification
- `_verifyPageCreator()` method to check if current user is the page creator
- `_extractUserIdFromToken()` method for JWT token parsing
- Both create and delete post methods now verify creator access

#### Updated Create Post Method
- `createBabaPagePost()` now checks creator permissions before creating posts
- Only the page creator can create posts for their page

#### Updated Delete Post Method
- `deleteBabaPagePost()` now verifies creator access before deletion
- Only the page creator can delete posts from their page

## API Endpoints Affected

### 1. DELETE /api/baba-pages/{pageId}
**Before**: Any authenticated user could delete any page
**After**: Only the page creator can delete their page

**Response for unauthorized access**:
```json
{
  "success": false,
  "message": "Only the page creator can delete this page"
}
```

### 2. POST /api/baba-pages/{pageId}/posts
**Before**: Any authenticated user could create posts for any page
**After**: Only the page creator can create posts for their page

**Response for unauthorized access**:
```json
{
  "success": false,
  "message": "Only the page creator can perform this action"
}
```

### 3. DELETE /api/baba-pages/{pageId}/posts/{postId}
**Before**: Any authenticated user could delete posts from any page
**After**: Only the page creator can delete posts from their page

## Security Features

### JWT Token Validation
- Extracts user ID from JWT token payload
- Validates token format and structure
- Handles malformed tokens gracefully

### Creator Verification
- Fetches page details to get creator information
- Compares creator ID with current user ID
- Returns appropriate error messages for different failure scenarios

### Error Handling
- Comprehensive error handling for network issues
- Clear error messages for different access scenarios
- Graceful degradation when API calls fail

## Testing

### Test Script
**File**: `test_creator_access.dart`

The test script includes:
1. **Create Page Test**: Creates a new Baba Ji page
2. **Create Post Test**: Creates a post as the page creator (should succeed)
3. **Unauthorized Post Test**: Attempts to create a post with different user token (should fail)
4. **Delete Page Test**: Deletes the page as the creator (should succeed)

### Running Tests
```bash
cd R_GRam
dart test_creator_access.dart
```

## Usage Examples

### Creating a Page (Unaffected)
```bash
curl --location 'http://103.14.120.163:8081/api/baba-pages' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer YOUR_TOKEN' \
--data '{
    "name": "Baba Ramdev Test Page",
    "description": "Testing authorization - created by User 1",
    "location": "Haridwar, India",
    "religion": "Hinduism",
    "website": "https://test-baba.com"
}'
```

### Deleting a Page (Now Creator-Only)
```bash
curl --location --request DELETE 'http://103.14.120.163:8081/api/baba-pages/PAGE_ID' \
--header 'Authorization: Bearer CREATOR_TOKEN'
```

**Success Response**:
```json
{
    "success": true,
    "message": "Baba Ji page deleted successfully from MongoDB"
}
```

**Unauthorized Response**:
```json
{
    "success": false,
    "message": "Only the page creator can delete this page"
}
```

### Creating Posts (Now Creator-Only)
```bash
curl --location 'http://103.14.120.163:8081/api/baba-pages/PAGE_ID/posts' \
--header 'Authorization: Bearer CREATOR_TOKEN' \
--form 'content="This is a test post by the page creator"'
```

**Success Response**: Post created successfully
**Unauthorized Response**:
```json
{
    "success": false,
    "message": "Only the page creator can perform this action"
}
```

## Backward Compatibility

- The implementation maintains backward compatibility with existing API responses
- Supports both `creatorId` and `creator` field names in API responses
- Existing pages without creator information will still work, but new access controls apply

## Future Enhancements

1. **Admin Override**: Add admin role that can manage any page
2. **Co-Creators**: Allow multiple users to manage a single page
3. **Permission Levels**: Different permission levels (view, post, manage)
4. **Audit Logging**: Log all creator actions for security tracking

## Security Considerations

1. **Token Security**: JWT tokens should be properly secured and have appropriate expiration
2. **Rate Limiting**: Consider implementing rate limiting for creator actions
3. **Input Validation**: Ensure all inputs are properly validated
4. **Error Information**: Avoid exposing sensitive information in error messages
