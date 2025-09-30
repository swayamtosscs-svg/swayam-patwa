import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

class NotificationService {
  static const String _baseUrl = 'http://103.14.120.163:8081/api';

  /// Get all notifications for the current user
  static Future<List<NotificationModel>> getNotifications({
    required String token,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/notifications/list?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        // Debug print to see the API response structure
        print('NotificationService.getNotifications - API Response: $jsonResponse');
        
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          // Handle different response structures
          List<dynamic> notificationsData = [];
          
          if (jsonResponse['data'] is List) {
            // Direct array response
            notificationsData = jsonResponse['data'];
          } else if (jsonResponse['data'] is Map) {
            // Object with notifications array
            final data = jsonResponse['data'] as Map<String, dynamic>;
            if (data['notifications'] is List) {
              notificationsData = data['notifications'];
            } else if (data['data'] is List) {
              notificationsData = data['data'];
            }
          }
          
          print('NotificationService.getNotifications - Parsed notifications data: $notificationsData');
          
          return notificationsData.map((data) => NotificationModel.fromJson(data)).toList();
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      }
      
      return [];
    } catch (e) {
      print('NotificationService: Error getting notifications: $e');
      rethrow;
    }
  }

  /// Mark a notification as read
  static Future<bool> markAsRead({
    required String notificationId,
    required String token,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('NotificationService: Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  static Future<bool> markAllAsRead({
    required String token,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/notifications/mark-all-read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('NotificationService: Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Get unread notifications only
  static Future<List<NotificationModel>> getUnreadNotifications({
    required String token,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/notifications/list?page=$page&limit=$limit&unreadOnly=true'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          // Handle different response structures
          List<dynamic> notificationsData = [];
          
          if (jsonResponse['data'] is List) {
            // Direct array response
            notificationsData = jsonResponse['data'];
          } else if (jsonResponse['data'] is Map) {
            // Object with notifications array
            final data = jsonResponse['data'] as Map<String, dynamic>;
            if (data['notifications'] is List) {
              notificationsData = data['notifications'];
            } else if (data['data'] is List) {
              notificationsData = data['data'];
            }
          }
          
          return notificationsData.map((data) => NotificationModel.fromJson(data)).toList();
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      }
      
      return [];
    } catch (e) {
      print('NotificationService: Error getting unread notifications: $e');
      rethrow;
    }
  }

  /// Get unread notification count
  static Future<int> getUnreadCount({
    required String token,
  }) async {
    try {
      final unreadNotifications = await getUnreadNotifications(token: token, limit: 1000);
      return unreadNotifications.length;
    } catch (e) {
      print('NotificationService: Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark notifications as viewed (hide count until new notifications arrive)
  static Future<void> markNotificationsAsViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_viewed', true);
    } catch (e) {
      print('NotificationService: Error marking notifications as viewed: $e');
    }
  }

  /// Check if notifications have been viewed
  static Future<bool> hasNotificationsBeenViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('notifications_viewed') ?? false;
    } catch (e) {
      print('NotificationService: Error checking notifications viewed status: $e');
      return false;
    }
  }

  /// Reset viewed status when new notifications arrive
  static Future<void> resetViewedStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_viewed', false);
    } catch (e) {
      print('NotificationService: Error resetting viewed status: $e');
    }
  }

  /// Force reset viewed status (for testing purposes)
  static Future<void> forceResetViewedStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('notifications_viewed');
    } catch (e) {
      print('NotificationService: Error force resetting viewed status: $e');
    }
  }

  /// Get authentication token from local storage
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Delete a notification
  static Future<bool> deleteNotification({
    required String notificationId,
    required String token,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/notifications/$notificationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('NotificationService: Error deleting notification: $e');
      return false;
    }
  }

  /// Create a follow notification
  static Future<bool> createFollowNotification({
    required String followerId,
    required String followerName,
    required String targetUserId,
    required String token,
    String? followerProfileImage,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/notifications/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'type': 'follow',
          'title': 'New Follower',
          'message': '$followerName started following you',
          'targetUserId': targetUserId,
          'followerId': followerId,
          'followerName': followerName,
          'followerProfileImage': followerProfileImage,
          'data': {
            'followerId': followerId,
            'followerName': followerName,
            'followerProfileImage': followerProfileImage,
            'action': 'follow',
          },
        }),
      );

      print('Create follow notification response: ${response.statusCode} - ${response.body}');
      
      // Reset viewed status when new notification is created
      if (response.statusCode == 200 || response.statusCode == 201) {
        await resetViewedStatus();
      }
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('NotificationService: Error creating follow notification: $e');
      return false;
    }
  }

  /// Create a notification (generic method)
  static Future<bool> createNotification({
    required String type,
    required String title,
    required String message,
    required String targetUserId,
    required String token,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/notifications/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'type': type,
          'title': title,
          'message': message,
          'targetUserId': targetUserId,
          'imageUrl': imageUrl,
          'data': data,
        }),
      );

      print('Create notification response: ${response.statusCode} - ${response.body}');
      
      // Reset viewed status when new notification is created
      if (response.statusCode == 200 || response.statusCode == 201) {
        await resetViewedStatus();
      }
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('NotificationService: Error creating notification: $e');
      return false;
    }
  }
}
