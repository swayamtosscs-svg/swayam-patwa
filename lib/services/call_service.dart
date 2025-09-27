import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/call_model.dart';
import '../models/user_model.dart';

class CallService {
  static const String baseUrl = 'http://103.14.120.163:8081';
  static const String callApiUrl = 'http://103.14.120.163:8081/api/calls';

  // Headers
  static Map<String, String> _authHeaders(String? token) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  // Initiate a call
  static Future<Map<String, dynamic>> initiateCall({
    required String receiverId,
    required CallType callType,
    required String token,
    required UserModel caller,
  }) async {
    try {
      print('Initiating ${callType.toString().split('.').last} call to user: $receiverId');
      
      final response = await http.post(
        Uri.parse('$callApiUrl/initiate'),
        headers: _authHeaders(token),
        body: jsonEncode({
          'receiverId': receiverId,
          'callType': callType.toString().split('.').last,
          'callerId': caller.id,
          'callerName': caller.name,
          'callerProfileImage': caller.profileImageUrl,
        }),
      );

      print('Initiate call API response status: ${response.statusCode}');
      print('Initiate call API response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Call initiated successfully',
          'data': result,
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Call service not available. Please try again later.',
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'You do not have permission to make calls.',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to initiate call. Please try again.',
        };
      }
    } catch (e) {
      print('Initiate call API error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Accept an incoming call
  static Future<Map<String, dynamic>> acceptCall({
    required String callId,
    required String token,
  }) async {
    try {
      print('Accepting call: $callId');
      
      final response = await http.post(
        Uri.parse('$callApiUrl/$callId/accept'),
        headers: _authHeaders(token),
      );

      print('Accept call API response status: ${response.statusCode}');
      print('Accept call API response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Call accepted successfully',
          'data': result,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to accept call. Please try again.',
        };
      }
    } catch (e) {
      print('Accept call API error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Decline an incoming call
  static Future<Map<String, dynamic>> declineCall({
    required String callId,
    required String token,
  }) async {
    try {
      print('Declining call: $callId');
      
      final response = await http.post(
        Uri.parse('$callApiUrl/$callId/decline'),
        headers: _authHeaders(token),
      );

      print('Decline call API response status: ${response.statusCode}');
      print('Decline call API response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Call declined successfully',
          'data': result,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to decline call. Please try again.',
        };
      }
    } catch (e) {
      print('Decline call API error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // End an active call
  static Future<Map<String, dynamic>> endCall({
    required String callId,
    required String token,
  }) async {
    try {
      print('Ending call: $callId');
      
      final response = await http.post(
        Uri.parse('$callApiUrl/$callId/end'),
        headers: _authHeaders(token),
      );

      print('End call API response status: ${response.statusCode}');
      print('End call API response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Call ended successfully',
          'data': result,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to end call. Please try again.',
        };
      }
    } catch (e) {
      print('End call API error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get call history
  static Future<Map<String, dynamic>> getCallHistory({
    required String token,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('Fetching call history - page: $page, limit: $limit');
      
      final response = await http.get(
        Uri.parse('$callApiUrl/history?page=$page&limit=$limit'),
        headers: _authHeaders(token),
      );

      print('Call history API response status: ${response.statusCode}');
      print('Call history API response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Call history retrieved successfully',
          'data': result,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch call history. Please try again.',
        };
      }
    } catch (e) {
      print('Call history API error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get active calls
  static Future<Map<String, dynamic>> getActiveCalls({
    required String token,
  }) async {
    try {
      print('Fetching active calls');
      
      final response = await http.get(
        Uri.parse('$callApiUrl/active'),
        headers: _authHeaders(token),
      );

      print('Active calls API response status: ${response.statusCode}');
      print('Active calls API response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Active calls retrieved successfully',
          'data': result,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch active calls. Please try again.',
        };
      }
    } catch (e) {
      print('Active calls API error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get call details
  static Future<Map<String, dynamic>> getCallDetails({
    required String callId,
    required String token,
  }) async {
    try {
      print('Fetching call details: $callId');
      
      final response = await http.get(
        Uri.parse('$callApiUrl/$callId'),
        headers: _authHeaders(token),
      );

      print('Call details API response status: ${response.statusCode}');
      print('Call details API response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Call details retrieved successfully',
          'data': result,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch call details. Please try again.',
        };
      }
    } catch (e) {
      print('Call details API error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Send call notification
  static Future<Map<String, dynamic>> sendCallNotification({
    required String receiverId,
    required String callId,
    required CallType callType,
    required String callerName,
    required String token,
  }) async {
    try {
      print('Sending call notification to user: $receiverId');
      
      final response = await http.post(
        Uri.parse('$callApiUrl/notify'),
        headers: _authHeaders(token),
        body: jsonEncode({
          'receiverId': receiverId,
          'callId': callId,
          'callType': callType.toString().split('.').last,
          'callerName': callerName,
        }),
      );

      print('Call notification API response status: ${response.statusCode}');
      print('Call notification API response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Call notification sent successfully',
          'data': result,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to send call notification. Please try again.',
        };
      }
    } catch (e) {
      print('Call notification API error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Check if user is available for calls
  static Future<Map<String, dynamic>> checkUserAvailability({
    required String userId,
    required String token,
  }) async {
    try {
      print('Checking availability for user: $userId');
      
      final response = await http.get(
        Uri.parse('$callApiUrl/availability/$userId'),
        headers: _authHeaders(token),
      );

      print('User availability API response status: ${response.statusCode}');
      print('User availability API response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'User availability checked successfully',
          'data': result,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to check user availability. Please try again.',
        };
      }
    } catch (e) {
      print('User availability API error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Create call room for WebRTC
  static Future<Map<String, dynamic>> createCallRoom({
    required String callId,
    required String token,
  }) async {
    try {
      print('Creating call room for call: $callId');
      
      final response = await http.post(
        Uri.parse('$callApiUrl/$callId/room'),
        headers: _authHeaders(token),
      );

      print('Create call room API response status: ${response.statusCode}');
      print('Create call room API response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Call room created successfully',
          'data': result,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create call room. Please try again.',
        };
      }
    } catch (e) {
      print('Create call room API error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get call token for WebRTC
  static Future<Map<String, dynamic>> getCallToken({
    required String callId,
    required String token,
  }) async {
    try {
      print('Getting call token for call: $callId');
      
      final response = await http.get(
        Uri.parse('$callApiUrl/$callId/token'),
        headers: _authHeaders(token),
      );

      print('Get call token API response status: ${response.statusCode}');
      print('Get call token API response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Call token retrieved successfully',
          'data': result,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get call token. Please try again.',
        };
      }
    } catch (e) {
      print('Get call token API error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}
