import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class LiveStreamingService {
  static const String baseUrl = 'https://103.14.120.163:8443/api';
  
  // Custom HTTP client that bypasses SSL certificate verification
  static http.Client _createHttpClient() {
    return http.Client();
  }
  
  // Initialize SSL context to bypass certificate verification
  static void _initializeSSL() {
    HttpOverrides.global = MyHttpOverrides();
  }
  
  static Future<void> initialize() async {
    _initializeSSL();
  }
  
  // Create a new room for live streaming
  static Future<Map<String, dynamic>> createRoom(String roomName) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rooms'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'roomName': roomName,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create room: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating room: $e');
    }
  }

  // Get room information
  static Future<Map<String, dynamic>> getRoomInfo(String roomName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rooms/$roomName'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get room info: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting room info: $e');
    }
  }

  // Get all available rooms
  static Future<List<Map<String, dynamic>>> getAllRooms() async {
    try {
      debugPrint('Fetching all available rooms...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/rooms'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      debugPrint('All rooms response status: ${response.statusCode}');
      debugPrint('All rooms response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('rooms')) {
          return List<Map<String, dynamic>>.from(data['rooms']);
        } else {
          // If server doesn't support this endpoint, return default rooms
          return _getDefaultRooms();
        }
      } else {
        debugPrint('Server doesn\'t support /rooms endpoint, using default rooms');
        return _getDefaultRooms();
      }
    } catch (e) {
      debugPrint('Error fetching all rooms: $e');
      return _getDefaultRooms();
    }
  }

  // Get default rooms when server doesn't support room listing
  static List<Map<String, dynamic>> _getDefaultRooms() {
    return [
      {
        'roomName': 'my-room',
        'viewerCount': 0,
        'broadcasterCount': 0,
        'isStreaming': false,
        'createdAt': DateTime.now().toIso8601String(),
        'description': 'Main Live Darshan Room',
      },
      {
        'roomName': 'live-darshan',
        'viewerCount': 0,
        'broadcasterCount': 0,
        'isStreaming': false,
        'createdAt': DateTime.now().toIso8601String(),
        'description': 'Live Darshan Streaming Room',
      },
      {
        'roomName': 'morning-prayer',
        'viewerCount': 0,
        'broadcasterCount': 0,
        'isStreaming': false,
        'createdAt': DateTime.now().toIso8601String(),
        'description': 'Morning Prayer Session',
      },
      {
        'roomName': 'evening-darshan',
        'viewerCount': 0,
        'broadcasterCount': 0,
        'isStreaming': false,
        'createdAt': DateTime.now().toIso8601String(),
        'description': 'Evening Darshan Session',
      },
      {
        'roomName': 'spiritual-talk',
        'viewerCount': 0,
        'broadcasterCount': 0,
        'isStreaming': false,
        'createdAt': DateTime.now().toIso8601String(),
        'description': 'Spiritual Discussion Room',
      },
    ];
  }

  // Join a room as viewer or broadcaster
  static Future<Map<String, dynamic>> joinRoom(String roomName, String role) async {
    try {
      debugPrint('Joining room: $roomName with role: $role');
      
      final response = await http.post(
        Uri.parse('$baseUrl/rooms/$roomName/join'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'role': role, // 'viewer' or 'broadcaster'
        }),
      );

      debugPrint('Join room response status: ${response.statusCode}');
      debugPrint('Join room response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to join room: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error joining room: $e');
      throw Exception('Error joining room: $e');
    }
  }

  // Start streaming
  static Future<Map<String, dynamic>> startStream(String roomName, String broadcasterId) async {
    try {
      debugPrint('Starting stream for room: $roomName with broadcasterId: $broadcasterId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/rooms/$roomName/stream/start'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'broadcasterId': broadcasterId,
        }),
      );

      debugPrint('Start stream response status: ${response.statusCode}');
      debugPrint('Start stream response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to start stream: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error starting stream: $e');
      throw Exception('Error starting stream: $e');
    }
  }

  // Stop streaming
  static Future<Map<String, dynamic>> stopStream(String roomName, String broadcasterId) async {
    try {
      debugPrint('Stopping stream for room: $roomName with broadcasterId: $broadcasterId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/rooms/$roomName/stream/stop'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'broadcasterId': broadcasterId,
        }),
      );

      debugPrint('Stop stream response status: ${response.statusCode}');
      debugPrint('Stop stream response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to stop stream: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error stopping stream: $e');
      throw Exception('Error stopping stream: $e');
    }
  }

  // Get viewers list
  static Future<Map<String, dynamic>> getViewers(String roomName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rooms/$roomName/viewers'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get viewers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting viewers: $e');
    }
  }

  // Check server status
  static Future<Map<String, dynamic>> getServerStatus() async {
    try {
      final client = _createHttpClient();
      
      final response = await client.get(
        Uri.parse('$baseUrl/status'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'R_GRam/1.0',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Server status response: $data');
        return data;
      } else {
        debugPrint('Server status check failed: ${response.statusCode}');
        throw Exception('Failed to get server status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting server status: $e');
      
      // Try alternative endpoint
      try {
        final client = _createHttpClient();
        final response = await client.get(
          Uri.parse('https://103.14.120.163:8443/'),
          headers: {
            'User-Agent': 'R_GRam/1.0',
          },
        ).timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 200) {
          return {'status': 'running', 'message': 'Server is accessible'};
        }
      } catch (altError) {
        debugPrint('Alternative check also failed: $altError');
      }
      
      throw Exception('Error getting server status: $e');
    }
  }

  // WebSocket connection for real-time communication
  static WebSocketChannel? connectToRoom(String websocketUrl, String roomName) {
    try {
      // Replace localhost with the actual server IP
      String wsUrl = websocketUrl.replaceFirst('localhost', '103.14.120.163');
      
      final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      return channel;
    } catch (e) {
      throw Exception('Error connecting to WebSocket: $e');
    }
  }

  // Send message through WebSocket
  static void sendMessage(WebSocketChannel channel, Map<String, dynamic> message) {
    try {
      channel.sink.add(jsonEncode(message));
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  // Close WebSocket connection
  static void closeConnection(WebSocketChannel channel) {
    try {
      channel.sink.close(status.goingAway);
    } catch (e) {
      print('Error closing WebSocket connection: $e');
    }
  }
}

class LiveStreamRoom {
  final String roomName;
  final int viewerCount;
  final int broadcasterCount;
  final List<String> viewers;
  final List<String> broadcasters;
  final bool isStreaming;
  final String? streamUrl;

  LiveStreamRoom({
    required this.roomName,
    required this.viewerCount,
    required this.broadcasterCount,
    required this.viewers,
    required this.broadcasters,
    this.isStreaming = false,
    this.streamUrl,
  });

  factory LiveStreamRoom.fromJson(Map<String, dynamic> json) {
    return LiveStreamRoom(
      roomName: json['roomName'] ?? '',
      viewerCount: json['viewerCount'] ?? 0,
      broadcasterCount: json['broadcasterCount'] ?? 0,
      viewers: List<String>.from(json['viewers'] ?? []),
      broadcasters: List<String>.from(json['broadcasters'] ?? []),
      isStreaming: json['isStreaming'] ?? false,
      streamUrl: json['streamUrl'],
    );
  }
}

class LiveStreamConnection {
  final String clientId;
  final String role;
  final String websocketUrl;
  final String roomName;

  LiveStreamConnection({
    required this.clientId,
    required this.role,
    required this.websocketUrl,
    required this.roomName,
  });

  factory LiveStreamConnection.fromJson(Map<String, dynamic> json) {
    return LiveStreamConnection(
      clientId: json['clientId'] ?? '',
      role: json['role'] ?? '',
      websocketUrl: json['websocketUrl'] ?? '',
      roomName: json['roomName'] ?? '',
    );
  }
}

// Custom HttpOverrides to bypass SSL certificate verification
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Allow all certificates for the live streaming server
        return host == '103.14.120.163' || host == 'localhost';
      };
  }
}