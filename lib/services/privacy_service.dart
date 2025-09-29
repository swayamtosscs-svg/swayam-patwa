import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/privacy_model.dart';

class PrivacyService {
  static const String _baseUrl = 'http://103.14.120.163:8081/api';

  /// Get social feed with privacy enforcement
  static Future<Map<String, dynamic>> getSocialFeedWithPrivacy({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/feed/social?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch social feed: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching social feed: $e',
      };
    }
  }

  /// Get assets feed with privacy enforcement
  static Future<Map<String, dynamic>> getAssetsFeedWithPrivacy({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/feed/assets?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch assets feed: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching assets feed: $e',
      };
    }
  }

  /// Get user privacy settings
  static Future<PrivacySettings?> getUserPrivacySettings(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/privacy/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return PrivacySettings.fromJson(jsonResponse['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error getting privacy settings: $e');
      return null;
    }
  }

  /// Update user privacy settings
  static Future<bool> updatePrivacySettings(
    String userId,
    PrivacySettings settings,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/privacy/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(settings.toJson()),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating privacy settings: $e');
      return false;
    }
  }
}
