# Reel Upload API Integration

This document explains how to use the reel upload API integration in the R_GRam Flutter app.

## API Endpoint

- **URL**: `http://api-rgram1.vercel.app/api/upload/reel`
- **Method**: `POST`
- **Content-Type**: `application/json`

## Authentication

The API uses JWT tokens for authentication. Include the token in the `Authorization` header:

```
Authorization: <your_jwt_token>
```

**Note**: Unlike other APIs in this app, this API expects the token directly without the "Bearer " prefix.

## Request Body

```json
{
  "content": "Reel content description",
  "videoUrl": "https://example.com/video.mp4",
  "thumbnail": "https://example.com/thumbnail.jpg"
}
```

### Required Fields

- `content`: String - Description or caption for the reel
- `videoUrl`: String - URL to the video file
- `thumbnail`: String - URL to the thumbnail image

## Response Format

### Success Response (200)

```json
{
  "success": true,
  "message": "Reel uploaded",
  "data": {
    "post": {
      "author": {
        "_id": "6899ae47ecc3cd3c33179c51",
        "username": "johndoe3",
        "fullName": "John Doe",
        "avatar": ""
      },
      "content": "Reel content",
      "images": [],
      "videos": [],
      "externalUrls": [],
      "type": "reel",
      "provider": "local",
      "duration": 0,
      "category": "general",
      "religion": "",
      "likes": [],
      "likesCount": 0,
      "commentsCount": 0,
      "shares": [],
      "sharesCount": 0,
      "saves": [],
      "savesCount": 0,
      "isActive": true,
      "_id": "6899b4ae9522cd64491278fa",
      "createdAt": "2025-08-11T09:15:26.716Z",
      "comments": [],
      "updatedAt": "2025-08-11T09:15:26.716Z",
      "__v": 0
    }
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

## Usage in Flutter

### 1. Using ReelService

```dart
import 'package:your_app/services/reel_service.dart';

// Upload a reel
final response = await ReelService.uploadReel(
  content: "Check out this amazing reel!",
  videoUrl: "https://example.com/video.mp4",
  thumbnail: "https://example.com/thumb.jpg",
  token: "your_jwt_token_here",
);

if (response.success) {
  print("Reel uploaded successfully!");
  print("Reel ID: ${response.data.post.id}");
  print("Author: ${response.data.post.author.username}");
} else {
  print("Upload failed: ${response.message}");
}
```

### 2. Using ApiService

```dart
import 'package:your_app/services/api_service.dart';

// Upload a reel
final response = await ApiService.uploadReel(
  content: "Check out this amazing reel!",
  videoUrl: "https://example.com/video.mp4",
  thumbnail: "https://example.com/thumb.jpg",
  token: "your_jwt_token_here",
);

if (response['success'] == true) {
  print("Reel uploaded successfully!");
} else {
  print("Upload failed: ${response['message']}");
}
```

## Models

The integration includes several models to handle the API responses:

- `ReelAuthor`: Represents the author of a reel
- `ReelPost`: Represents a reel post with all its properties
- `ReelUploadResponse`: Wrapper for the upload API response
- `ReelUploadData`: Contains the uploaded reel data

## Example Token

For testing purposes, you can use this example token:

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2ODk5YWU0N2VjYzNjZDNjMzMxNzljNTEiLCJpYXQiOjE3NTQ5MDIwODcsImV4cCI6MTc1NzQ5NDA4N30.obM9YqZsFac6Be9iT5R-QLdllMBAkHRPJ_jfy6XRbIs
```

## Testing the Integration

1. Navigate to `/reel-upload` in the app
2. Fill in the form with your reel details
3. Use the example token or your own JWT token
4. Click "Upload Reel" to test the API

## Additional Features

The `ReelService` also provides methods for:

- Getting reels feed
- Liking/unliking reels
- Adding comments
- Sharing reels
- Saving/unsaving reels

## Error Handling

The service includes comprehensive error handling:

- Network errors
- Invalid responses
- HTTP status code errors
- JSON parsing errors

All errors are wrapped in a consistent response format for easy handling in the UI.

## Dependencies

Make sure you have the following dependencies in your `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.1.0
  flutter:
    sdk: flutter
```

## Notes

- The API expects URLs for video and thumbnail files
- The content field supports text descriptions
- All timestamps are in ISO 8601 format
- The API automatically assigns a unique ID to each uploaded reel
- The response includes comprehensive metadata about the uploaded reel
