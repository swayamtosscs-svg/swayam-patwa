import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';

class NotificationService {
  static const String _baseUrl = 'https://api-rgram1.vercel.app/api';

  /// Get all notifications for the current user
  static Future<List<NotificationModel>> getNotifications({
    required String token,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/notifications?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> notificationsData = jsonResponse['data']['notifications'] ?? [];
          return notificationsData.map((data) => NotificationModel.fromJson(data)).toList();
        }
      }
      
      return [];
    } catch (e) {
      print('NotificationService: Error getting notifications: $e');
      return [];
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

  /// Get unread notification count
  static Future<int> getUnreadCount({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/notifications/unread-count'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['data']?['count'] ?? 0;
      }
      
      return 0;
    } catch (e) {
      print('NotificationService: Error getting unread count: $e');
      return 0;
    }
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
}
