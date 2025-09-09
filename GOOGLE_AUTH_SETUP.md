# Google Authentication Setup

This document explains how to set up and use Google authentication in your Flutter app.

## Overview

The app now includes Google authentication functionality that integrates with your custom API endpoints. The implementation includes:

- Google sign-in button in the login screen
- Mock authentication for testing (since OAuth flow requires browser)
- Local storage of user data
- Integration with the existing auth system

## Files Modified

### 1. `lib/services/auth_service.dart`
- Added Google authentication methods
- Local storage for Google user data
- Integration with GoogleAuthService

### 2. `lib/screens/login_screen.dart`
- Connected Google button to authentication flow
- Added loading states and error handling
- User feedback with snackbars

### 3. `lib/providers/auth_provider.dart`
- Updated to manage Google authentication state
- Provider pattern for state management

### 4. `lib/main.dart`
- Updated AuthWrapper to work with Google authentication
- Proper routing based on authentication state

## How It Works

### Current Implementation (Mock)
Since implementing a full OAuth flow in Flutter requires opening a browser (which isn't available in the current setup), the app uses a mock authentication system:

1. User taps "Continue with Google" button
2. App calls `GoogleAuthService.mockGoogleAuth()`
3. Returns mock user data for testing
4. User data is stored locally
5. App navigates to interests screen

### Production Implementation
To implement real Google OAuth:

1. **Add Google Sign-In package:**
   ```yaml
   dependencies:
     google_sign_in: ^6.2.1
   ```

2. **Configure OAuth credentials:**
   - Set up Google Cloud Console project
   - Configure OAuth 2.0 credentials
   - Add SHA-1 fingerprints for Android

3. **Update GoogleAuthService:**
   - Replace mock methods with real OAuth flow
   - Handle authentication callbacks
   - Integrate with your API endpoints

## API Integration

The current setup is designed to work with your existing API endpoints:

- **Base URL:** `https://api-rgram1.vercel.app/api`
- **Endpoints:**
  - `GET /auth/google/init` - Initialize OAuth flow
  - `POST /auth/google/callback` - Complete OAuth flow

## Testing

1. Run the app
2. Navigate to login screen
3. Tap "Continue with Google" button
4. Wait for mock authentication (2 seconds)
5. Verify user data is displayed
6. Check navigation to interests screen

## User Data Stored

When a user signs in with Google, the following data is stored locally:

- User ID
- Email address
- Full name
- Username
- Avatar URL (if available)
- Authentication token

## Error Handling

The implementation includes comprehensive error handling:

- Network errors
- Authentication failures
- User feedback with snackbars
- Loading states for better UX

## Next Steps

1. **Test the current implementation** with mock data
2. **Configure real OAuth credentials** when ready for production
3. **Update API endpoints** to match your backend
4. **Add user profile creation** after successful authentication
5. **Implement token refresh** for long-term sessions

## Troubleshooting

### Common Issues

1. **Button not responding:** Check if `_isGoogleLoading` state is properly managed
2. **Navigation not working:** Verify route names in main.dart
3. **User data not persisting:** Check SharedPreferences implementation
4. **Mock authentication slow:** This is intentional (2-second delay for testing)

### Debug Information

Enable debug prints in the console to see:
- Authentication flow progress
- User data storage/retrieval
- Error messages and stack traces

## Security Considerations

- **Never store sensitive data** in SharedPreferences
- **Implement proper token validation** in production
- **Add token expiration handling**
- **Consider encrypting stored user data**
- **Implement proper logout functionality**

## Support

For issues or questions about the Google authentication implementation, check:
1. Console logs for error messages
2. Network requests in debug tools
3. SharedPreferences data in device storage
4. Provider state management
