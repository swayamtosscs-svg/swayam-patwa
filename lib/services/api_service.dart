import 'dart:convert';
import 'package:http/http.dart' as http;
// Note: No model imports required in this service file

class ApiService {
  static const String baseUrl = 'http://103.14.120.163:8081';
  static const String reelApiUrl = 'http://103.14.120.163:8081/api';
  static const String authApiUrl = 'http://103.14.120.163:8081/api/auth';
  
  // Headers
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  static Map<String, String> _authHeaders(String? token) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  // Reel Upload API
  static Future<Map<String, dynamic>> uploadReel({
    required String content,
    required String videoUrl,
    required String thumbnail,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$reelApiUrl/upload/reel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token, // Note: This API uses token directly, not Bearer
        },
        body: jsonEncode({
          'content': content,
          'videoUrl': videoUrl,
          'thumbnail': thumbnail,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Authentication APIs
  static Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send-otp.php'),
        headers: _headers,
        body: jsonEncode({
          'phone_number': phoneNumber,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> verifyOTP(String phoneNumber, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-otp.php'),
        headers: _headers,
        body: jsonEncode({
          'phone_number': phoneNumber,
          'otp': otp,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login.php'),
        headers: _headers,
        body: jsonEncode({
          'gmail': email,
          'password': password,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> signup(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signup.php'),
        headers: _headers,
        body: jsonEncode(userData),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Profile APIs
  static Future<Map<String, dynamic>> getProfile(String userId, String? token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile.php?user_id=$userId'),
        headers: _authHeaders(token),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // New Profile Retrieval API for R-Gram
  static Future<Map<String, dynamic>> getRGramProfile(String? token) async {
    try {
      final response = await http.get(
        Uri.parse('http://103.14.120.163:8081/api/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': token, // Note: This API uses token directly, not Bearer
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // New Profile Update API for R-Gram
  static Future<Map<String, dynamic>> updateRGramProfile({
    required Map<String, dynamic> profileData,
    required String token,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('http://103.14.120.163:8081/api/user/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token, // Note: This API uses token directly, not Bearer
        },
        body: jsonEncode(profileData),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // New Privacy Toggle API for R-Gram
  static Future<Map<String, dynamic>> toggleUserPrivacy({
    required String userId,
    required String token,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('http://103.14.120.163:8081/api/user/toggle-privacy-by-id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Note: This API uses Bearer token
        },
        body: jsonEncode({
          'userId': userId,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Send Message API for R-Gram
  static Future<Map<String, dynamic>> sendMessage({
    required String toUserId,
    required String content,
    required String messageType,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('http://103.14.120.163:8081/api/chat/quick-message'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'toUserId': toUserId,
          'content': content,
          'messageType': messageType,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Receive Messages API for R-Gram
  static Future<Map<String, dynamic>> getMessages({
    required String threadId,
    required String token,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('http://103.14.120.163:8081/api/chat/quick-message?threadId=$threadId&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateProfile(String userId, Map<String, dynamic> profileData, String? token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update-profile.php'),
        headers: _authHeaders(token),
        body: jsonEncode({
          'user_id': userId,
          ...profileData,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Feed APIs
  static Future<Map<String, dynamic>> getFeed(String? token, {int page = 1, int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/feed.php?page=$page&limit=$limit'),
        headers: _authHeaders(token),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Post APIs
  static Future<Map<String, dynamic>> createPost(Map<String, dynamic> postData, String? token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create-post.php'),
        headers: _authHeaders(token),
        body: jsonEncode(postData),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getPosts(String userId, String? token, {int page = 1, int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts.php?user_id=$userId&page=$page&limit=$limit'),
        headers: _authHeaders(token),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Story APIs
  static Future<Map<String, dynamic>> uploadStory({
    required String media,
    required String type,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$reelApiUrl/upload/story'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token, // Note: This API uses token directly, not Bearer
        },
        body: jsonEncode({
          'media': media,
          'type': type,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> createStory(Map<String, dynamic> storyData, String? token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create-story.php'),
        headers: _authHeaders(token),
        body: jsonEncode(storyData),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getStories(String? token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stories.php'),
        headers: _authHeaders(token),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Search APIs
  static Future<Map<String, dynamic>> searchUsers(String query, String? token, {int page = 1, int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search-users.php?q=$query&page=$page&limit=$limit'),
        headers: _authHeaders(token),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // New R-Gram Search Users API
  static Future<Map<String, dynamic>> searchRGramUsers({
    required String query,
    required String token,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('http://103.14.120.163:8081/api/search?q=$query&type=users&page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Note: This API uses Bearer token
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Notification APIs
  static Future<Map<String, dynamic>> getNotifications(String? token, {int page = 1, int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications.php?page=$page&limit=$limit'),
        headers: _authHeaders(token),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // New R-Gram Follow/Unfollow APIs
  static Future<Map<String, dynamic>> followRGramUser({
    required String targetUserId,
    required String token,
  }) async {
    // Try main API first
    try {
      final response = await http.post(
        Uri.parse('http://103.14.120.163:8081/api/follow/$targetUserId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      print('Follow API response status: ${response.statusCode}');
      print('Follow API response body: ${response.body}');
      
      // Check if response is JSON
      if (response.headers['content-type']?.contains('application/json') == true) {
        return jsonDecode(response.body);
      } else {
        // Handle non-JSON response (HTML error page, etc.)
        if (response.statusCode == 404) {
          return {'success': false, 'message': 'Follow endpoint not found. Please try again later.'};
        } else if (response.statusCode == 401) {
          return {'success': false, 'message': 'Authentication failed. Please login again.'};
        } else if (response.statusCode == 500) {
          return {'success': false, 'message': 'Server error. Please try again later.'};
        } else {
          return {'success': false, 'message': 'Unexpected response from server. Please try again.'};
        }
      }
    } catch (e) {
      print('Follow API error: $e');
      
      // Try alternative endpoint if main one fails
      try {
        print('Trying alternative follow endpoint...');
        final altResponse = await http.post(
          Uri.parse('$baseUrl/follow-user.php'),
          headers: _authHeaders(token),
          body: jsonEncode({'target_user_id': targetUserId}),
        );
        
        print('Alternative follow API response status: ${altResponse.statusCode}');
        print('Alternative follow API response body: ${altResponse.body}');
        
        if (altResponse.headers['content-type']?.contains('application/json') == true) {
          return jsonDecode(altResponse.body);
        } else {
          return {'success': false, 'message': 'Alternative follow endpoint also failed. Please try again later.'};
        }
      } catch (altError) {
        print('Alternative follow API also failed: $altError');
        return {'success': false, 'message': 'Network error: $e'};
      }
    }
  }

  // New R-Gram Unfollow API
  static Future<Map<String, dynamic>> unfollowRGramUser({
    required String targetUserId,
    required String token,
  }) async {
    // Try main API first
    try {
      final response = await http.delete(
        Uri.parse('http://103.14.120.163:8081/api/follow/$targetUserId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      print('Unfollow API response status: ${response.statusCode}');
      print('Unfollow API response body: ${response.body}');
      
      // Check if response is JSON
      if (response.headers['content-type']?.contains('application/json') == true) {
        return jsonDecode(response.body);
      } else {
        // Handle non-JSON response (HTML error page, etc.)
        if (response.statusCode == 404) {
          return {'success': false, 'message': 'Unfollow endpoint not found. Please try again later.'};
        } else if (response.statusCode == 401) {
          return {'success': false, 'message': 'Authentication failed. Please login again.'};
        } else if (response.statusCode == 500) {
          return {'success': false, 'message': 'Server error. Please try again later.'};
        } else {
          return {'success': false, 'message': 'Unexpected response from server. Please try again.'};
        }
      }
    } catch (e) {
      print('Unfollow API error: $e');
      
      // Try alternative endpoint if main one fails
      try {
        print('Trying alternative unfollow endpoint...');
        final altResponse = await http.post(
          Uri.parse('$baseUrl/unfollow-user.php'),
          headers: _authHeaders(token),
          body: jsonEncode({'target_user_id': targetUserId}),
        );
        
        print('Alternative unfollow API response status: ${altResponse.statusCode}');
        print('Alternative unfollow API response body: ${altResponse.body}');
        
        if (altResponse.headers['content-type']?.contains('application/json') == true) {
          return jsonDecode(altResponse.body);
        } else {
          return {'success': false, 'message': 'Alternative unfollow endpoint also failed. Please try again later.'};
        }
      } catch (altError) {
        print('Alternative unfollow API also failed: $altError');
        return {'success': false, 'message': 'Network error: $e'};
      }
    }
  }

  // Get Following Users API
  static Future<Map<String, dynamic>> getRGramFollowing({
    required String userId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('http://103.14.120.163:8081/api/following/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Fixed: Use Bearer token format
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get Followers API
  static Future<Map<String, dynamic>> getRGramFollowers({
    required String userId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('http://103.14.120.163:8081/api/followers/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Fixed: Use Bearer token format
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Check if current user is following a specific user
  static Future<Map<String, dynamic>> checkRGramFollowStatus({
    required String targetUserId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('http://103.14.120.163:8081/api/follow/status/$targetUserId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get Feed Posts from Followed Users API
  static Future<Map<String, dynamic>> getRGramFeed({
    required String token,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('http://103.14.120.163:8081/api/feed?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Note: This API uses Bearer token
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get User Posts from R-Gram API
  static Future<Map<String, dynamic>> getRGramUserPosts({
    required String userId,
    required String token,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('http://103.14.120.163:8081/api/user/$userId/media?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Follow Request APIs
  static Future<Map<String, dynamic>> sendFollowRequest({
    required String targetUserId,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('http://103.14.120.163:8081/api/follow-request/$targetUserId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Fixed: Use Bearer token format
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getFollowRequests({
    required String token,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('http://103.14.120.163:8081/api/follow-requests?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Fixed: Use Bearer token format
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> respondToFollowRequest({
    required String requestId,
    required String action, // 'accept' or 'reject'
    required String token,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('http://103.14.120.163:8081/api/follow-request/$requestId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Fixed: Use Bearer token format
        },
        body: jsonEncode({'action': action}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }


  // Comment APIs
  static Future<Map<String, dynamic>> addComment(String userId, String postId, String comment, String? token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add-comment.php'),
        headers: _authHeaders(token),
        body: jsonEncode({
          'user_id': userId,
          'post_id': postId,
          'comment': comment,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getComments(String postId, String? token, {int page = 1, int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/comments.php?post_id=$postId&page=$page&limit=$limit'),
        headers: _authHeaders(token),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // File Upload Helper
  static Future<String?> uploadFile(String filePath, String? token) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload.php'),
      );

      request.headers.addAll(_authHeaders(token));
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final result = jsonDecode(responseData);

    if (result['success'] == true) {
      return result['file_url'];
    }
    return null;
    } catch (e) {
      return null;
    }
  }


  // New R-Gram Logout API
  static Future<Map<String, dynamic>> logoutRGram({
    required String token,
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('http://103.14.120.163:8081/api/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Note: This API uses Bearer token
        },
        body: jsonEncode({
          'userId': userId,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // New R-Gram Delete Media API
  static Future<Map<String, dynamic>> deleteMedia({
    required String mediaId,
    required String token,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('https://api-rgram1.vercel.app/api/media/delete?id=$mediaId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
} 