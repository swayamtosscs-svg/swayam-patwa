# Chat Media Integration - Video and Image Sending

This document describes the implementation of video and image sending functionality in the R_Gram chat system using the provided APIs.

## API Endpoints Used

### 1. Send Media Message
- **Endpoint**: `http://103.14.120.163:8081/api/chat/send-media`
- **Method**: POST
- **Content-Type**: multipart/form-data
- **Headers**: 
  - `Authorization: Bearer {token}`

**Form Fields:**
- `toUserId`: Recipient user ID
- `content`: Message content/caption
- `messageType`: "image" or "video"
- `file`: The media file (image or video)

**Example cURL:**
```bash
curl --location 'http://103.14.120.163:8081/api/chat/send-media' \
--header 'Authorization: Bearer {token}' \
--form 'toUserId="68ad57cdceb840899bef3405"' \
--form 'content="Check out this video!"' \
--form 'messageType="video"' \
--form 'file=@"path/to/video.mp4"'
```

### 2. Retrieve Messages with Media
- **Endpoint**: `http://103.14.120.163:8081/api/chat/enhanced-message`
- **Method**: GET
- **Headers**: 
  - `Authorization: Bearer {token}`

**Query Parameters:**
- `threadId`: Chat thread ID
- `limit`: Number of messages to retrieve (default: 50)

**Example cURL:**
```bash
curl --location 'http://103.14.120.163:8081/api/chat/enhanced-message?threadId=68dba01f97580d2a7fb39678&limit=50' \
--header 'Authorization: Bearer {token}'
```

## Implementation Details

### 1. ChatService Updates

#### New Method: `sendMediaMessage`
```dart
static Future<Map<String, dynamic>> sendMediaMessage({
  required dynamic file, // File or XFile
  required String toUserId,
  required String content,
  required String messageType, // 'image' or 'video'
  required String token,
  String? currentUserId,
}) async
```

**Features:**
- Supports both File and XFile for cross-platform compatibility
- Automatic content type detection based on file extension
- Thread management and conversation storage
- Error handling with detailed logging

#### Updated Method: `getMessagesByThreadId`
- Now uses the `enhanced-message` endpoint instead of `quick-message`
- Properly handles media messages with `mediaUrl` and `mediaInfo`
- Maintains backward compatibility with existing text messages

### 2. ChatScreen UI Updates

#### New Video Picker Button
- Added video camera icon button next to image picker
- Integrated with `ImagePicker.pickVideo()` method
- 5-minute duration limit for videos
- Proper loading states and error handling

#### Enhanced Message Display
- **Image Messages**: Clickable thumbnails that open in full-screen dialog
- **Video Messages**: Play button overlay with video info
- **Text Messages**: Unchanged, maintains existing functionality

#### New Methods Added:
- `_pickAndSendVideo()`: Handles video selection and sending
- `_sendVideoMessage()`: Processes video file and sends via API
- `_showVideoDialog()`: Displays video in modal dialog (placeholder for video player)

### 3. Media Support

#### Supported Image Formats:
- JPEG (.jpg, .jpeg)
- PNG (.png)
- GIF (.gif)

#### Supported Video Formats:
- MP4 (.mp4)
- MOV (.mov)
- AVI (.avi)
- WebM (.webm)

#### File Size Limits:
- Images: Optimized to 1920x1920 with 85% quality
- Videos: Maximum 5 minutes duration

## Usage Examples

### Sending an Image
```dart
// In ChatScreen
Future<void> _pickAndSendImage() async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1920,
    maxHeight: 1920,
    imageQuality: 85,
  );

  if (image != null) {
    await _sendImageMessage(image);
  }
}
```

### Sending a Video
```dart
// In ChatScreen
Future<void> _pickAndSendVideo() async {
  final ImagePicker picker = ImagePicker();
  final XFile? video = await picker.pickVideo(
    source: ImageSource.gallery,
    maxDuration: const Duration(minutes: 5),
  );

  if (video != null) {
    await _sendVideoMessage(video);
  }
}
```

### Retrieving Messages
```dart
// Get messages for a thread
final messages = await ChatService.getMessagesByThreadId(
  threadId: 'thread_id_here',
  token: 'auth_token_here',
);

// Check for media messages
for (final message in messages) {
  if (message.messageType == 'image' && message.mediaUrl != null) {
    // Display image
    Image.network('http://103.14.120.163:8081${message.mediaUrl}');
  } else if (message.messageType == 'video' && message.mediaUrl != null) {
    // Display video thumbnail
    // Implement video player here
  }
}
```

## API Response Format

### Send Media Response
```json
{
  "success": true,
  "message": "Message sent successfully",
  "data": {
    "message": {
      "_id": "68dba0cc97580d2a7fb39683",
      "thread": "68dba01f97580d2a7fb39678",
      "sender": {
        "_id": "68db9f8197580d2a7fb3961e",
        "username": "tetuser",
        "fullName": "Test User",
        "avatar": ""
      },
      "recipient": null,
      "content": "Check out this video!",
      "messageType": "video",
      "mediaUrl": "/uploads/68db9f8197580d2a7fb3961e/videos/68db9f8197580d2a7fb3961e_1759224012074_hpvk3ebp7.mp4",
      "mediaInfo": {
        "fileName": "68db9f8197580d2a7fb3961e_1759224012074_hpvk3ebp7.mp4",
        "originalName": "gbfg.mp4",
        "localPath": "/var/www/html/rgram_api_linux_new/public/uploads/68db9f8197580d2a7fb3961e/videos/68db9f8197580d2a7fb3961e_1759224012074_hpvk3ebp7.mp4",
        "publicUrl": "/uploads/68db9f8197580d2a7fb3961e/videos/68db9f8197580d2a7fb3961e_1759224012074_hpvk3ebp7.mp4",
        "size": 1153293,
        "mimetype": "video/mp4",
        "folder": "videos",
        "uploadedAt": "2025-09-30T09:20:12.076Z"
      },
      "isRead": false,
      "isDeleted": false,
      "reactions": [],
      "createdAt": "2025-09-30T09:20:12.085Z",
      "updatedAt": "2025-09-30T09:20:12.085Z",
      "__v": 0
    },
    "threadId": "68dba01f97580d2a7fb39678",
    "mediaInfo": {
      "fileName": "68db9f8197580d2a7fb3961e_1759224012074_hpvk3ebp7.mp4",
      "originalName": "gbfg.mp4",
      "publicUrl": "/uploads/68db9f8197580d2a7fb3961e/videos/68db9f8197580d2a7fb3961e_1759224012074_hpvk3ebp7.mp4",
      "size": 1153293,
      "mimetype": "video/mp4",
      "folder": "videos"
    }
  }
}
```

### Enhanced Message Response
```json
{
  "success": true,
  "data": {
    "messages": [
      {
        "_id": "68dba0cc97580d2a7fb39683",
        "thread": "68dba01f97580d2a7fb39678",
        "sender": {
          "_id": "68db9f8197580d2a7fb3961e",
          "username": "tetuser",
          "fullName": "Test User",
          "avatar": ""
        },
        "recipient": null,
        "content": "Check out this video!",
        "messageType": "video",
        "mediaUrl": "/uploads/68db9f8197580d2a7fb3961e/videos/68db9f8197580d2a7fb3961e_1759224012074_hpvk3ebp7.mp4",
        "mediaInfo": {
          "fileName": "68db9f8197580d2a7fb3961e_1759224012074_hpvk3ebp7.mp4",
          "originalName": "gbfg.mp4",
          "localPath": "/var/www/html/rgram_api_linux_new/public/uploads/68db9f8197580d2a7fb3961e/videos/68db9f8197580d2a7fb3961e_1759224012074_hpvk3ebp7.mp4",
          "publicUrl": "/uploads/68db9f8197580d2a7fb3961e/videos/68db9f8197580d2a7fb3961e_1759224012074_hpvk3ebp7.mp4",
          "size": 1153293,
          "mimetype": "video/mp4",
          "folder": "videos",
          "uploadedAt": "2025-09-30T09:20:12.076Z"
        },
        "isRead": false,
        "isDeleted": false,
        "reactions": [],
        "createdAt": "2025-09-30T09:20:12.085Z",
        "updatedAt": "2025-09-30T09:20:12.085Z",
        "__v": 0
      }
    ],
    "thread": {
      "_id": "68dba01f97580d2a7fb39678",
      "participants": [
        "68ad57cdceb840899bef3405",
        "68db9f8197580d2a7fb3961e"
      ],
      "lastMessageAt": "2025-09-30T09:20:12.091Z",
      "unreadCount": {
        "68ad57cdceb840899bef3405": 2
      },
      "isGroupChat": false,
      "createdAt": "2025-09-30T09:17:19.826Z",
      "updatedAt": "2025-09-30T09:20:12.092Z",
      "__v": 0,
      "lastMessage": "68dba0cc97580d2a7fb39683"
    },
    "hasMore": false
  }
}
```

## Testing

A test file `test_chat_media_integration.dart` has been created with the following test methods:

1. `testSendImage()` - Tests image sending functionality
2. `testSendVideo()` - Tests video sending functionality  
3. `testRetrieveMessages()` - Tests message retrieval with media
4. `runAllTests()` - Runs all tests sequentially

To run tests:
```dart
// In your Flutter app
await ChatMediaIntegrationTest.runAllTests();
```

## Future Enhancements

1. **Video Player Integration**: Implement actual video playback using `video_player` package
2. **Thumbnail Generation**: Generate video thumbnails for better UI
3. **File Compression**: Add video compression before sending
4. **Progress Indicators**: Show upload progress for large files
5. **Media Gallery**: Add ability to view all media in a conversation

## Dependencies

The implementation uses the following Flutter packages:
- `image_picker`: For selecting images and videos from gallery
- `http`: For API communication
- `http_parser`: For multipart form data handling

## Error Handling

The implementation includes comprehensive error handling:
- Network connectivity issues
- File selection errors
- API response errors
- File format validation
- Size limit enforcement

All errors are logged and displayed to users via SnackBar notifications.

## Security Considerations

- File type validation based on extensions
- Size limits to prevent abuse
- Authorization token validation
- Secure file upload handling

## Performance Optimizations

- Image compression before sending
- Video duration limits
- Efficient message caching
- Lazy loading of media content
- Proper memory management for large files