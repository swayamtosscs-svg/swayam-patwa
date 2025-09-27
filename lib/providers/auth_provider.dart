import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import '../models/post_model.dart'; // Fixed import path
import '../models/message_model.dart';
import 'dart:io';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  GoogleUser? _googleUser;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  
  // Restored properties for existing screens
  String? _error;
  bool _isOtpSent = false;
  String? _phoneNumber;
  String? _authToken;
  UserModel? _userProfile;
  
  // Cache for followers and following counts
  final Map<String, Map<String, dynamic>> _userCountsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5); // Cache for 5 minutes

  // Getters
  GoogleUser? get googleUser => _googleUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  bool get isOtpSent => _isOtpSent;
  String? get phoneNumber => _phoneNumber;
  String? get authToken => _authToken;
  UserModel? get userProfile => _userProfile;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await checkGoogleAuthStatus();
      await _loadAuthToken();
    } catch (e) {
      print('AuthProvider: Error during initialization: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('auth_token');
      
      if (storedToken != null && storedToken.isNotEmpty) {
        print('AuthProvider: Found stored token, attempting to restore session');
        _authToken = storedToken;
        
        // Try to load user profile with stored token
        await _loadUserProfile();
        
        if (_userProfile != null) {
          _isAuthenticated = true;
          print('AuthProvider: Session restored successfully for user: ${_userProfile?.name}');
        } else {
          print('AuthProvider: Failed to load user profile, clearing invalid token');
          await _clearAuthToken();
        }
      } else {
        print('AuthProvider: No stored token found');
        _authToken = null;
        _userProfile = null;
      }
      
      notifyListeners();
    } catch (e) {
      print('AuthProvider: Error loading auth token: $e');
      _authToken = null;
      _userProfile = null;
      notifyListeners();
    }
  }

  Future<void> _saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _authToken = token;
  }

  Future<void> _clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _authToken = null;
    _userProfile = null;
    _isAuthenticated = false; // Ensure authentication state is cleared
  }

  /// Handle successful login
  Future<void> handleSuccessfulLogin(String token, Map<String, dynamic> userData) async {
    print('AuthProvider: handleSuccessfulLogin called with token: ${token.length > 20 ? token.substring(0, 20) + '...' : token} and userData: $userData');
    
    await _saveAuthToken(token);
    print('AuthProvider: Token saved successfully');
    
    // Try to load profile from API first, fallback to userData if needed
    try {
      await _loadUserProfile();
      if (_userProfile == null) {
        // Fallback to userData if API call fails
        _userProfile = _createUserFromResponse(userData);
        print('AuthProvider: User profile created from fallback data: ${_userProfile?.name}');
      } else {
        print('AuthProvider: User profile loaded from API: ${_userProfile?.name}');
      }
    } catch (e) {
      print('AuthProvider: Error loading profile from API, using fallback: $e');
      _userProfile = _createUserFromResponse(userData);
      print('AuthProvider: User profile created from fallback data: ${_userProfile?.name}');
    }
    
    _isAuthenticated = true;
    print('AuthProvider: Authentication status set to true');
    
    notifyListeners();
    print('AuthProvider: Notified listeners of state change');
  }

  Future<void> _loadUserProfile() async {
    if (_authToken == null) return;

    try {
      // Try the new R-Gram profile API first
      final response = await ApiService.getRGramProfile(_authToken);
      if (response['success'] == true && response['data'] != null && response['data']['user'] != null) {
        // Convert response to UserModel using the new API structure
        _userProfile = _createUserFromRGramResponse(response['data']['user']);
        print('Profile loaded successfully from R-Gram API');
      } else {
        // Fallback to old API if new one fails
        final fallbackResponse = await ApiService.getProfile('current', _authToken);
        if (fallbackResponse['success'] == true) {
          _userProfile = _createUserFromResponse(fallbackResponse['data']);
          print('Profile loaded successfully from fallback API');
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
      // Try fallback API on error
      try {
        final fallbackResponse = await ApiService.getProfile('current', _authToken);
        if (fallbackResponse['success'] == true) {
          _userProfile = _createUserFromResponse(fallbackResponse['data']);
          print('Profile loaded successfully from fallback API after error');
        }
      } catch (fallbackError) {
        print('Fallback API also failed: $fallbackError');
      }
    }
  }

  UserModel _createUserFromResponse(Map<String, dynamic> data) {
    print('Creating user from fallback API data: $data');
    
    try {
      return UserModel(
        id: data['id'] ?? data['_id'] ?? '',
        name: data['fullName'] ?? data['name'] ?? '',
        email: data['email'] ?? '',
        username: data['username'],
        phoneNumber: data['phoneNumber'] ?? data['phone_number'],
        profileImageUrl: data['avatar'] ?? data['profileImageUrl'] ?? data['profile_image_url'] ?? '',
        bio: data['bio'] ?? '',
        website: data['website'],
        location: data['location'] ?? '',
        selectedReligion: data['selectedReligion'] != null 
            ? Religion.values.firstWhere(
                (e) => e.toString() == 'Religion.${data['selectedReligion']}',
                orElse: () => Religion.other,
              )
            : null,
        createdAt: data['createdAt'] != null 
            ? DateTime.parse(data['createdAt']) 
            : DateTime.now(),
        lastActive: data['lastActive'] != null 
            ? DateTime.parse(data['lastActive']) 
            : DateTime.now(),
        verificationStatus: UserVerificationStatus.values.firstWhere(
          (e) => e.toString() == 'UserVerificationStatus.${data['verificationStatus'] ?? 'unverified'}',
          orElse: () => UserVerificationStatus.unverified,
        ),
        followersCount: data['followersCount'] ?? data['followers_count'] ?? 0,
        followingCount: data['followingCount'] ?? data['following_count'] ?? 0,
        postsCount: data['postsCount'] ?? data['posts_count'] ?? 0,
        reelsCount: data['reelsCount'] ?? data['reels_count'] ?? 0,
        followers: List<String>.from(data['followers'] ?? []),
        following: List<String>.from(data['following'] ?? []),
        isOnline: data['isOnline'] ?? data['is_online'] ?? false,
        isPrivate: data['isPrivate'] ?? data['is_private'] ?? false,
        isEmailVerified: data['isEmailVerified'] ?? data['is_email_verified'] ?? false,
        isVerified: data['isVerified'] ?? data['is_verified'] ?? false,
        preferences: data['preferences'] ?? {},
      );
    } catch (e) {
      print('Error creating user model from fallback API: $e');
      // Return a default user model if parsing fails
      return UserModel(
        id: data['id'] ?? data['_id'] ?? 'default_id',
        name: data['fullName'] ?? data['name'] ?? 'User',
        email: data['email'] ?? 'user@example.com',
        username: data['username'] ?? 'user',
        phoneNumber: null,
        profileImageUrl: null,
        bio: null,
        website: null,
        location: null,
        selectedReligion: null,
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        verificationStatus: UserVerificationStatus.unverified,
        followersCount: 0,
        followingCount: 0,
        postsCount: 0,
        reelsCount: 0,
        followers: [],
        following: [],
        isOnline: false,
        isPrivate: false,
        isEmailVerified: false,
        isVerified: false,
        preferences: {},
      );
    }
  }

  UserModel _createUserFromRGramResponse(Map<String, dynamic> data) {
    print('Creating user from R-Gram API data: $data');
    
    try {
      return UserModel(
        id: data['id'] ?? data['_id'] ?? '',
        name: data['fullName'] ?? data['name'] ?? '',
        email: data['email'] ?? '',
        username: data['username'],
        phoneNumber: data['phoneNumber'] ?? data['phone_number'],
        profileImageUrl: data['avatar'] ?? data['profileImageUrl'] ?? data['profile_image_url'] ?? '',
        bio: data['bio'] ?? '',
        website: data['website'],
        location: data['location'] ?? '',
        selectedReligion: data['religion'] != null 
            ? Religion.values.firstWhere(
                (e) => e.toString() == 'Religion.${data['religion']}',
                orElse: () => Religion.other,
              )
            : null,
        createdAt: data['createdAt'] != null 
            ? DateTime.parse(data['createdAt']) 
            : DateTime.now(),
        lastActive: data['lastActive'] != null 
            ? DateTime.parse(data['lastActive']) 
            : DateTime.now(),
        verificationStatus: UserVerificationStatus.values.firstWhere(
          (e) => e.toString() == 'UserVerificationStatus.${data['isVerified'] ?? 'unverified'}',
          orElse: () => UserVerificationStatus.unverified,
        ),
        followersCount: data['followersCount'] ?? data['followers_count'] ?? 0,
        followingCount: data['followingCount'] ?? data['following_count'] ?? 0,
        postsCount: data['postsCount'] ?? data['posts_count'] ?? 0,
        reelsCount: data['reelsCount'] ?? data['reels_count'] ?? 0,
        followers: List<String>.from(data['followers'] ?? []),
        following: List<String>.from(data['following'] ?? []),
        isOnline: data['isOnline'] ?? data['is_online'] ?? false,
        isPrivate: data['isPrivate'] ?? data['is_private'] ?? false,
        isEmailVerified: data['isEmailVerified'] ?? data['is_email_verified'] ?? false,
        isVerified: data['isVerified'] ?? data['is_verified'] ?? false,
        preferences: data['preferences'] ?? {},
      );
    } catch (e) {
      print('Error creating user model from R-Gram API: $e');
      // Return a default user model if parsing fails
      return UserModel(
        id: data['id'] ?? data['_id'] ?? 'default_id',
        name: data['fullName'] ?? data['name'] ?? 'User',
        email: data['email'] ?? 'user@example.com',
        username: data['username'] ?? 'user',
        phoneNumber: null,
        profileImageUrl: null,
        bio: null,
        website: null,
        location: null,
        selectedReligion: null,
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        verificationStatus: UserVerificationStatus.unverified,
        followersCount: 0,
        followingCount: 0,
        postsCount: 0,
        reelsCount: 0,
        followers: [],
        following: [],
        isOnline: false,
        isPrivate: false,
        isEmailVerified: false,
        isVerified: false,
        preferences: {},
      );
    }
  }

  Future<void> checkGoogleAuthStatus() async {
    try {
      final user = await _authService.getStoredGoogleUser();
      _googleUser = user;
      _isAuthenticated = user != null;
      notifyListeners();
    } catch (e) {
      print('Error checking auth status: $e');
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      final user = await _authService.signInWithGoogle();
      
      if (user != null) {
        _googleUser = user;
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Google sign-in error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _authService.clearGoogleUserData();
      _googleUser = null;
      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      print('Sign-out error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Restored methods for existing screens
  Future<void> sendOTP(String phoneNumber) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.sendOTP(phoneNumber);
      if (response['success'] == true) {
        _phoneNumber = phoneNumber;
        _isOtpSent = true;
      } else {
        _error = response['message'] ?? 'Failed to send OTP';
      }
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> verifyOTP(String otp) async {
    if (_phoneNumber == null) {
      _error = 'Phone number not found';
      return;
    }

    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.verifyOTP(_phoneNumber!, otp);
      if (response['success'] == true) {
        await _saveAuthToken(response['token']);
        await _loadUserProfile();
        _isOtpSent = false;
        _isAuthenticated = true;
      } else {
        _error = response['message'] ?? 'Invalid OTP';
      }
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.login(email, password);
      if (response['success'] == true) {
        await _saveAuthToken(response['token']);
        await _loadUserProfile();
        _isAuthenticated = true;
      } else {
        _error = response['message'] ?? 'Invalid credentials';
      }
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signup(Map<String, dynamic> userData) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.signup(userData);
      if (response['success'] == true) {
        await _saveAuthToken(response['token']);
        await _loadUserProfile();
        _isAuthenticated = true;
      } else {
        _error = response['message'] ?? 'Failed to create account';
      }
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createUserProfile({
    required String name,
    required String email,
    Religion? selectedReligion,
    String? bio,
    String? location,
  }) async {
    if (_authToken == null) return;

    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.updateProfile('current', {
        'name': name,
        'email': email,
        'selected_religion': selectedReligion?.toString().split('.').last,
        'bio': bio,
        'location': location,
      }, _authToken);

      if (response['success'] == true) {
        await _loadUserProfile();
      } else {
        _error = response['message'] ?? 'Failed to update profile';
      }
    } catch (e) {
      _error = 'Network error: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    print('AuthProvider: Logging out user');
    
    // Store token and userId before clearing them
    final tokenToLogout = _authToken;
    final userIdToLogout = _userProfile?.id;
    
    // Immediately clear local authentication state
    _isAuthenticated = false;
    _authToken = null;
    _userProfile = null;
    notifyListeners();
    
    // Clear local storage immediately
    await _clearAuthToken();
    
    // Call logout API in background (don't wait for it) - use stored values
    if (tokenToLogout != null && userIdToLogout != null) {
      try {
        ApiService.logoutRGram(
          token: tokenToLogout,
          userId: userIdToLogout,
        ).catchError((e) {
          print('Background logout API error: $e');
        });
      } catch (e) {
        print('Error calling logout API: $e');
      }
    }
    
    print('AuthProvider: Logout completed (local state cleared)');
  }

  /// Logout and show login screen
  Future<void> logoutAndShowSignup() async {
    await logout();
    // The AuthWrapper will automatically show the login screen
    // since isAuthenticated is now false
  }

  void updateSelectedReligion(String religion) {
    // Convert string to Religion enum
    Religion? religionEnum;
    try {
      religionEnum = Religion.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == religion.toLowerCase(),
      );
    } catch (e) {
      // If religion not found in enum, set to other
      religionEnum = Religion.other;
    }
    
    // Update user profile with selected religion
    if (_userProfile != null) {
      _userProfile = _userProfile!.copyWith(selectedReligion: religionEnum);
    }
    
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> refreshUserData() async {
    await checkGoogleAuthStatus();
  }

  /// Refresh user profile data from the API
  Future<void> refreshUserProfile() async {
    if (_authToken != null) {
      await _loadUserProfile();
      notifyListeners();
    }
  }

  /// Get user profile from API (public method)
  Future<UserModel?> fetchUserProfile() async {
    if (_authToken == null) return null;
    
    try {
      await _loadUserProfile();
      return _userProfile;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  /// Update local user profile (for immediate UI updates)
  void updateLocalUserProfile(UserModel updatedUser) {
    _userProfile = updatedUser;
    notifyListeners();
  }

  /// Update user profile using R-Gram API
  Future<bool> updateUserProfile({
    String? fullName,
    String? bio,
    String? website,
    String? location,
    String? religion,
    bool? isPrivate,
  }) async {
    if (_authToken == null) return false;

    _setLoading(true);
    _error = null;

    try {
      // Prepare update data - only include non-null and non-empty values
      final updateData = <String, dynamic>{};
      if (fullName != null && fullName.trim().isNotEmpty) {
        updateData['fullName'] = fullName.trim();
      }
      if (bio != null && bio.trim().isNotEmpty) {
        updateData['bio'] = bio.trim();
      } else if (bio != null) {
        // If bio is explicitly set to empty, send empty string
        updateData['bio'] = '';
      }
      if (website != null && website.trim().isNotEmpty) {
        updateData['website'] = website.trim();
      } else if (website != null) {
        // If website is explicitly set to empty, send empty string
        updateData['website'] = '';
      }
      if (location != null && location.trim().isNotEmpty) {
        updateData['location'] = location.trim();
      } else if (location != null) {
        // If location is explicitly set to empty, send empty string
        updateData['location'] = '';
      }
      if (religion != null) {
        updateData['religion'] = religion;
      }
      if (isPrivate != null) {
        updateData['isPrivate'] = isPrivate;
      }

      // Don't proceed if no data to update
      if (updateData.isEmpty) {
        _error = 'No changes to update';
        return false;
      }

      print('Updating profile with data: $updateData');

      // Call the R-Gram update API
      final response = await ApiService.updateRGramProfile(
        profileData: updateData,
        token: _authToken!,
      );

      if (response['success'] == true && response['data'] != null && response['data']['user'] != null) {
        // Update the local user profile with new data
        _userProfile = _createUserFromRGramResponse(response['data']['user']);
        print('Profile updated successfully from R-Gram API');
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to update profile';
        print('Profile update failed: ${response['message']}');
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      print('Profile update error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get saved posts from API
  Future<List<Map<String, dynamic>>> getSavedPosts() async {
    if (_authToken == null) return [];

    try {
      // For now, return empty list since we don't have a saved posts API yet
      // This can be implemented when you add a saved posts API endpoint
      print('Saved posts API not implemented yet');
      return [];
    } catch (e) {
      print('Error loading saved posts: $e');
      return [];
    }
  }

  /// Search users using R-Gram API
  Future<List<Map<String, dynamic>>> searchUsers(String query, {int page = 1, int limit = 10}) async {
    if (_authToken == null) return [];

    try {
      final response = await ApiService.searchRGramUsers(
        query: query,
        token: _authToken!,
        page: page,
        limit: limit,
      );
      
      if (response['success'] == true && response['data'] != null) {
        final users = List<Map<String, dynamic>>.from(response['data']['users'] ?? []);
        print('Search found ${users.length} users for query: $query');
        return users;
      } else {
        print('Search failed: ${response['message']}');
        return [];
      }
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  /// Get posts for a specific user
  Future<List<Map<String, dynamic>>> getUserPosts(String userId, {int page = 1, int limit = 20}) async {
    if (_authToken == null) return [];

    try {
      final response = await ApiService.getPosts(userId, _authToken!, page: page, limit: limit);
      
      if (response['success'] == true && response['data'] != null) {
        final posts = List<Map<String, dynamic>>.from(response['data']['posts'] ?? []);
        print('Loaded ${posts.length} posts for user: $userId');
        return posts;
      } else {
        print('Failed to load user posts: ${response['message']}');
        return [];
      }
    } catch (e) {
      print('Error loading user posts: $e');
      return [];
    }
  }

  /// Follow a user using R-Gram API
  Future<bool> followUser(String targetUserId) async {
    if (_authToken == null) {
      _error = 'Please login to follow users';
      return false;
    }

    try {
      final response = await ApiService.followRGramUser(
        targetUserId: targetUserId,
        token: _authToken!,
      );

      if (response['success'] == true) {
        // Refresh own profile to update following count
        await _loadUserProfile();
        
        // Update local following count immediately for better UX
        if (_userProfile != null) {
          _userProfile = _userProfile!.copyWith(
            followingCount: _userProfile!.followingCount + 1,
          );
        }
        
        // Clear cache for the target user to ensure fresh data
        clearUserCache(targetUserId);
        
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to follow user';
        print('Follow user failed: ${response['message']}');
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      print('Follow user error: $e');
      return false;
    }
  }

  /// Unfollow a user using R-Gram API
  Future<bool> unfollowUser(String targetUserId) async {
    if (_authToken == null) {
      _error = 'Please login to unfollow users';
      return false;
    }

    try {
      final response = await ApiService.unfollowRGramUser(
        targetUserId: targetUserId,
        token: _authToken!,
      );

      if (response['success'] == true) {
        // Refresh own profile to update following count
        await _loadUserProfile();
        
        // Update local following count immediately for better UX
        if (_userProfile != null) {
          _userProfile = _userProfile!.copyWith(
            followingCount: (_userProfile!.followingCount - 1).clamp(0, double.infinity).toInt(),
          );
        }
        
        // Clear cache for the target user to ensure fresh data
        clearUserCache(targetUserId);
        
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to unfollow user';
        print('Unfollow user failed: ${response['message']}');
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      print('Unfollow user error: $e');
      return false;
    }
  }





  /// Toggle user account privacy (public/private) using R-Gram API
  Future<bool> toggleAccountPrivacy() async {
    if (_authToken == null || _userProfile == null) return false;

    _setLoading(true);
    _error = null;

    try {
      final response = await ApiService.toggleUserPrivacy(
        userId: _userProfile!.id,
        token: _authToken!,
      );

      if (response['success'] == true && response['data'] != null) {
        // Update the local user profile with new privacy status
        final newPrivacyStatus = response['data']['isPrivate'] ?? false;
        final newProfileVisibility = response['data']['profileVisibility'] ?? 'public';
        
        _userProfile = _userProfile!.copyWith(
          isPrivate: newPrivacyStatus,
        );
        
        print('Privacy toggled successfully. New status: ${newPrivacyStatus ? 'private' : 'public'}');
        print('Profile visibility: $newProfileVisibility');
        
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Failed to toggle privacy';
        print('Privacy toggle failed: ${response['message']}');
        return false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      print('Privacy toggle error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Send a message to another user
  Future<SendMessageResponse?> sendMessage({
    required String toUserId,
    required String content,
    String messageType = 'text',
  }) async {
    if (_authToken == null) return null;

    try {
      final response = await ApiService.sendMessage(
        toUserId: toUserId,
        content: content,
        messageType: messageType,
        token: _authToken!,
      );

      if (response['success'] == true) {
        return SendMessageResponse.fromJson(response);
      } else {
        _error = response['message'] ?? 'Failed to send message';
        return null;
      }
    } catch (e) {
      _error = 'Network error: $e';
      return null;
    }
  }

  /// Get messages from a specific thread
  Future<MessageResponse?> getMessages({
    required String threadId,
    int limit = 20,
  }) async {
    if (_authToken == null) return null;

    try {
      final response = await ApiService.getMessages(
        threadId: threadId,
        token: _authToken!,
        limit: limit,
      );

      if (response['success'] == true) {
        return MessageResponse.fromJson(response);
      } else {
        _error = response['message'] ?? 'Failed to get messages';
        return null;
      }
    } catch (e) {
      _error = 'Network error: $e';
      return null;
    }
  }

  /// Get list of users that the current user follows
  Future<List<Map<String, dynamic>>> getFollowingUsers() async {
    if (_authToken == null || _userProfile == null) return [];

    try {
      final response = await ApiService.getRGramFollowing(
        userId: _userProfile!.id,
        token: _authToken!,
      );

      if (response['success'] == true && response['data'] != null) {
        final following = List<Map<String, dynamic>>.from(response['data']['following'] ?? []);
        print('Loaded ${following.length} following users');
        return following;
      } else {
        print('Failed to load following users: ${response['message']}');
        return [];
      }
    } catch (e) {
      print('Error loading following users: $e');
      return [];
    }
  }

  /// Get list of users that a specific user follows
  Future<List<Map<String, dynamic>>> getFollowingUsersForUser(String userId) async {
    if (_authToken == null) return [];

    try {
      final response = await ApiService.getRGramFollowing(
        userId: userId,
        token: _authToken!,
      );

      if (response['success'] == true && response['data'] != null) {
        final following = List<Map<String, dynamic>>.from(response['data']['following'] ?? []);
        print('Loaded ${following.length} following users for user $userId');
        return following;
      } else {
        print('Failed to load following users for user $userId: ${response['message']}');
        return [];
      }
    } catch (e) {
      print('Error loading following users for user $userId: $e');
      return [];
    }
  }

  /// Get list of users that follow the current user
  Future<List<Map<String, dynamic>>> getFollowers() async {
    if (_authToken == null || _userProfile == null) return [];

    try {
      final response = await ApiService.getRGramFollowers(
        userId: _userProfile!.id,
        token: _authToken!,
      );

      if (response['success'] == true && response['data'] != null) {
        final followers = List<Map<String, dynamic>>.from(response['data']['followers'] ?? []);
        print('Loaded ${followers.length} followers');
        return followers;
      } else {
        print('Failed to load followers: ${response['message']}');
        return [];
      }
    } catch (e) {
      print('Error loading followers: $e');
      return [];
    }
  }

  /// Check if cached data is still valid
  bool _isCacheValid(String userId) {
    final timestamp = _cacheTimestamps[userId];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  /// Get cached followers and following counts
  Map<String, int>? _getCachedCounts(String userId) {
    if (!_isCacheValid(userId)) return null;
    final cached = _userCountsCache[userId];
    if (cached == null) return null;
    return {
      'followers': cached['followers'] ?? 0,
      'following': cached['following'] ?? 0,
    };
  }

  /// Cache followers and following counts
  void _cacheCounts(String userId, int followersCount, int followingCount) {
    _userCountsCache[userId] = {
      'followers': followersCount,
      'following': followingCount,
    };
    _cacheTimestamps[userId] = DateTime.now();
  }

  /// Clear cache for a specific user (useful after follow/unfollow actions)
  void clearUserCache(String userId) {
    _userCountsCache.remove(userId);
    _cacheTimestamps.remove(userId);
    print('Cleared cache for user: $userId');
  }

  /// Clear all cached data
  void clearAllCache() {
    _userCountsCache.clear();
    _cacheTimestamps.clear();
    print('Cleared all cached data');
  }

  /// Get list of users that follow a specific user
  Future<List<Map<String, dynamic>>> getFollowersForUser(String userId) async {
    if (_authToken == null) return [];

    try {
      final response = await ApiService.getRGramFollowers(
        userId: userId,
        token: _authToken!,
      );

      if (kDebugMode) {
        print('Followers API response for user $userId: $response');
      }

      if (response['success'] == true && response['data'] != null) {
        final followers = List<Map<String, dynamic>>.from(response['data']['followers'] ?? []);
        print('Loaded ${followers.length} followers for user $userId');
        
        // Debug: Print first user data structure
        if (followers.isNotEmpty) {
          print('First follower data for user $userId: ${followers.first}');
          print('Available keys: ${followers.first.keys.toList()}');
        }
        
        return followers;
      } else {
        print('Failed to load followers for user $userId: ${response['message']}');
        return [];
      }
    } catch (e) {
      print('Error loading followers for user $userId: $e');
      return [];
    }
  }

  /// Check if the current user is following a specific target user
  Future<bool> isFollowingUser(String targetUserId) async {
    if (_authToken == null || _userProfile == null) return false;

    try {
      // First try to use the direct API call for better performance
      final response = await ApiService.checkRGramFollowStatus(
        targetUserId: targetUserId,
        token: _authToken!,
      );
      
      if (response['success'] == true && response['data'] != null) {
        final isFollowing = response['data']['isFollowing'] ?? false;
        if (kDebugMode) {
          print('Direct API check: Following user $targetUserId: $isFollowing');
        }
        return isFollowing;
      }
      
      // Fallback to checking the following list if direct API fails
      if (kDebugMode) {
        print('Direct API failed, falling back to following list check');
      }
      
      final following = await getFollowingUsers();
      
      // Check if the target user ID exists in the following list
      final isFollowing = following.any((user) => 
        (user['_id'] ?? user['id']) == targetUserId
      );
      
      if (kDebugMode) {
        print('Following list check: Following user $targetUserId: $isFollowing');
        print('Current following list: ${following.map((u) => u['_id'] ?? u['id']).toList()}');
      }
      
      return isFollowing;
    } catch (e) {
      print('Error checking if following user $targetUserId: $e');
      return false;
    }
  }

  /// Get followers and following counts with caching for better performance
  Future<Map<String, int>> getUserCounts(String userId) async {
    if (_authToken == null) return {'followers': 0, 'following': 0};

    // Check cache first
    final cachedCounts = _getCachedCounts(userId);
    if (cachedCounts != null) {
      print('Using cached counts for user $userId: $cachedCounts');
      return cachedCounts;
    }

    try {
      // Get both followers and following counts in parallel
      final futures = await Future.wait([
        ApiService.getRGramFollowers(userId: userId, token: _authToken!),
        ApiService.getRGramFollowing(userId: userId, token: _authToken!),
      ]);

      final followersResponse = futures[0];
      final followingResponse = futures[1];

      int followersCount = 0;
      int followingCount = 0;

      if (followersResponse['success'] == true && followersResponse['data'] != null) {
        final followers = List<Map<String, dynamic>>.from(followersResponse['data']['followers'] ?? []);
        followersCount = followers.length;
      }

      if (followingResponse['success'] == true && followingResponse['data'] != null) {
        final following = List<Map<String, dynamic>>.from(followingResponse['data']['following'] ?? []);
        followingCount = following.length;
      }

      // Cache the results
      _cacheCounts(userId, followersCount, followingCount);

      print('Fetched and cached counts for user $userId: followers=$followersCount, following=$followingCount');
      
      return {
        'followers': followersCount,
        'following': followingCount,
      };
    } catch (e) {
      print('Error fetching counts for user $userId: $e');
      return {'followers': 0, 'following': 0};
    }
  }

  /// Refresh follower and following counts for a specific user
  Future<Map<String, int>> refreshUserCounts(String userId) async {
    if (_authToken == null) return {'followers': 0, 'following': 0};

    try {
      // Get both followers and following counts
      final followersResponse = await ApiService.getRGramFollowers(
        userId: userId,
        token: _authToken!,
      );
      
      final followingResponse = await ApiService.getRGramFollowing(
        userId: userId,
        token: _authToken!,
      );

      int followersCount = 0;
      int followingCount = 0;

      if (followersResponse['success'] == true && followersResponse['data'] != null) {
        final followers = List<Map<String, dynamic>>.from(followersResponse['data']['followers'] ?? []);
        followersCount = followers.length;
      }

      if (followingResponse['success'] == true && followingResponse['data'] != null) {
        final following = List<Map<String, dynamic>>.from(followingResponse['data']['following'] ?? []);
        followingCount = following.length;
      }

      print('Refreshed counts for user $userId: followers=$followersCount, following=$followingCount');
      
      return {
        'followers': followersCount,
        'following': followingCount,
      };
    } catch (e) {
      print('Error refreshing counts for user $userId: $e');
      return {'followers': 0, 'following': 0};
    }
  }


  /// Create a Post object from API response data
  Post _createPostFromData(Map<String, dynamic> postData) {
    return Post(
      id: postData['id'] ?? postData['_id'] ?? '',
      userId: postData['userId'] ?? postData['user_id'] ?? '',
      username: postData['username'] ?? '',
      userAvatar: postData['userAvatar'] ?? postData['user_avatar'] ?? '',
      caption: postData['caption'] ?? '',
      imageUrl: postData['imageUrl'] ?? postData['image_url'],
      videoUrl: postData['videoUrl'] ?? postData['video_url'],
      type: _parsePostType(postData['type'] ?? 'image'),
      likes: postData['likes'] ?? postData['likesCount'] ?? 0,
      comments: postData['comments'] ?? postData['commentsCount'] ?? 0,
      shares: postData['shares'] ?? postData['sharesCount'] ?? 0,
      createdAt: postData['createdAt'] != null 
          ? DateTime.parse(postData['createdAt']) 
          : DateTime.now(),
      hashtags: List<String>.from(postData['hashtags'] ?? []),
    );
  }

  /// Parse post type from string
  PostType _parsePostType(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return PostType.image;
      case 'video':
        return PostType.video;
      case 'reel':
        return PostType.reel;
      default:
        return PostType.image;
    }
  }



} 