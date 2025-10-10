import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/live_stream_model.dart';

class LiveStreamService {
  static const String baseUrl = 'https://new-live-api.onrender.com/api';
  
  /// Create a new live stream room
  static Future<Map<String, dynamic>> createLiveRoom({
    required String title,
    required String hostName,
    String? description,
    String? category,
    List<String>? tags,
    bool isPrivate = false,
    int maxViewers = 100,
    bool allowChat = true,
    bool allowViewerSpeak = false,
    String? thumbnail,
    String? authToken,
  }) async {
    try {
      print('LiveStreamService: Creating live room with title: $title');
      
      // Prepare headers
      Map<String, String> headers = {
        'Content-Type': 'application/json',
      };
      
      // Add auth token if provided
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      
      // Prepare request body
      final requestBody = {
        'title': title,
        'hostName': hostName,
        'description': description ?? '',
        'category': category ?? 'General',
        'tags': tags ?? ['live', 'stream'],
        'isPrivate': isPrivate,
        'maxViewers': maxViewers,
        'allowChat': allowChat,
        'allowViewerSpeak': allowViewerSpeak,
        'thumbnail': thumbnail ?? '',
      };
      
      print('LiveStreamService: Request body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/rooms/create'),
        headers: headers,
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );
      
      print('LiveStreamService: Response status: ${response.statusCode}');
      print('LiveStreamService: Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['roomId'] != null) {
          print('LiveStreamService: Room created successfully');
          print('LiveStreamService: Room ID: ${responseData['roomId']}');
          print('LiveStreamService: Stream Key: ${responseData['streamKey']}');
          
          return {
            'success': true,
            'message': responseData['message'] ?? 'Room created successfully',
            'data': responseData,
          };
        } else {
          return {
            'success': false,
            'message': 'Invalid response format',
            'error': 'Missing roomId in response',
          };
        }
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to create room',
          'error': 'HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      print('LiveStreamService: Error creating room: $e');
      return {
        'success': false,
        'message': 'Error creating live room: $e',
        'error': e.toString(),
      };
    }
  }
  
  /// Get room details by room ID
  static Future<Map<String, dynamic>> getRoomDetails({
    required String roomId,
    String? authToken,
  }) async {
    try {
      print('LiveStreamService: Getting room details for: $roomId');
      
      Map<String, String> headers = {
        'Content-Type': 'application/json',
      };
      
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/rooms/$roomId'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );
      
      print('LiveStreamService: Room details response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get room details',
          'error': 'HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      print('LiveStreamService: Error getting room details: $e');
      return {
        'success': false,
        'message': 'Error getting room details: $e',
        'error': e.toString(),
      };
    }
  }
  
  /// Join a live room as viewer
  static Future<Map<String, dynamic>> joinRoomAsViewer({
    required String roomId,
    String? authToken,
  }) async {
    try {
      print('LiveStreamService: Joining room as viewer: $roomId');
      
      Map<String, String> headers = {
        'Content-Type': 'application/json',
      };
      
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/rooms/$roomId/join'),
        headers: headers,
        body: jsonEncode({'role': 'viewer'}),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to join room',
          'error': 'HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      print('LiveStreamService: Error joining room: $e');
      return {
        'success': false,
        'message': 'Error joining room: $e',
        'error': e.toString(),
      };
    }
  }
  
  /// Start live stream
  static Future<Map<String, dynamic>> startLiveStream({
    required String roomId,
    required String streamKey,
    String? authToken,
  }) async {
    try {
      print('LiveStreamService: Starting live stream for room: $roomId');
      
      Map<String, String> headers = {
        'Content-Type': 'application/json',
      };
      
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/rooms/$roomId/start'),
        headers: headers,
        body: jsonEncode({
          'streamKey': streamKey,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to start live stream',
          'error': 'HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      print('LiveStreamService: Error starting live stream: $e');
      return {
        'success': false,
        'message': 'Error starting live stream: $e',
        'error': e.toString(),
      };
    }
  }
  
  /// Stop live stream
  static Future<Map<String, dynamic>> stopLiveStream({
    required String roomId,
    String? authToken,
  }) async {
    try {
      print('LiveStreamService: Stopping live stream for room: $roomId');
      
      Map<String, String> headers = {
        'Content-Type': 'application/json',
      };
      
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/rooms/$roomId/stop'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to stop live stream',
          'error': 'HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      print('LiveStreamService: Error stopping live stream: $e');
      return {
        'success': false,
        'message': 'Error stopping live stream: $e',
        'error': e.toString(),
      };
    }
  }
  
  /// Get list of active live rooms
  static Future<Map<String, dynamic>> getActiveRooms({
    String? category,
    int page = 1,
    int limit = 20,
    String? authToken,
  }) async {
    try {
      print('LiveStreamService: Getting active rooms');
      
      Map<String, String> headers = {
        'Content-Type': 'application/json',
      };
      
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      
      String url = '$baseUrl/rooms?page=$page&limit=$limit';
      if (category != null && category.isNotEmpty) {
        url += '&category=$category';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get active rooms',
          'error': 'HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      print('LiveStreamService: Error getting active rooms: $e');
      return {
        'success': false,
        'message': 'Error getting active rooms: $e',
        'error': e.toString(),
      };
    }
  }
}