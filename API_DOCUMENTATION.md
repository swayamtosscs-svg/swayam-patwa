# R-Gram API Documentation

This document contains all the API endpoints used in the R-Gram Flutter application.

## 📋 Table of Contents

- [Base URLs](#base-urls)
- [Authentication](#authentication)
- [User Management](#user-management)
- [Feed APIs](#feed-apis)
- [Post Management](#post-management)
- [Reel Management](#reel-management)
- [Story Management](#story-management)
- [Search APIs](#search-apis)
- [Follow System](#follow-system)
- [Chat & Messaging](#chat--messaging)
- [Baba Ji Pages](#baba-ji-pages)
- [Baba Ji Page Posts](#baba-ji-page-posts)
- [Baba Ji Page Reels](#baba-ji-page-reels)
- [Baba Ji Page Comments](#baba-ji-page-comments)
- [Baba Ji Page Likes](#baba-ji-page-likes)
- [Media Management](#media-management)
- [Notifications](#notifications)
- [Legacy APIs](#legacy-apis)

## Base URLs

- **Primary Server**: `https://api-rgram1.vercel.app/api`
- **Legacy Server**: `http://tossconsultancyservices.com/rgram`

## Authentication

Most APIs require authentication using Bearer token:
```
Authorization: Bearer YOUR_TOKEN
```

## Authentication APIs

### 1. Send OTP
**Endpoint**: `POST /auth/otp/send`
```bash
curl -X POST "https://api-rgram1.vercel.app/api/auth/otp/send" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "purpose": "signup"
  }'
```

### 2. Verify OTP
**Endpoint**: `POST /auth/otp/verify`
```bash
curl -X POST "https://api-rgram1.vercel.app/api/auth/otp/verify" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "code": "123456",
    "purpose": "signup"
  }'
```

### 3. User Signup
**Endpoint**: `POST /auth/signup`
```bash
curl -X POST "https://api-rgram1.vercel.app/api/auth/signup" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123",
    "fullName": "John Doe",
    "username": "johndoe",
    "religion": "Hindu",
    "isPrivate": false
  }'
```

### 4. User Login
**Endpoint**: `POST /auth/login`
```bash
curl -X POST "https://api-rgram1.vercel.app/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'
```

### 5. Google OAuth Init
**Endpoint**: `GET /auth/google/init`
```bash
curl -X GET "https://api-rgram1.vercel.app/api/auth/google/init" \
  -H "Content-Type: application/json"
```

### 6. Google OAuth Callback
**Endpoint**: `GET /auth/google/callback`
```bash
curl -X GET "https://api-rgram1.vercel.app/api/auth/google/callback?test=true&format=json" \
  -H "Content-Type: application/json"
```

### 7. Logout
**Endpoint**: `POST /auth/logout`
```bash
curl -X POST "https://api-rgram1.vercel.app/api/auth/logout" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## User Management

### 8. Get User Profile
**Endpoint**: `GET /user/profile`
```bash
curl -X GET "https://api-rgram1.vercel.app/api/user/profile" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 9. Update User Profile
**Endpoint**: `PUT /user/update`
```bash
curl -X PUT "https://api-rgram1.vercel.app/api/user/update" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "fullName": "John Doe Updated",
    "username": "johndoe_updated",
    "bio": "Updated bio"
  }'
```

### 10. Toggle Privacy
**Endpoint**: `PUT /user/toggle-privacy-by-id`
```bash
curl -X PUT "https://api-rgram1.vercel.app/api/user/toggle-privacy-by-id" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "userId": "USER_ID",
    "isPrivate": true
  }'
```

## Feed APIs

### 11. Get Home Feed
**Endpoint**: `GET /feed/home`
```bash
curl -X GET "https://api-rgram1.vercel.app/api/feed/home?page=1&limit=20" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 12. Get General Feed
**Endpoint**: `GET /feed`
```bash
curl -X GET "https://api-rgram1.vercel.app/api/feed?page=1&limit=20" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Post Management

### 13. Create Post
**Endpoint**: `POST /posts`
```bash
curl -X POST "https://api-rgram1.vercel.app/api/posts" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "caption": "My new post",
    "mediaUrl": "https://example.com/image.jpg",
    "type": "image",
    "hashtags": ["#spiritual", "#peace"]
  }'
```

### 14. Get User Media
**Endpoint**: `GET /user/{userId}/media`
```bash
curl -X GET "https://api-rgram1.vercel.app/api/user/USER_ID/media?page=1&limit=10" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Reel Management

### 15. Upload Reel
**Endpoint**: `POST /upload/reel`
```bash
curl -X POST "https://api-rgram1.vercel.app/api/upload/reel" \
  -H "Content-Type: application/json" \
  -H "Authorization: YOUR_TOKEN" \
  -d '{
    "content": "My awesome reel",
    "videoUrl": "https://example.com/video.mp4",
    "thumbnail": "https://example.com/thumbnail.jpg"
  }'
```

## Story Management

### 16. Upload Story
**Endpoint**: `POST /story/upload`
```bash
curl -X POST "https://api-rgram1.vercel.app/api/story/upload" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@/path/to/story.jpg" \
  -F "userId=USER_ID" \
  -F "caption=My story caption"
```

### 17. Get Stories
**Endpoint**: `GET /stories`
```bash
curl -X GET "https://api-rgram1.vercel.app/api/stories" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Search APIs

### 18. Search Users
**Endpoint**: `GET /search`
```bash
curl -X GET "https://api-rgram1.vercel.app/api/search?q=john&type=users&page=1&limit=10" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Follow System

### 19. Follow User
**Endpoint**: `POST /follow/{userId}`
```bash
curl -X POST "https://api-rgram1.vercel.app/api/follow/USER_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 20. Unfollow User
**Endpoint**: `DELETE /follow/{userId}`
```bash
curl -X DELETE "https://api-rgram1.vercel.app/api/follow/USER_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 21. Get Following
**Endpoint**: `GET /following/{userId}`
```bash
curl -X GET "https://api-rgram1.vercel.app/api/following/USER_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 22. Get Followers
**Endpoint**: `GET /followers/{userId}`
```bash
curl -X GET "https://api-rgram1.vercel.app/api/followers/USER_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 23. Get Follow Status
**Endpoint**: `GET /follow/status/{userId}`
```bash
curl -X GET "https://api-rgram1.vercel.app/api/follow/status/USER_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 24. Send Follow Request
**Endpoint**: `POST /follow-request/{userId}`
```bash
curl -X POST "https://api-rgram1.vercel.app/api/follow-request/USER_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 25. Get Follow Requests
**Endpoint**: `GET /follow-requests`
```bash
curl -X GET "https://api-rgram1.vercel.app/api/follow-requests?page=1&limit=10" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 26. Respond to Follow Request
**Endpoint**: `PUT /follow-request/{requestId}`
```bash
curl -X PUT "https://api-rgram1.vercel.app/api/follow-request/REQUEST_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "action": "accept"
  }'
```

## Chat & Messaging

### 27. Send Message
**Endpoint**: `POST /chat/quick-message`
```bash
curl -X POST "https://api-rgram1.vercel.app/api/chat/quick-message" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "toUserId": "USER_ID",
    "content": "Hello!",
    "messageType": "text"
  }'
```

### 28. Get Messages
**Endpoint**: `GET /chat/quick-message`
```bash
curl -X GET "https://api-rgram1.vercel.app/api/chat/quick-message?threadId=THREAD_ID&limit=50" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 29. Update Message
**Endpoint**: `PUT /chat/quick-message`
```bash
curl -X PUT "https://api-rgram1.vercel.app/api/chat/quick-message" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "messageId": "MESSAGE_ID",
    "content": "Updated message"
  }'
```

### 30. Delete Message
**Endpoint**: `DELETE /chat/quick-message`
```bash
curl -X DELETE "https://api-rgram1.vercel.app/api/chat/quick-message" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "messageId": "MESSAGE_ID",
    "deleteType": "for_me"
  }'
```

## Baba Ji Pages

### 31. Create Baba Ji Page
**Endpoint**: `POST /baba-pages`
```bash
curl -X POST "https://api-rgram1.vercel.app/api/baba-pages" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "name": "Baba Ji Name",
    "description": "Spiritual teachings",
    "religion": "Hindu",
    "website": "https://example.com",
    "location": "India"
  }'
```

### 32. Get Baba Ji Pages
**Endpoint**: `GET /baba-pages`
```bash
curl -X GET "https://api-rgram1.vercel.app/api/baba-pages?page=1&limit=10&search=spiritual" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 33. Get Baba Ji Page by ID
**Endpoint**: `GET /baba-pages/{pageId}`
```bash
curl -X GET "https://api-rgram1.vercel.app/api/baba-pages/PAGE_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 34. Update Baba Ji Page
**Endpoint**: `PUT /baba-pages/{pageId}`
```bash
curl -X PUT "https://api-rgram1.vercel.app/api/baba-pages/PAGE_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "name": "Updated Baba Ji Name",
    "description": "Updated description"
  }'
```

### 35. Delete Baba Ji Page
**Endpoint**: `DELETE /baba-pages/{pageId}`
```bash
curl -X DELETE "https://api-rgram1.vercel.app/api/baba-pages/PAGE_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 36. Follow Baba Ji Page
**Endpoint**: `POST /baba-pages/{pageId}/follow`
```bash
curl -X POST "https://api-rgram1.vercel.app/api/baba-pages/PAGE_ID/follow" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 37. Unfollow Baba Ji Page
**Endpoint**: `DELETE /baba-pages/{pageId}/follow`
```bash
curl -X DELETE "https://api-rgram1.vercel.app/api/baba-pages/PAGE_ID/follow" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Baba Ji Page Posts

### 38. Create Baba Ji Page Post
**Endpoint**: `POST /baba-pages/{pageId}/posts`
```bash
curl -X POST "https://api-rgram1.vercel.app/api/baba-pages/PAGE_ID/posts" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "content=Post content" \
  -F "media=@/path/to/image.jpg"
```

### 39. Get Baba Ji Page Posts
**Endpoint**: `GET /baba-pages/{pageId}/posts`
```bash
curl -X GET "https://api-rgram1.vercel.app/api/baba-pages/PAGE_ID/posts?page=1&limit=10" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Baba Ji Page Reels

### 40. Upload Baba Ji Page Reel
**Endpoint**: `POST /baba-pages/{pageId}/reels`
```bash
curl -X POST "https://api-rgram1.vercel.app/api/baba-pages/PAGE_ID/reels" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "video=@/path/to/video.mp4" \
  -F "thumbnail=@/path/to/thumbnail.jpg" \
  -F "title=Reel title" \
  -F "description=Reel description"
```

### 41. Get Baba Ji Page Reels
**Endpoint**: `GET /baba-pages/{pageId}/reels`
```bash
curl -X GET "https://api-rgram1.vercel.app/api/baba-pages/PAGE_ID/reels?page=1&limit=10" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Baba Ji Page Comments

### 42. Add Comment to Baba Ji Page
**Endpoint**: `POST /baba-pages/{pageId}/comments`
```bash
curl -X POST "http://103.14.120.163:8081/api/baba-pages/PAGE_ID/comments" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "content": "Your comment text here",
    "contentId": "POST_ID",
    "contentType": "post",
    "userId": "USER_ID"
  }'
```

### 43. Get Baba Ji Page Comments
**Endpoint**: `GET /baba-pages/{pageId}/comments`
```bash
curl -X GET "http://103.14.120.163:8081/api/baba-pages/PAGE_ID/comments?contentId=POST_ID&contentType=post&page=1&limit=10" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 44. Add Comment to Baba Ji Page Reel
**Endpoint**: `POST /baba-pages/{pageId}/comments`
```bash
curl -X POST "http://103.14.120.163:8081/api/baba-pages/PAGE_ID/comments" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "content": "Your comment text here",
    "contentId": "REEL_ID",
    "contentType": "reel",
    "userId": "USER_ID"
  }'
```

### 45. Get Baba Ji Page Reel Comments
**Endpoint**: `GET /baba-pages/{pageId}/comments`
```bash
curl -X GET "http://103.14.120.163:8081/api/baba-pages/PAGE_ID/comments?contentId=REEL_ID&contentType=reel&page=1&limit=10" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Baba Ji Page Likes

### 46. Like Baba Ji Page Content
**Endpoint**: `POST /baba-pages/{pageId}/like`
```bash
curl -X POST "https://api-rgram1.vercel.app/api/baba-pages/PAGE_ID/like" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "contentId": "POST_ID",
    "contentType": "post"
  }'
```

### 47. Unlike Baba Ji Page Content
**Endpoint**: `DELETE /baba-pages/{pageId}/like`
```bash
curl -X DELETE "https://api-rgram1.vercel.app/api/baba-pages/PAGE_ID/like" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "contentId": "POST_ID",
    "contentType": "post"
  }'
```

### 48. Check Like Status
**Endpoint**: `GET /baba-pages/{pageId}/like`
```bash
curl -X GET "https://api-rgram1.vercel.app/api/baba-pages/PAGE_ID/like?contentId=POST_ID&contentType=post&userId=USER_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Media Management

### 49. Delete Media
**Endpoint**: `DELETE /media/delete`
```bash
curl -X DELETE "https://api-rgram1.vercel.app/api/media/delete?id=MEDIA_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 50. Get Media Upload
**Endpoint**: `GET /media/upload`
```bash
curl -X GET "https://api-rgram1.vercel.app/api/media/upload?userId=USER_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Notifications

### 51. Get Notifications
**Endpoint**: `GET /notifications`
```bash
curl -X GET "https://api-rgram1.vercel.app/api/notifications?page=1&limit=20" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Legacy APIs

The following APIs are from the legacy server (`http://tossconsultancyservices.com/rgram`) and may be deprecated:

### 52. Legacy Send OTP
```bash
curl -X POST "http://tossconsultancyservices.com/rgram/send-otp.php" \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "+1234567890"
  }'
```

### 53. Legacy Verify OTP
```bash
curl -X POST "http://tossconsultancyservices.com/rgram/verify-otp.php" \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "+1234567890",
    "otp": "123456"
  }'
```

### 54. Legacy Login
```bash
curl -X POST "http://tossconsultancyservices.com/rgram/login.php" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'
```

### 55. Legacy Signup
```bash
curl -X POST "http://tossconsultancyservices.com/rgram/signup.php" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123",
    "fullName": "John Doe"
  }'
```

### 56. Legacy Get Profile
```bash
curl -X GET "http://tossconsultancyservices.com/rgram/profile.php?user_id=USER_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 57. Legacy Get Feed
```bash
curl -X GET "http://tossconsultancyservices.com/rgram/feed.php?page=1&limit=10" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 58. Legacy Create Post
```bash
curl -X POST "http://tossconsultancyservices.com/rgram/create-post.php" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "content": "My post",
    "image_url": "https://example.com/image.jpg"
  }'
```

### 59. Legacy Get Posts
```bash
curl -X GET "http://tossconsultancyservices.com/rgram/posts.php?user_id=USER_ID&page=1&limit=10" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 60. Legacy Create Story
```bash
curl -X POST "http://tossconsultancyservices.com/rgram/create-story.php" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "content": "My story",
    "media_url": "https://example.com/story.jpg"
  }'
```

### 61. Legacy Get Stories
```bash
curl -X GET "http://tossconsultancyservices.com/rgram/stories.php" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 62. Legacy Search Users
```bash
curl -X GET "http://tossconsultancyservices.com/rgram/search-users.php?q=john&page=1&limit=10" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 63. Legacy Get Notifications
```bash
curl -X GET "http://tossconsultancyservices.com/rgram/notifications.php?page=1&limit=20" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 64. Legacy Add Comment
```bash
curl -X POST "http://tossconsultancyservices.com/rgram/add-comment.php" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "post_id": "POST_ID",
    "comment": "Great post!"
  }'
```

### 65. Legacy Get Comments
```bash
curl -X GET "http://tossconsultancyservices.com/rgram/comments.php?post_id=POST_ID&page=1&limit=10" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 66. Legacy Update Profile
```bash
curl -X POST "http://tossconsultancyservices.com/rgram/update-profile.php" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "user_id": "USER_ID",
    "fullName": "John Doe Updated",
    "bio": "Updated bio"
  }'
```

### 67. Legacy Upload
```bash
curl -X POST "http://tossconsultancyservices.com/rgram/upload.php" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@/path/to/file.jpg"
```

## Response Format

Most APIs return responses in the following format:

### Success Response
```json
{
  "success": true,
  "message": "Operation successful",
  "data": {
    // Response data
  }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error description"
}
```

## Authentication Notes

- **Bearer Token**: Most APIs use `Authorization: Bearer YOUR_TOKEN`
- **Direct Token**: Some APIs (like reel upload) use `Authorization: YOUR_TOKEN` (without Bearer)
- **No Auth**: Some public APIs don't require authentication

## Rate Limiting

Please be mindful of rate limits when making API calls. The exact limits are not documented but it's recommended to:
- Implement proper retry logic
- Use pagination for list endpoints
- Cache responses when appropriate

## Error Handling

Common HTTP status codes:
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `500` - Internal Server Error

## Support

For API support or questions, please contact the development team or refer to the main project documentation.
