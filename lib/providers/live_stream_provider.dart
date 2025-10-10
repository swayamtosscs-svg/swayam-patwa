import 'package:flutter/foundation.dart';
import '../models/live_stream_model.dart';
import '../services/live_stream_service.dart';

class LiveStreamProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  LiveRoom? _currentRoom;
  List<LiveRoom> _activeRooms = [];
  bool _isLive = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  LiveRoom? get currentRoom => _currentRoom;
  List<LiveRoom> get activeRooms => _activeRooms;
  bool get isLive => _isLive;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Create a new live room
  Future<Map<String, dynamic>> createLiveRoom({
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
    _setLoading(true);
    _setError(null);

    try {
      final response = await LiveStreamService.createLiveRoom(
        title: title,
        hostName: hostName,
        description: description,
        category: category,
        tags: tags,
        isPrivate: isPrivate,
        maxViewers: maxViewers,
        allowChat: allowChat,
        allowViewerSpeak: allowViewerSpeak,
        thumbnail: thumbnail,
        authToken: authToken,
      );

      if (response['success'] == true) {
        final roomData = response['data'];
        _currentRoom = LiveRoom.fromJson(roomData['room']);
        print('LiveStreamProvider: Room created successfully');
        print('LiveStreamProvider: Room ID: ${_currentRoom!.id}');
        print('LiveStreamProvider: Stream Key: ${_currentRoom!.streamKey}');
        
        return {
          'success': true,
          'message': response['message'],
          'room': _currentRoom,
          'roomId': roomData['roomId'],
          'streamKey': roomData['streamKey'],
          'joinUrl': roomData['joinUrl'],
          'hostUrl': roomData['hostUrl'],
        };
      } else {
        _setError(response['message'] ?? 'Failed to create room');
        return {
          'success': false,
          'message': response['message'],
          'error': response['error'],
        };
      }
    } catch (e) {
      _setError('Error creating live room: $e');
      return {
        'success': false,
        'message': 'Error creating live room: $e',
        'error': e.toString(),
      };
    } finally {
      _setLoading(false);
    }
  }

  /// Get room details
  Future<Map<String, dynamic>> getRoomDetails({
    required String roomId,
    String? authToken,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await LiveStreamService.getRoomDetails(
        roomId: roomId,
        authToken: authToken,
      );

      if (response['success'] == true) {
        _currentRoom = LiveRoom.fromJson(response['data']);
        return {
          'success': true,
          'room': _currentRoom,
        };
      } else {
        _setError(response['message'] ?? 'Failed to get room details');
        return {
          'success': false,
          'message': response['message'],
        };
      }
    } catch (e) {
      _setError('Error getting room details: $e');
      return {
        'success': false,
        'message': 'Error getting room details: $e',
      };
    } finally {
      _setLoading(false);
    }
  }

  /// Join room as viewer
  Future<Map<String, dynamic>> joinRoomAsViewer({
    required String roomId,
    String? authToken,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await LiveStreamService.joinRoomAsViewer(
        roomId: roomId,
        authToken: authToken,
      );

      if (response['success'] == true) {
        // Update current room if it's the one we're joining
        if (_currentRoom?.id == roomId) {
          _currentRoom = LiveRoom.fromJson(response['data']);
        }
        return {
          'success': true,
          'data': response['data'],
        };
      } else {
        _setError(response['message'] ?? 'Failed to join room');
        return {
          'success': false,
          'message': response['message'],
        };
      }
    } catch (e) {
      _setError('Error joining room: $e');
      return {
        'success': false,
        'message': 'Error joining room: $e',
      };
    } finally {
      _setLoading(false);
    }
  }

  /// Start live stream
  Future<Map<String, dynamic>> startLiveStream({
    required String roomId,
    required String streamKey,
    String? authToken,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await LiveStreamService.startLiveStream(
        roomId: roomId,
        streamKey: streamKey,
        authToken: authToken,
      );

      if (response['success'] == true) {
        _isLive = true;
        if (_currentRoom?.id == roomId) {
          _currentRoom = _currentRoom!.copyWith(
            isLive: true,
            status: 'live',
          );
        }
        return {
          'success': true,
          'data': response['data'],
        };
      } else {
        _setError(response['message'] ?? 'Failed to start live stream');
        return {
          'success': false,
          'message': response['message'],
        };
      }
    } catch (e) {
      _setError('Error starting live stream: $e');
      return {
        'success': false,
        'message': 'Error starting live stream: $e',
      };
    } finally {
      _setLoading(false);
    }
  }

  /// Stop live stream
  Future<Map<String, dynamic>> stopLiveStream({
    required String roomId,
    String? authToken,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await LiveStreamService.stopLiveStream(
        roomId: roomId,
        authToken: authToken,
      );

      if (response['success'] == true) {
        _isLive = false;
        if (_currentRoom?.id == roomId) {
          _currentRoom = _currentRoom!.copyWith(
            isLive: false,
            status: 'ended',
          );
        }
        return {
          'success': true,
          'data': response['data'],
        };
      } else {
        _setError(response['message'] ?? 'Failed to stop live stream');
        return {
          'success': false,
          'message': response['message'],
        };
      }
    } catch (e) {
      _setError('Error stopping live stream: $e');
      return {
        'success': false,
        'message': 'Error stopping live stream: $e',
      };
    } finally {
      _setLoading(false);
    }
  }

  /// Get active rooms
  Future<Map<String, dynamic>> getActiveRooms({
    String? category,
    int page = 1,
    int limit = 20,
    String? authToken,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await LiveStreamService.getActiveRooms(
        category: category,
        page: page,
        limit: limit,
        authToken: authToken,
      );

      if (response['success'] == true) {
        final roomsData = response['data']['rooms'] as List?;
        if (roomsData != null) {
          _activeRooms = roomsData.map((room) => LiveRoom.fromJson(room)).toList();
        }
        return {
          'success': true,
          'rooms': _activeRooms,
          'total': response['data']['total'] ?? 0,
          'page': response['data']['page'] ?? 1,
          'limit': response['data']['limit'] ?? 20,
        };
      } else {
        _setError(response['message'] ?? 'Failed to get active rooms');
        return {
          'success': false,
          'message': response['message'],
        };
      }
    } catch (e) {
      _setError('Error getting active rooms: $e');
      return {
        'success': false,
        'message': 'Error getting active rooms: $e',
      };
    } finally {
      _setLoading(false);
    }
  }

  /// Clear current room
  void clearCurrentRoom() {
    _currentRoom = null;
    _isLive = false;
    notifyListeners();
  }

  /// Update room status locally
  void updateRoomStatus(String roomId, bool isLive, String status) {
    if (_currentRoom?.id == roomId) {
      _currentRoom = _currentRoom!.copyWith(
        isLive: isLive,
        status: status,
      );
      _isLive = isLive;
      notifyListeners();
    }
  }

  /// Add room to active rooms list
  void addRoomToList(LiveRoom room) {
    if (!_activeRooms.any((r) => r.id == room.id)) {
      _activeRooms.insert(0, room);
      notifyListeners();
    }
  }

  /// Remove room from active rooms list
  void removeRoomFromList(String roomId) {
    _activeRooms.removeWhere((room) => room.id == roomId);
    notifyListeners();
  }

  /// Update room in active rooms list
  void updateRoomInList(LiveRoom updatedRoom) {
    final index = _activeRooms.indexWhere((room) => room.id == updatedRoom.id);
    if (index != -1) {
      _activeRooms[index] = updatedRoom;
      notifyListeners();
    }
  }
}
