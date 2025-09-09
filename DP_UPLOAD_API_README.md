# DP Upload API Integration - R-Gram App

This document describes the integration of the DP (Display Picture) upload API in the R-Gram Flutter app.

## API Details

### Endpoint
- **URL**: `https://api-rgram1.vercel.app/api/dp/upload`
- **Method**: `POST`
- **Content-Type**: `multipart/form-data`

### Request Parameters

#### Form Fields
- `image` (required): The image file to upload
- `userId` (required): The user ID for whom the profile picture is being uploaded

#### Headers
- `Authorization`: `Bearer {token}` - Authentication token

### Example cURL Request
```bash
curl --location 'https://api-rgram1.vercel.app/api/dp/upload' \
--form 'image=@"path/to/image.jpg"' \
--form 'userId="68b12c75d38c9af3cbcb41b3"'
```

## Response Format

### Success Response (200/201)
```json
{
    "success": true,
    "message": "DP uploaded successfully",
    "data": {
        "avatar": "https://res.cloudinary.com/dtuxhmf4t/image/upload/v1756446450/user/68b12c75d38c9af3cbcb41b3/dp/dp_68b12c75d38c9af3cbcb41b3_1756446450036.avif",
        "publicId": "user/68b12c75d38c9af3cbcb41b3/dp/dp_68b12c75d38c9af3cbcb41b3_1756446450036",
        "width": 400,
        "height": 400,
        "format": "avif",
        "size": 13973,
        "userId": "68b12c75d38c9af3cbcb41b3"
    }
}
```

### Error Responses
- **400**: Validation error (invalid file format, size, etc.)
- **401**: Authentication failed
- **403**: Access denied
- **413**: File too large
- **500**: Server error

## Implementation in Flutter

### 1. ProfilePictureService
The main service class that handles all profile picture operations:

```dart
import 'package:your_app/services/profile_picture_service.dart';

// Upload profile picture
final response = await ProfilePictureService.uploadProfilePicture(
  imageFile: selectedImageFile,
  userId: currentUserId,
  token: authToken,
);

if (response['success'] == true) {
  final avatarUrl = response['data']['avatar'];
  final publicId = response['data']['publicId'];
  // Update UI with new profile picture
}
```

### 2. Key Features
- **File Validation**: Checks file existence, size (max 10MB), and format
- **Error Handling**: Comprehensive error handling with user-friendly messages
- **Timeout Management**: 60-second timeout for upload requests
- **Cross-Platform**: Supports both mobile (File) and web (List<int>) platforms
- **Security**: Validates authentication tokens and user permissions

### 3. Supported Image Formats
- JPEG (.jpg, .jpeg)
- PNG (.png)
- GIF (.gif)
- WebP (.webp)

### 4. File Size Limits
- **Maximum**: 10MB
- **Recommended**: 1-5MB for optimal performance

## Usage Examples

### Basic Upload
```dart
// Get image from gallery or camera
final ImagePicker picker = ImagePicker();
final XFile? image = await picker.pickImage(
  source: ImageSource.gallery,
  maxWidth: 800,
  maxHeight: 800,
  imageQuality: 85,
);

if (image != null) {
  final File imageFile = File(image.path);
  
  // Upload using the service
  final response = await ProfilePictureService.uploadProfilePicture(
    imageFile: imageFile,
    userId: currentUser.id,
    token: authToken,
  );
  
  if (response['success'] == true) {
    // Success! Update UI
    setState(() {
      profileImageUrl = response['data']['avatar'];
    });
  } else {
    // Handle error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response['message'])),
    );
  }
}
```

### Integration with AuthProvider
```dart
// In your AuthProvider or similar state management
Future<void> updateProfilePicture(File imageFile) async {
  final response = await ProfilePictureService.uploadProfilePicture(
    imageFile: imageFile,
    userId: _userProfile!.id,
    token: _authToken!,
  );
  
  if (response['success'] == true) {
    // Update local user profile
    final updatedUser = _userProfile!.copyWith(
      profileImageUrl: response['data']['avatar'],
    );
    _userProfile = updatedUser;
    notifyListeners();
  }
  
  return response;
}
```

## Widget Integration

### ProfilePictureWidget
The app includes a reusable `ProfilePictureWidget` that handles:
- Image selection (gallery/camera)
- Upload progress indication
- Error handling and user feedback
- Automatic UI updates after successful upload

```dart
ProfilePictureWidget(
  userId: currentUser.id,
  token: authToken,
  currentImageUrl: currentUser.profileImageUrl,
  onImageChanged: (String newImageUrl) {
    // Handle image change
    setState(() {
      profileImageUrl = newImageUrl;
    });
  },
)
```

## Error Handling

### Common Error Scenarios
1. **Network Issues**: Connection timeout, no internet
2. **Authentication**: Invalid or expired token
3. **File Issues**: Invalid format, size too large, corrupted file
4. **Server Issues**: API endpoint unavailable, server errors

### User Feedback
- Loading indicators during upload
- Success messages on completion
- Error messages with actionable suggestions
- Retry options for failed uploads

## Testing

### Test the API
1. Use the provided cURL command with a valid image file
2. Verify the response structure matches the expected format
3. Test with different image formats and sizes
4. Test authentication with valid/invalid tokens

### Test in Flutter
1. Run the app and navigate to profile settings
2. Try uploading different types of images
3. Test error scenarios (no internet, invalid file, etc.)
4. Verify UI updates correctly after upload

## Security Considerations

- **Authentication**: All requests require valid Bearer tokens
- **File Validation**: Server-side validation of file types and sizes
- **User Isolation**: Users can only upload to their own profile
- **HTTPS**: All API communication is encrypted

## Performance Optimization

- **Image Compression**: Compress images before upload
- **Caching**: Cache uploaded images locally
- **Progressive Loading**: Show placeholder while uploading
- **Background Processing**: Handle uploads in background threads

## Troubleshooting

### Common Issues
1. **Upload Fails**: Check file format, size, and network connection
2. **Authentication Error**: Verify token is valid and not expired
3. **File Not Found**: Ensure image file exists and is accessible
4. **Timeout**: Check network speed and try with smaller images

### Debug Information
The service includes comprehensive logging for debugging:
- Request details (URL, headers, form data)
- File information (path, size, format)
- Response status and body
- Error details and stack traces

## Future Enhancements

- **Batch Upload**: Support for multiple images
- **Image Editing**: Built-in crop and filter tools
- **CDN Integration**: Optimized image delivery
- **Analytics**: Upload success rates and performance metrics

## Support

For API-related issues:
- Check the API documentation
- Verify endpoint availability
- Test with cURL or Postman
- Check server logs for errors

For Flutter integration issues:
- Review the ProfilePictureService implementation
- Check console logs for detailed error messages
- Verify authentication and user permissions
- Test with different image files and sizes

