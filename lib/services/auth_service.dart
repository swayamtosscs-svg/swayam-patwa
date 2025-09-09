import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'google_auth_service.dart';

class AuthService {
  // Dummy AuthService for non-Firebase run
  Future<void> sendOTP(String phoneNumber) async {
    // No-op
  }
  
  Future<void> verifyOTP(String otp) async {
    // No-op
  }
  
  Future<void> signOut() async {
    // No-op
  }
  
  Future<void> deleteAccount() async {
    // No-op
  }

  /// Google Sign-In using the custom API
  Future<GoogleUser?> signInWithGoogle() async {
    try {
      // Use the mock authentication for now
      // In production, you would use the actual OAuth flow
      final user = await GoogleAuthService.mockGoogleAuth();
      
      if (user != null) {
        // Store user data locally
        await _storeGoogleUser(user);
        return user;
      }
      return null;
    } catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }

  /// Store Google user data locally
  Future<void> _storeGoogleUser(GoogleUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('google_user_id', user.id);
      await prefs.setString('google_user_email', user.email);
      await prefs.setString('google_user_name', user.fullName);
      await prefs.setString('google_user_username', user.username);
      if (user.avatar != null) {
        await prefs.setString('google_user_avatar', user.avatar!);
      }
      if (user.token != null) {
        await prefs.setString('google_user_token', user.token!);
      }
    } catch (e) {
      print('Error storing Google user data: $e');
    }
  }

  /// Get stored Google user data
  Future<GoogleUser?> getStoredGoogleUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('google_user_id');
      final email = prefs.getString('google_user_email');
      final name = prefs.getString('google_user_name');
      final username = prefs.getString('google_user_username');
      final avatar = prefs.getString('google_user_avatar');
      final token = prefs.getString('google_user_token');

      if (id != null && email != null && name != null && username != null) {
        return GoogleUser(
          id: id,
          email: email,
          fullName: name,
          username: username,
          avatar: avatar,
          token: token,
        );
      }
      return null;
    } catch (e) {
      print('Error getting stored Google user data: $e');
      return null;
    }
  }

  /// Clear stored Google user data
  Future<void> clearGoogleUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('google_user_id');
      await prefs.remove('google_user_email');
      await prefs.remove('google_user_name');
      await prefs.remove('google_user_username');
      await prefs.remove('google_user_avatar');
      await prefs.remove('google_user_token');
    } catch (e) {
      print('Error clearing Google user data: $e');
    }
  }

  /// Check if user is signed in with Google
  Future<bool> isGoogleUserSignedIn() async {
    try {
      final user = await getStoredGoogleUser();
      return user != null;
    } catch (e) {
      return false;
    }
  }
} 