# Story Upload Feature

This document explains how to use the new story upload functionality in the R_GRam Flutter app.

## Overview

The story upload feature allows users to upload images and videos as stories using the API endpoint:
- **URL**: `http://api-rgram1.vercel.app/api/upload/story`
- **Method**: POST
- **Content-Type**: application/json

## API Integration

### Story Upload API

The story upload API accepts the following parameters:
- `media`: The media URL (image or video)
- `type`: The media type ("image" or "video")

**Example Request:**
```json
{
  "media": "story_media_url",
  "type": "image"
}
```

**Example Response:**
```json
{
  "success": true,
  "message": "Story uploaded",
  "data": {
    "story": {
      "author": "6899ae47ecc3cd3c33179c51",
      "media": "story_media_url",
      "type": "image",
      "mentions": [],
      "hashtags": [],
      "isActive": true,
      "views": [],
      "viewsCount": 0,
      "_id": "6899b18c9522cd64491278f4",
      "expiresAt": "2025-08-12T09:02:04.421Z",
      "createdAt": "2025-08-11T09:02:04.421Z",
      "updatedAt": "2025-08-11T09:02:04.421Z"
    }
  }
}
```

## Implementation Details

### 1. Story Model (`lib/models/story_model.dart`)

The `Story` class represents a story with all its properties:
- Basic info: id, author, media, type
- Engagement: mentions, hashtags, views, viewsCount
- Status: isActive, expiresAt
- Timestamps: createdAt, updatedAt

### 2. Story Service (`lib/services/story_service.dart`)

The `StoryService` class provides methods for:
- `uploadStory()`: Upload story with media URL
- `uploadStoryFromFile()`: Upload story from local file
- `getUserStories()`: Get user's stories
- `deleteStory()`: Delete a story
- `getStoryViews()`: Get story views
- `markStoryAsViewed()`: Mark story as viewed

### 3. Story Upload Screen (`lib/screens/story_upload_screen.dart`)

A dedicated screen for story creation with:
- Media selection (gallery/camera for images and videos)
- Media preview
- Upload functionality
- Progress indicators

### 4. Integration with Home Screen

The home screen now includes:
- An "Add Story" button in the stories section
- Navigation to the story upload screen
- Token validation before upload

## Usage

### Basic Story Upload

```dart
// Upload story with media URL
final result = await StoryService.uploadStory(
  mediaUrl: 'https://example.com/image.jpg',
  type: 'image',
  token: 'your_auth_token',
);

if (result.success) {
  print('Story uploaded successfully!');
  print('Story ID: ${result.story?.id}');
} else {
  print('Upload failed: ${result.message}');
}
```

### Upload from File

```dart
// Upload story from local file
final result = await StoryService.uploadStoryFromFile(
  file: File('/path/to/image.jpg'),
  type: 'image',
  token: 'your_auth_token',
);

if (result.success) {
  print('Story uploaded successfully!');
} else {
  print('Upload failed: ${result.message}');
}
```

### Navigation to Upload Screen

```dart
// Navigate to story upload screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => StoryUploadScreen(token: 'your_auth_token'),
  ),
);
```

## Dependencies

The following packages are required:
- `image_picker`: For selecting images and videos from gallery/camera
- `video_player`: For video preview and playback
- `http`: For API communication

## Error Handling

The service includes comprehensive error handling:
- Network errors
- File upload failures
- API response validation
- User-friendly error messages

## Security

- Authentication token is required for all operations
- Media files are validated before upload
- File size and type restrictions can be implemented

## Future Enhancements

Potential improvements include:
- Story editing capabilities
- Filters and effects for images
- Story templates
- Scheduled story publishing
- Analytics and insights
- Story collaboration features

## Troubleshooting

### Common Issues

1. **Token Expired**: Ensure the authentication token is valid
2. **File Too Large**: Check file size limits
3. **Unsupported Format**: Verify file type is supported
4. **Network Issues**: Check internet connectivity

### Debug Information

Enable debug logging by checking the console output for detailed error messages and API responses.
