import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/follow_request_model.dart';
import 'notification_service.dart';

class FollowRequestService {
  static const String _baseUrl = 'http://103.14.120.163:8081/api';

  /// Get authentication headers with token
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get authentication token from local storage
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Get pending follow requests (received)
  static Future<List<FollowRequest>> getPendingRequests({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/follow-requests?page=$page&limit=$limit'),
        headers: headers,
      );

      print('Get pending requests response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> requestsData = jsonResponse['data']['requests'] ?? [];
          return requestsData.map((data) => FollowRequest.fromJson(data)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting pending requests: $e');
      return [];
    }
  }

  /// Get sent follow requests
  static Future<List<FollowRequest>> getSentRequests({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/follow-requests/sent?page=$page&limit=$limit'),
        headers: headers,
      );

      print('Get sent requests response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> requestsData = jsonResponse['data']['requests'] ?? [];
          return requestsData.map((data) => FollowRequest.fromJson(data)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error getting sent requests: $e');
      return [];
    }
  }

  /// Send a follow request
  static Future<bool> sendFollowRequest(String targetUserId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/follow-request/$targetUserId'),
        headers: headers,
      );

      print('Send follow request response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error sending follow request: $e');
      return false;
    }
  }

  /// Accept a follow request
  static Future<bool> acceptFollowRequest(String requestId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/follow-request/$requestId'),
        headers: headers,
        body: jsonEncode({'action': 'accept'}),
      );

      print('Accept follow request response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error accepting follow request: $e');
      return false;
    }
  }

  /// Reject a follow request
  static Future<bool> rejectFollowRequest(String requestId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/follow-request/$requestId'),
        headers: headers,
        body: jsonEncode({'action': 'reject'}),
      );

      print('Reject follow request response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error rejecting follow request: $e');
      return false;
    }
  }

  /// Cancel a follow request by request ID
  static Future<bool> cancelFollowRequest(String requestId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/follow-requests/$requestId'),
        headers: headers,
      );

      print('Cancel follow request response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error cancelling follow request: $e');
      return false;
    }
  }

  /// Cancel a follow request by target user ID
  static Future<bool> cancelFollowRequestByUserId(String targetUserId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/follow-requests/user/$targetUserId'),
        headers: headers,
      );

      print('Cancel follow request by user ID response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error cancelling follow request by user ID: $e');
      return false;
    }
  }

  /// Follow a user directly (for public accounts)
  /// Returns: true if successful, false if failed, null if follow request already sent (private account)
  static Future<bool?> followUser(String targetUserId, {String? followerName}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/follow/$targetUserId'),
        headers: headers,
      );

      print('Follow user response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Create follow notification
        await _createFollowNotification(targetUserId, followerName);
        return true;
      } else if (response.statusCode == 400) {
        // Check if it's a "follow request already sent" response
        try {
          final responseBody = jsonDecode(response.body);
          if (responseBody['message']?.toString().toLowerCase().contains('follow request already sent') == true) {
            print('FollowRequestService: Follow request already sent - this is a private account');
            return null; // Special return value indicating follow request already sent
          }
        } catch (e) {
          print('Error parsing follow response: $e');
        }
      }
      return false;
    } catch (e) {
      print('Error following user: $e');
      return false;
    }
  }

  /// Create follow notification
  static Future<void> _createFollowNotification(String targetUserId, String? followerName) async {
    try {
      final token = await _getToken();
      if (token == null) return;

      // Get current user info
      final currentUserInfo = await _getCurrentUserInfo();
      if (currentUserInfo == null) return;

      final followerId = currentUserInfo['id'] ?? currentUserInfo['_id'];
      final followerNameToUse = followerName ?? currentUserInfo['name'] ?? currentUserInfo['username'] ?? 'Someone';

      await NotificationService.createFollowNotification(
        followerId: followerId,
        followerName: followerNameToUse,
        targetUserId: targetUserId,
        token: token,
      );
    } catch (e) {
      print('Error creating follow notification: $e');
    }
  }

  /// Get current user information
  static Future<Map<String, dynamic>?> _getCurrentUserInfo() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/user/profile'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return jsonResponse['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error getting current user info: $e');
      return null;
    }
  }

  /// Unfollow a user
  static Future<bool> unfollowUser(String targetUserId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/follow/$targetUserId'),
        headers: headers,
      );

      print('Unfollow user response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error unfollowing user: $e');
      return false;
    }
  }

  /// Check if there's a pending request to a user
  static Future<bool> hasPendingRequest(String targetUserId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/follow/status/$targetUserId'),
        headers: headers,
      );

      print('Check pending request response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['hasRequest'] == true || jsonResponse['isRequested'] == true;
      }
      return false;
    } catch (e) {
      print('Error checking pending request: $e');
      return false;
    }
  }
}