import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../models/live_stream_model.dart';

class LiveStreamService {
  static const String baseUrl = 'https://103.14.120.163:8443/api';

  /// Create HTTP client with SSL certificate bypass for development
  static http.Client _createHttpClient() {
    // Create a custom HttpClient that bypasses SSL certificate verification
    final httpClient = HttpClient();
    httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
      // For development, bypass SSL certificate verification
      print('LiveStreamService: Bypassing SSL certificate verification for $host:$port');
      return true;
    };
    
    return IOClient(httpClient);
  }

  /// Check if the live streaming server is running
  static Future<LiveStreamHealth> checkHealth() async {
    try {
      print('LiveStreamService: Checking server health');
      
      final client = _createHttpClient();
      final response = await client.get(
        Uri.parse('$baseUrl/health'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      client.close();

      print('LiveStreamService: Health check response status: ${response.statusCode}');
      print('LiveStreamService: Health check response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return LiveStreamHealth.fromJson(jsonResponse);
      } else {
        return LiveStreamHealth(
          success: false,
          message: 'Server is not responding',
          uptime: 0,
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      print('LiveStreamService: Error checking health: $e');
      return LiveStreamHealth(
        success: false,
        message: 'Error connecting to server: $e',
        uptime: 0,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Assign role to user for live streaming
  static Future<Map<String, dynamic>> assignRole({
    required String userId,
    required String role, // 'broadcaster' or 'viewer'
    required String room,
  }) async {
    try {
      print('LiveStreamService: Assigning role $role to user $userId for room $room');
      
      final requestBody = jsonEncode({
        "userId": userId,
        "role": role,
        "room": room,
      });
      
      final client = _createHttpClient();
      final response = await client.post(
        Uri.parse('$baseUrl/assign-role'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );
      client.close();
      
      print('LiveStreamService: Role assignment response status: ${response.statusCode}');
      print('LiveStreamService: Role assignment response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('LiveStreamService: Role assigned successfully');
        return data;
      } else {
        print('LiveStreamService: Failed to assign role: ${response.statusCode}');
        throw Exception('Failed to assign role: ${response.statusCode}');
      }
    } catch (e) {
      print('LiveStreamService: Error assigning role: $e');
      rethrow;
    }
  }

  /// Start a live stream for a room
  static Future<LiveStreamRoom> startLiveStream({
    required String room,
    required String userId,
  }) async {
    try {
      print('LiveStreamService: Starting live stream for room: $room with user: $userId');
      
      // First assign broadcaster role to the user
      try {
        await assignRole(
          userId: userId,
          role: 'broadcaster',
          room: room,
        );
        print('LiveStreamService: Broadcaster role assigned successfully');
      } catch (e) {
        print('LiveStreamService: Warning - Failed to assign broadcaster role: $e');
        // Continue with stream start even if role assignment fails
      }
      
      // Use the correct API format as specified in the curl example
      final requestBody = jsonEncode({"room": room});
      final client = _createHttpClient();
      final response = await client.post(
        Uri.parse('$baseUrl/start-live'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );
      client.close();

      print('LiveStreamService: Start live response status: ${response.statusCode}');
      print('LiveStreamService: Start live response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return LiveStreamRoom.fromJson(jsonResponse);
      } else {
        return LiveStreamRoom(
          success: false,
          room: room,
          isActive: false,
          broadcasterCount: 0,
          viewerCount: 0,
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      print('LiveStreamService: Error starting live stream: $e');
      return LiveStreamRoom(
        success: false,
        room: room,
        isActive: false,
        broadcasterCount: 0,
        viewerCount: 0,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Stop a live stream for a room
  static Future<LiveStreamRoom> stopLiveStream({
    required String room,
  }) async {
    try {
      print('LiveStreamService: Stopping live stream for room: $room');
      
      final request = LiveStreamRequest(room: room);
      final client = _createHttpClient();
      final response = await client.post(
        Uri.parse('$baseUrl/stop-live'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );
      client.close();

      print('LiveStreamService: Stop live response status: ${response.statusCode}');
      print('LiveStreamService: Stop live response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return LiveStreamRoom.fromJson(jsonResponse);
      } else {
        return LiveStreamRoom(
          success: false,
          room: room,
          isActive: false,
          broadcasterCount: 0,
          viewerCount: 0,
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      print('LiveStreamService: Error stopping live stream: $e');
      return LiveStreamRoom(
        success: false,
        room: room,
        isActive: false,
        broadcasterCount: 0,
        viewerCount: 0,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Join a live stream room as viewer
  static Future<LiveStreamRoom> joinLiveStream({
    required String room,
    required String userId,
  }) async {
    try {
      print('LiveStreamService: Joining live stream room: $room as viewer with user: $userId');
      
      // First assign viewer role to the user
      try {
        await assignRole(
          userId: userId,
          role: 'viewer',
          room: room,
        );
        print('LiveStreamService: Viewer role assigned successfully');
      } catch (e) {
        print('LiveStreamService: Warning - Failed to assign viewer role: $e');
        // Continue with join even if role assignment fails
      }
      
      final client = _createHttpClient();
      final response = await client.get(
        Uri.parse('$baseUrl/join-live/$room'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      client.close();

      print('LiveStreamService: Join live response status: ${response.statusCode}');
      print('LiveStreamService: Join live response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return LiveStreamRoom.fromJson(jsonResponse);
      } else {
        return LiveStreamRoom(
          success: false,
          room: room,
          isActive: false,
          broadcasterCount: 0,
          viewerCount: 0,
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      print('LiveStreamService: Error joining live stream: $e');
      return LiveStreamRoom(
        success: false,
        room: room,
        isActive: false,
        broadcasterCount: 0,
        viewerCount: 0,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Get live stream status for a room
  static Future<LiveStreamStatus> getLiveStatus({
    required String room,
  }) async {
    try {
      print('LiveStreamService: Getting live status for room: $room');
      
      final response = await http.get(
        Uri.parse('$baseUrl/live/$room'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('LiveStreamService: Get live status response status: ${response.statusCode}');
      print('LiveStreamService: Get live status response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return LiveStreamStatus.fromJson(jsonResponse);
      } else {
        return LiveStreamStatus(
          success: false,
          room: room,
          isLive: false,
          broadcasterCount: 0,
          viewerCount: 0,
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      print('LiveStreamService: Error getting live status: $e');
      return LiveStreamStatus(
        success: false,
        room: room,
        isLive: false,
        broadcasterCount: 0,
        viewerCount: 0,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }


  /// Get user information
  static Future<LiveStreamUserResponse> getUserInfo({
    required String userId,
  }) async {
    try {
      print('LiveStreamService: Getting user info for: $userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('LiveStreamService: Get user info response status: ${response.statusCode}');
      print('LiveStreamService: Get user info response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return LiveStreamUserResponse.fromJson(jsonResponse);
      } else {
        return LiveStreamUserResponse(
          success: false,
          message: 'User not found',
          user: LiveStreamUser(
            userId: userId,
            role: '',
            room: '',
            joinedAt: DateTime.now().toIso8601String(),
          ),
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      print('LiveStreamService: Error getting user info: $e');
      return LiveStreamUserResponse(
        success: false,
        message: 'Error getting user info: $e',
        user: LiveStreamUser(
          userId: userId,
          role: '',
          room: '',
          joinedAt: DateTime.now().toIso8601String(),
        ),
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Get all users in a room
  static Future<LiveStreamRoomUsersResponse> getRoomUsers({
    required String room,
  }) async {
    try {
      print('LiveStreamService: Getting users in room: $room');
      
      final response = await http.get(
        Uri.parse('$baseUrl/room/$room/users'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('LiveStreamService: Get room users response status: ${response.statusCode}');
      print('LiveStreamService: Get room users response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return LiveStreamRoomUsersResponse.fromJson(jsonResponse);
      } else {
        return LiveStreamRoomUsersResponse(
          success: false,
          users: [],
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      print('LiveStreamService: Error getting room users: $e');
      return LiveStreamRoomUsersResponse(
        success: false,
        users: [],
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Update user role
  static Future<LiveStreamUserResponse> updateUserRole({
    required String userId,
    required String role,
  }) async {
    try {
      print('LiveStreamService: Updating user $userId role to $role');
      
      final request = RoleUpdateRequest(role: role);
      final response = await http.put(
        Uri.parse('$baseUrl/user/$userId/role'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('LiveStreamService: Update role response status: ${response.statusCode}');
      print('LiveStreamService: Update role response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return LiveStreamUserResponse.fromJson(jsonResponse);
      } else {
        final jsonResponse = jsonDecode(response.body);
        return LiveStreamUserResponse(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to update role',
          user: LiveStreamUser(
            userId: userId,
            role: role,
            room: '',
            joinedAt: DateTime.now().toIso8601String(),
          ),
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      print('LiveStreamService: Error updating user role: $e');
      return LiveStreamUserResponse(
        success: false,
        message: 'Error updating role: $e',
        user: LiveStreamUser(
          userId: userId,
          role: role,
          room: '',
          joinedAt: DateTime.now().toIso8601String(),
        ),
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Remove user
  static Future<LiveStreamUserResponse> removeUser({
    required String userId,
  }) async {
    try {
      print('LiveStreamService: Removing user: $userId');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('LiveStreamService: Remove user response status: ${response.statusCode}');
      print('LiveStreamService: Remove user response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return LiveStreamUserResponse.fromJson(jsonResponse);
      } else {
        final jsonResponse = jsonDecode(response.body);
        return LiveStreamUserResponse(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to remove user',
          user: LiveStreamUser(
            userId: userId,
            role: '',
            room: '',
            joinedAt: DateTime.now().toIso8601String(),
          ),
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      print('LiveStreamService: Error removing user: $e');
      return LiveStreamUserResponse(
        success: false,
        message: 'Error removing user: $e',
        user: LiveStreamUser(
          userId: userId,
          role: '',
          room: '',
          joinedAt: DateTime.now().toIso8601String(),
        ),
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Get all active live streams
  static Future<LiveStreamRoomsResponse> getAllLiveStreams() async {
    try {
      print('LiveStreamService: Getting all live streams');
      
      final response = await http.get(
        Uri.parse('$baseUrl/live-streams'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('LiveStreamService: Get all live streams response status: ${response.statusCode}');
      print('LiveStreamService: Get all live streams response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return LiveStreamRoomsResponse.fromJson(jsonResponse);
      } else {
        return LiveStreamRoomsResponse(
          success: false,
          rooms: [],
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      print('LiveStreamService: Error getting all live streams: $e');
      return LiveStreamRoomsResponse(
        success: false,
        rooms: [],
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Get live stream analytics
  static Future<LiveStreamAnalytics> getLiveStreamAnalytics({
    required String room,
  }) async {
    try {
      print('LiveStreamService: Getting analytics for room: $room');
      
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/$room'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('LiveStreamService: Get analytics response status: ${response.statusCode}');
      print('LiveStreamService: Get analytics response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return LiveStreamAnalytics.fromJson(jsonResponse);
      } else {
        return LiveStreamAnalytics(
          success: false,
          room: room,
          totalViewers: 0,
          peakViewers: 0,
          averageViewers: 0,
          totalDuration: 0,
          startTime: DateTime.now().toIso8601String(),
          endTime: DateTime.now().toIso8601String(),
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      print('LiveStreamService: Error getting analytics: $e');
      return LiveStreamAnalytics(
        success: false,
        room: room,
        totalViewers: 0,
        peakViewers: 0,
        averageViewers: 0,
        totalDuration: 0,
        startTime: DateTime.now().toIso8601String(),
        endTime: DateTime.now().toIso8601String(),
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Send live stream message/comment
  static Future<LiveStreamMessageResponse> sendMessage({
    required String room,
    required String userId,
    required String message,
  }) async {
    try {
      print('LiveStreamService: Sending message to room: $room');
      
      final request = LiveStreamMessageRequest(
        room: room,
        userId: userId,
        message: message,
      );
      final response = await http.post(
        Uri.parse('$baseUrl/message'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('LiveStreamService: Send message response status: ${response.statusCode}');
      print('LiveStreamService: Send message response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return LiveStreamMessageResponse.fromJson(jsonResponse);
      } else {
        final jsonResponse = jsonDecode(response.body);
        return LiveStreamMessageResponse(
          success: false,
          message: jsonResponse['message'] ?? 'Failed to send message',
          messageId: '',
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      print('LiveStreamService: Error sending message: $e');
      return LiveStreamMessageResponse(
        success: false,
        message: 'Error sending message: $e',
        messageId: '',
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Get live stream messages
  static Future<LiveStreamMessagesResponse> getMessages({
    required String room,
    int limit = 50,
  }) async {
    try {
      print('LiveStreamService: Getting messages for room: $room');
      
      final response = await http.get(
        Uri.parse('$baseUrl/messages/$room?limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('LiveStreamService: Get messages response status: ${response.statusCode}');
      print('LiveStreamService: Get messages response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return LiveStreamMessagesResponse.fromJson(jsonResponse);
      } else {
        return LiveStreamMessagesResponse(
          success: false,
          messages: [],
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      print('LiveStreamService: Error getting messages: $e');
      return LiveStreamMessagesResponse(
        success: false,
        messages: [],
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }
}
