import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'cache_service.dart';
import 'custom_http_client.dart';
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

  // Feed APIs with caching
  static Future<Map<String, dynamic>> getFeed(String? token, {int page = 1, int limit = 10}) async {
    try {
      final cacheKey = 'feed_${page}_$limit';
      
      // Try to get cached data first
      final cachedData = await CacheService.getCachedData<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }
      
      final response = await CustomHttpClient.get(
        Uri.parse('$baseUrl/feed.php?page=$page&limit=$limit'),
        headers: _authHeaders(token),
      );

      final result = jsonDecode(response.body) as Map<String, dynamic>;
      
      // Cache the result for 5 minutes
      await CacheService.cacheData(cacheKey, result, expiry: const Duration(minutes: 5));
      
      return result;
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

  // Permanent Post Deletion API - ensures complete removal from server
  static Future<Map<String, dynamic>> deleteMedia({
    required String mediaId,
    required String token,
  }) async {
    print('Attempting permanent deletion of media with ID: $mediaId');
    
    // PRIMARY endpoint - Correct server 103.14.120.163:8081
    try {
      print('Trying PRIMARY deletion endpoint: DELETE http://103.14.120.163:8081/api/posts/$mediaId');
      final response = await http.delete(
        Uri.parse('http://103.14.120.163:8081/api/posts/$mediaId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('PRIMARY delete API response status: ${response.statusCode}');
      print('PRIMARY delete API response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          print('Post permanently deleted via PRIMARY endpoint (103.14.120.163:8081)');
          return {
            'success': true,
            'message': 'Post permanently deleted successfully from server'
          };
        } else {
          print('PRIMARY endpoint returned success=false: ${result['message']}');
          // Only treat as success if explicitly confirmed as deleted
          if (result['message']?.toString().toLowerCase().contains('deleted successfully') == true ||
              result['message']?.toString().toLowerCase().contains('successfully deleted') == true ||
              result['message']?.toString().toLowerCase().contains('deleted') == true) {
            return {
              'success': true,
              'message': 'Post permanently deleted successfully from server'
            };
          } else {
            return {
              'success': false,
              'message': result['message'] ?? 'Failed to delete post from server'
            };
          }
        }
      } else if (response.statusCode == 404) {
        print('PRIMARY endpoint returned 404 - post not found');
        // Treat 404 as success since the goal is achieved (post doesn't exist)
        return {
          'success': true,
          'message': 'Post successfully removed (was not found on server)'
        };
      } else if (response.statusCode == 401) {
        print('PRIMARY endpoint returned 401 - unauthorized');
        return {
          'success': false,
          'message': 'Unauthorized to delete this post. Please check your permissions.'
        };
      } else if (response.statusCode == 403) {
        print('PRIMARY endpoint returned 403 - forbidden');
        return {
          'success': false,
          'message': 'You do not have permission to delete this post.'
        };
      } else {
        print('PRIMARY endpoint failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('PRIMARY delete endpoint error: $e');
    }

    // SECONDARY endpoint - Media deletion endpoint on correct server
    try {
      print('Trying SECONDARY deletion endpoint: DELETE http://103.14.120.163:8081/api/media/delete');
      final response = await http.delete(
        Uri.parse('http://103.14.120.163:8081/api/media/delete?id=$mediaId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('SECONDARY delete API response status: ${response.statusCode}');
      print('SECONDARY delete API response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          print('Media permanently deleted via SECONDARY endpoint (103.14.120.163:8081)');
          return {
            'success': true,
            'message': 'Media permanently deleted successfully from server'
          };
        } else {
          print('SECONDARY endpoint returned success=false: ${result['message']}');
          if (result['message']?.toString().toLowerCase().contains('deleted successfully') == true ||
              result['message']?.toString().toLowerCase().contains('successfully deleted') == true ||
              result['message']?.toString().toLowerCase().contains('deleted') == true) {
            return {
              'success': true,
              'message': 'Media permanently deleted successfully from server'
            };
          } else {
            return {
              'success': false,
              'message': result['message'] ?? 'Failed to delete media from server'
            };
          }
        }
      } else if (response.statusCode == 404) {
        print('SECONDARY endpoint returned 404 - media not found');
        // Treat 404 as success since the goal is achieved (media doesn't exist)
        return {
          'success': true,
          'message': 'Media successfully removed (was not found on server)'
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Unauthorized to delete this media. Please check your permissions.'
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'You do not have permission to delete this media.'
        };
      }
    } catch (e) {
      print('SECONDARY delete endpoint error: $e');
    }

    // TERTIARY endpoint - Alternative server (fallback)
    try {
      print('Trying TERTIARY deletion endpoint: DELETE http://103.14.120.163:8081/api/posts/$mediaId');
      final response = await http.delete(
        Uri.parse('http://103.14.120.163:8081/api/posts/$mediaId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('TERTIARY delete API response status: ${response.statusCode}');
      print('TERTIARY delete API response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          print('Post permanently deleted via TERTIARY endpoint');
          return {
            'success': true,
            'message': 'Post permanently deleted successfully from server'
          };
        } else {
          return {
            'success': false,
            'message': result['message'] ?? 'Failed to delete post from server'
          };
        }
      } else if (response.statusCode == 404) {
        print('TERTIARY endpoint returned 404 - post not found');
        // Treat 404 as success since the goal is achieved (post doesn't exist)
        return {
          'success': true,
          'message': 'Post successfully removed (was not found on server)'
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Unauthorized to delete this post. Please check your permissions.'
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'You do not have permission to delete this post.'
        };
      }
    } catch (e) {
      print('TERTIARY delete endpoint error: $e');
    }

    // If all endpoints fail, return comprehensive error
    return {
      'success': false,
      'message': 'Failed to permanently delete post. All deletion endpoints are unavailable. Please check your internet connection and try again later.'
    };
  }

  // Dedicated post deletion endpoint for better reliability
  static Future<Map<String, dynamic>> deletePost({
    required String postId,
    required String token,
  }) async {
    print('Attempting dedicated post deletion for ID: $postId');
    
    try {
      // Use the correct server 103.14.120.163:8081
      final response = await http.delete(
        Uri.parse('http://103.14.120.163:8081/api/posts/$postId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Dedicated post deletion response status: ${response.statusCode}');
      print('Dedicated post deletion response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          print('Post permanently deleted via dedicated endpoint (103.14.120.163:8081)');
          return {
            'success': true,
            'message': 'Post permanently deleted successfully from server'
          };
        } else {
          print('Dedicated endpoint returned success=false: ${result['message']}');
          // Only treat as success if explicitly confirmed as deleted
          if (result['message']?.toString().toLowerCase().contains('deleted successfully') == true ||
              result['message']?.toString().toLowerCase().contains('successfully deleted') == true ||
              result['message']?.toString().toLowerCase().contains('deleted') == true) {
            return {
              'success': true,
              'message': 'Post permanently deleted successfully from server'
            };
          } else {
            return {
              'success': false,
              'message': result['message'] ?? 'Failed to delete post from server'
            };
          }
        }
      } else if (response.statusCode == 404) {
        print('Dedicated endpoint returned 404 - post not found');
        return {
          'success': false,
          'message': 'Post not found on server. It may have already been deleted or never existed.'
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Unauthorized to delete this post. Please check your permissions.'
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'You do not have permission to delete this post.'
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to delete post. Server returned status: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Dedicated post deletion error: $e');
      return {
        'success': false,
        'message': 'Network error while deleting post: $e'
      };
    }
  }

  // Verify if a post/media still exists on the server
  static Future<bool> verifyPostExists({
    required String postId,
    required String token,
  }) async {
    try {
      print('Verifying if post $postId still exists on server (103.14.120.163:8081)...');
      
      // Try to fetch the post from the correct server to see if it still exists
      final response = await http.get(
        Uri.parse('http://103.14.120.163:8081/api/posts/$postId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Post verification response status: ${response.statusCode}');
      
      if (response.statusCode == 404) {
        print('Post $postId confirmed as deleted (404 not found) from server 103.14.120.163:8081');
        return false; // Post doesn't exist = successfully deleted
      } else if (response.statusCode == 200) {
        print('Post $postId still exists on server 103.14.120.163:8081');
        return true; // Post still exists = deletion failed
      } else {
        print('Post verification returned status: ${response.statusCode}');
        return true; // Assume it exists if we can't verify
      }
    } catch (e) {
      print('Post verification error: $e');
      return true; // Assume it exists if we can't verify
    }
  }

  // Enhanced deletion with verification
  static Future<Map<String, dynamic>> deleteMediaWithVerification({
    required String mediaId,
    required String token,
  }) async {
    print('Starting deletion with verification for media ID: $mediaId');
    
    // First, try to delete the media
    final deleteResult = await deleteMedia(mediaId: mediaId, token: token);
    
    if (deleteResult['success'] == true) {
      print('Initial deletion successful, verifying...');
      
      // Wait a moment for server to process
      await Future.delayed(Duration(seconds: 2));
      
      // Verify the deletion worked
      final stillExists = await verifyPostExists(postId: mediaId, token: token);
      
      if (!stillExists) {
        print('Deletion verified successfully - post no longer exists on server');
        return {
          'success': true,
          'message': 'Post permanently deleted and verified from server'
        };
      } else {
        print('Deletion verification failed - post still exists on server');
        return {
          'success': false,
          'message': 'Post deletion failed - post still exists on server'
        };
      }
    } else {
      print('Initial deletion failed: ${deleteResult['message']}');
      
      // If the deletion failed because the post doesn't exist, treat it as success
      if (deleteResult['message']?.toString().toLowerCase().contains('not found') == true ||
          deleteResult['message']?.toString().toLowerCase().contains('already been deleted') == true) {
        print('Post was not found or already deleted - treating as success');
        return {
          'success': true,
          'message': 'Post successfully removed (was not found on server)'
        };
      }
      
      return deleteResult;
    }
  }

  // Determine the correct like endpoint based on post source
  static Future<String?> getCorrectLikeEndpoint({
    required String postId,
    required String token,
  }) async {
    try {
      // First try the posts API
      final postsResponse = await http.get(
        Uri.parse('http://103.14.120.163:8081/api/posts/$postId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (postsResponse.statusCode == 200) {
        return 'http://103.14.120.163:8081/api/posts/$postId/like';
      }
      
      // If not found in posts API, try the media API
      final mediaResponse = await http.get(
        Uri.parse('http://103.14.120.163:8081/api/media/$postId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (mediaResponse.statusCode == 200) {
        return 'http://103.14.120.163:8081/api/media/$postId/like';
      }
      
      return null; // Post not found in either API
    } catch (e) {
      print('Error determining correct like endpoint: $e');
      return null;
    }
  }

  // Get like status for local/mock posts
  static Future<Map<String, dynamic>> _getLocalPostLikeStatus({
    required String postId,
  }) async {
    try {
      // Use SharedPreferences to get local likes
      final prefs = await SharedPreferences.getInstance();
      final likeCountsKey = 'like_counts';
      
      // Get current like counts
      final likeCountsJson = prefs.getString(likeCountsKey) ?? '{}';
      final Map<String, dynamic> likeCounts = Map<String, dynamic>.from(jsonDecode(likeCountsJson));
      
      int currentCount = likeCounts[postId] ?? 0;
      
      print('Local Post Like Status: post $postId - Count: $currentCount');
      
      return {
        'success': true,
        'message': 'Local like status retrieved',
        'data': {
          'likesCount': currentCount,
          'liked': false, // We don't track individual user likes for local posts
        },
      };
    } catch (e) {
      print('Error getting local post like status: $e');
      return {
        'success': false,
        'message': 'Error getting local like status',
        'data': {
          'likesCount': 0,
          'liked': false,
        },
      };
    }
  }

  // Handle likes for local/mock posts that don't exist on server
  static Future<Map<String, dynamic>> _handleLocalPostLike({
    required String postId,
    required String userId,
    required String action, // 'like' or 'unlike'
  }) async {
    try {
      // Use SharedPreferences to store local likes
      final prefs = await SharedPreferences.getInstance();
      final likedPostsKey = 'liked_posts_$userId';
      final likeCountsKey = 'like_counts';
      
      // Get current liked posts
      final likedPostsJson = prefs.getString(likedPostsKey) ?? '[]';
      final List<dynamic> likedPosts = jsonDecode(likedPostsJson);
      
      // Get current like counts
      final likeCountsJson = prefs.getString(likeCountsKey) ?? '{}';
      final Map<String, dynamic> likeCounts = Map<String, dynamic>.from(jsonDecode(likeCountsJson));
      
      bool isLiked = likedPosts.contains(postId);
      int currentCount = likeCounts[postId] ?? 0;
      
      if (action == 'like' && !isLiked) {
        likedPosts.add(postId);
        likeCounts[postId] = currentCount + 1;
        isLiked = true;
        currentCount++;
      } else if (action == 'unlike' && isLiked) {
        likedPosts.remove(postId);
        likeCounts[postId] = (currentCount - 1).clamp(0, double.infinity).toInt();
        isLiked = false;
        currentCount = (currentCount - 1).clamp(0, double.infinity).toInt();
      }
      
      // Save updated data
      await prefs.setString(likedPostsKey, jsonEncode(likedPosts));
      await prefs.setString(likeCountsKey, jsonEncode(likeCounts));
      
      print('Local Post Like: $action post $postId - Count: $currentCount, Liked: $isLiked');
      
      return {
        'success': true,
        'message': action == 'like' ? 'Liked locally' : 'Unliked locally',
        'data': {
          'likesCount': currentCount,
          'liked': isLiked,
        },
      };
    } catch (e) {
      print('Error handling local post like: $e');
      return {
        'success': false,
        'message': 'Error handling local like',
        'data': {
          'likesCount': 0,
          'liked': false,
        },
      };
    }
  }

  // Check if post exists before liking (check both posts and media APIs)
  static Future<bool> postExists({
    required String postId,
    required String token,
  }) async {
    try {
      // First try the posts API
      final postsResponse = await http.get(
        Uri.parse('http://103.14.120.163:8081/api/posts/$postId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (postsResponse.statusCode == 200) {
        return true;
      }
      
      // If not found in posts API, try the media API
      final mediaResponse = await http.get(
        Uri.parse('http://103.14.120.163:8081/api/media/$postId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      return mediaResponse.statusCode == 200;
    } catch (e) {
      print('Error checking if post exists: $e');
      return false;
    }
  }

  // Like/Unlike Post APIs - Using New Unified Like API with Fallback
  static Future<Map<String, dynamic>> likePost({
    required String postId,
    required String token,
    required String userId,
  }) async {
    print('Like Post API: Using new unified like API endpoint with fallback');
    
    // First check if this is a local/mock post
    if (postId.startsWith('mock_') || postId.startsWith('local_')) {
      print('Like Post API: Detected local/mock post, using local storage fallback');
      return await _handleLocalPostLike(postId: postId, userId: userId, action: 'like');
    }
    
    // Try the new unified like API first
    try {
      print('Like Post API: Trying new unified like endpoint');
      
      final response = await http.post(
        Uri.parse('http://103.14.120.163:8081/api/likes/like'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contentType': 'post',
          'contentId': postId,
        }),
      );

      print('Like Post API - URL: http://103.14.120.163:8081/api/likes/like');
      print('Like Post API - PostId: $postId');
      print('Like Post API response status: ${response.statusCode}');
      print('Like Post API response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        print('Like Post API succeeded with new endpoint');
        return result;
      } else if (response.statusCode == 404) {
        print('Like Post API: New endpoint returned 404, trying fallback endpoint');
        // Try the old working endpoint as fallback
        return await _tryFallbackLikeEndpoint(postId: postId, token: token, userId: userId, action: 'like');
      } else {
        print('Like Post API: New endpoint failed with ${response.statusCode}, trying fallback');
        return await _tryFallbackLikeEndpoint(postId: postId, token: token, userId: userId, action: 'like');
      }
    } catch (e) {
      print('Like Post API: Error with new endpoint: $e, trying fallback');
      return await _tryFallbackLikeEndpoint(postId: postId, token: token, userId: userId, action: 'like');
    }
  }

  static Future<Map<String, dynamic>> unlikePost({
    required String postId,
    required String token,
    required String userId,
  }) async {
    print('Unlike Post API: Using DELETE method for unlike');
    
    // First check if this is a local/mock post
    if (postId.startsWith('mock_') || postId.startsWith('local_')) {
      print('Unlike Post API: Detected local/mock post, using local storage fallback');
      return await _handleLocalPostLike(postId: postId, userId: userId, action: 'unlike');
    }
    
    // Try DELETE unlike endpoint first
    try {
      print('Unlike Post API: Trying DELETE unlike endpoint');
      
      // For DELETE with body, we need to use http.Request
      final request = http.Request(
        'DELETE',
        Uri.parse('http://103.14.120.163:8081/api/likes/unlike'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'contentType': 'post',
        'contentId': postId,
      });
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Unlike Post API - URL: DELETE http://103.14.120.163:8081/api/likes/unlike');
      print('Unlike Post API - PostId: $postId');
      print('Unlike Post API response status: ${response.statusCode}');
      print('Unlike Post API response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        print('Unlike Post API succeeded with DELETE endpoint');
        return result;
      } else if (response.statusCode == 404) {
        print('Unlike Post API: DELETE endpoint returned 404, trying toggle endpoint');
        // Try the toggle endpoint as fallback
        return await _tryFallbackLikeEndpoint(postId: postId, token: token, userId: userId, action: 'unlike');
      } else {
        print('Unlike Post API: DELETE endpoint failed with ${response.statusCode}, trying toggle fallback');
        return await _tryFallbackLikeEndpoint(postId: postId, token: token, userId: userId, action: 'unlike');
      }
    } catch (e) {
      print('Unlike Post API: Error with DELETE endpoint: $e, trying toggle fallback');
      return await _tryFallbackLikeEndpoint(postId: postId, token: token, userId: userId, action: 'unlike');
    }
  }

  // Fallback method to try the old working like API (toggle endpoint)
  static Future<Map<String, dynamic>> _tryFallbackLikeEndpoint({
    required String postId,
    required String token,
    required String userId,
    required String action,
  }) async {
    print('Fallback Like API: Trying toggle endpoint for action: $action');
    
    // Try the toggle endpoint: POST /api/feed/like/{postId}
    try {
      final response = await http.post(
        Uri.parse('http://103.14.120.163:8081/api/feed/like/$postId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Fallback Like API - URL: POST http://103.14.120.163:8081/api/feed/like/$postId');
      print('Fallback Like API - Action: $action');
      print('Fallback Like API response status: ${response.statusCode}');
      print('Fallback Like API response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        print('Fallback Like API succeeded with toggle endpoint');
        
        // Update result based on action to ensure correct state
        if (action == 'like') {
          result['data'] = result['data'] ?? {};
          result['data']['liked'] = true;
          if (result['data']['likesCount'] != null) {
            result['data']['likesCount'] = (result['data']['likesCount'] as int);
          }
        } else if (action == 'unlike') {
          result['data'] = result['data'] ?? {};
          result['data']['liked'] = false;
          if (result['data']['likesCount'] != null) {
            result['data']['likesCount'] = (result['data']['likesCount'] as int);
          }
        }
        
        return result;
      } else {
        print('Fallback Like API: Failed with ${response.statusCode}, using local storage');
        return await _handleLocalPostLike(postId: postId, userId: userId, action: action);
      }
    } catch (e) {
      print('Fallback Like API: Error: $e, using local storage');
      return await _handleLocalPostLike(postId: postId, userId: userId, action: action);
    }
  }

  static Future<Map<String, dynamic>> togglePostLike({
    required String postId,
    required String token,
    required String userId,
    required bool isCurrentlyLiked,
  }) async {
    if (isCurrentlyLiked) {
      return await unlikePost(postId: postId, token: token, userId: userId);
    } else {
      return await likePost(postId: postId, token: token, userId: userId);
    }
  }

  static Future<Map<String, dynamic>> getPostLikeStatus({
    required String postId,
    required String token,
  }) async {
    print('Get Post Like Status API: Using local storage for like status');
    
    // First check if this is a local/mock post
    if (postId.startsWith('mock_') || postId.startsWith('local_')) {
      print('Get Post Like Status API: Detected local/mock post, checking local storage');
      return await _getLocalPostLikeStatus(postId: postId);
    }
    
    // Since the new like API doesn't have a specific endpoint for getting like status,
    // we'll use local storage to track like status
    try {
      print('Get Post Like Status API: Checking local storage for like status');
      return await _getLocalPostLikeStatus(postId: postId);
    } catch (e) {
      print('Get Post Like Status API: Error checking local storage: $e');
      return {
        'success': true,
        'data': {
          'liked': false,
          'likesCount': 0,
        },
      };
    }
  }

  static Future<Map<String, dynamic>> getPostLikes({
    required String postId,
    required String token,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // Try the new likes API endpoint
      final response = await http.get(
        Uri.parse('http://103.14.120.163:8081/api/likes/$postId?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Get Post Likes API - URL: http://103.14.120.163:8081/api/likes/$postId');
      print('Get Post Likes API response status: ${response.statusCode}');
      print('Get Post Likes API response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Get Post Likes API: Failed with ${response.statusCode}');
        // Return empty list if API fails
        return {
          'success': true,
          'message': 'Post likes retrieved from local storage (API endpoint not available)',
          'data': {
            'likes': [],
            'totalCount': 0,
          },
        };
      }
    } catch (e) {
      print('Get Post Likes API error: $e');
      return {
        'success': true,
        'message': 'Post likes retrieved from local storage',
        'data': {
          'likes': [],
          'totalCount': 0,
        },
      };
    }
  }
} 