# Profile Picture Management - R-Gram App

This document describes the implementation of profile picture upload, retrieve, and delete functionality in the R-Gram Flutter app using the provided APIs.

## Features

- **Upload Profile Picture**: Choose from gallery or take a photo
- **Retrieve Profile Picture**: Display current profile picture
- **Delete Profile Picture**: Remove existing profile picture
- **Real-time Updates**: UI updates automatically after operations
- **Error Handling**: Comprehensive error handling with user feedback

## API Endpoints Used

### 1. Upload Profile Picture
- **URL**: `https://api-rgram1.vercel.app/api/dp/upload`
- **Method**: `POST`
- **Headers**: `Authorization: Bearer {token}`
- **Body**: Multipart form data with `dp` (image file) and `userId`

### 2. Retrieve Profile Picture
- **URL**: `https://api-rgram1.vercel.app/api/dp/retrieve-simple?userId={userId}`
- **Method**: `GET`
- **Headers**: `Authorization: Bearer {token}` (optional)

### 3. Delete Profile Picture
- **URL**: `https://api-rgram1.vercel.app/api/dp/delete-simple`
- **Method**: `DELETE`
- **Headers**: `Authorization: Bearer {token}`, `Content-Type: application/json`
- **Body**: JSON with `publicId` and `deleteFromCloudinary` flag

## Implementation Files

### 1. Profile Picture Service (`lib/services/profile_picture_service.dart`)
- Handles all API calls for profile picture operations
- Manages multipart form data for image uploads
- Provides error handling and response parsing

### 2. Profile Picture Widget (`lib/widgets/profile_picture_widget.dart`)
- Reusable UI component for profile picture display and management
- Includes camera icon overlay for editing options
- Supports custom sizing and border colors
- Handles image picker integration

### 3. Models (`lib/services/profile_picture_service.dart`)
- `ProfilePictureData`: Data model for profile picture information
- `ProfilePictureResponse`: API response wrapper

## Integration Points

### Profile Screen (`lib/screens/profile_screen.dart`)
- Main profile display with integrated profile picture widget
- Automatically updates when profile picture changes

### Profile Edit Screen (`lib/screens/profile_edit_screen.dart`)
- Profile editing interface with profile picture management
- Replaces the old static image display

### Test Screen (`lib/screens/profile_picture_test_screen.dart`)
- Standalone testing interface for profile picture functionality
- Useful for development and testing

## Usage

### Basic Implementation

```dart
ProfilePictureWidget(
  currentImageUrl: user.profileImageUrl,
  userId: user.id,
  token: authProvider.authToken ?? '',
  onImageChanged: (String newImageUrl) {
    // Handle image change
    setState(() {
      user.profileImageUrl = newImageUrl;
    });
  },
  size: 120,
  borderColor: Colors.blue,
  showEditButton: true,
)
```

### Manual API Calls

```dart
// Upload profile picture
final response = await ProfilePictureService.uploadProfilePicture(
  imageFile: imageFile,
  userId: userId,
  token: token,
);

// Retrieve profile picture
final response = await ProfilePictureService.retrieveProfilePicture(
  userId: userId,
  token: token,
);

// Delete profile picture
final response = await ProfilePictureService.deleteProfilePicture(
  publicId: publicId,
  token: token,
);
```

## Dependencies

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.4.0
  http_parser: ^4.0.2
  image_picker: ^1.1.2
```

## Features

### Image Upload
- Supports both gallery and camera sources
- Automatic image compression (800x800 max, 85% quality)
- Progress indicators during upload
- Error handling with user-friendly messages

### Image Management
- Tap camera icon to access options
- Choose from gallery or take photo
- Delete existing profile picture
- Confirmation dialogs for destructive actions

### UI/UX
- Circular profile picture with customizable border
- Religion-based color theming
- Loading states and error feedback
- Responsive design with custom sizing

## Error Handling

The implementation includes comprehensive error handling:

- Network errors
- API response errors
- File picker errors
- Permission errors
- User feedback through snackbars

## Security

- Authentication token required for all operations
- Secure file upload handling
- Input validation and sanitization
- Error messages don't expose sensitive information

## Testing

Use the `ProfilePictureTestScreen` to test all functionality:

1. Navigate to the test screen
2. Test upload from gallery
3. Test camera capture
4. Test delete functionality
5. Verify real-time updates

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure camera and storage permissions are granted
2. **Upload Failed**: Check authentication token and network connectivity
3. **Image Not Displaying**: Verify image URL format and network access
4. **Delete Not Working**: Ensure `publicId` is correctly retrieved

### Debug Information

Enable debug logging by checking console output for:
- API request/response details
- Error messages and stack traces
- Image processing information

## Future Enhancements

- Image cropping and editing
- Multiple image format support
- Image caching and optimization
- Batch operations
- Image filters and effects
- Backup and restore functionality

## Support

For issues or questions regarding the profile picture functionality:
1. Check the console logs for error details
2. Verify API endpoint accessibility
3. Ensure proper authentication setup
4. Test with the provided test screen

