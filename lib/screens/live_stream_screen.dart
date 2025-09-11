import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
// import 'package:permission_handler/permission_handler.dart';
import '../providers/auth_provider.dart';
import '../models/live_stream_model.dart';
import '../services/live_stream_service.dart';
import '../utils/app_theme.dart';
import '../widgets/app_loader.dart';

class LiveStreamScreen extends StatefulWidget {
  const LiveStreamScreen({super.key});

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  List<CameraDescription>? cameras;
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isStreaming = false;
  bool _isLoading = false;
  String _currentRoom = 'darshan';
  String _userRole = 'viewer';
  LiveStreamStatus? _streamStatus;
  List<LiveStreamMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  LiveStreamAnalytics? _analytics;
  List<LiveStreamRoom> _availableRooms = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _checkServerHealth();
    _loadAvailableRooms();
    _loadMessages();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      print('LiveStreamScreen: Initializing camera...');
      
      // Request camera permission
      // final status = await Permission.camera.request();
      // if (status != PermissionStatus.granted) {
      //   print('LiveStreamScreen: Camera permission denied');
      //   _showErrorSnackBar('Camera permission is required for live streaming');
      //   return;
      // }

      print('LiveStreamScreen: Camera permission granted');

      // Get available cameras
      try {
        cameras = await availableCameras();
        print('LiveStreamScreen: Found ${cameras?.length ?? 0} cameras');
      } catch (e) {
        print('LiveStreamScreen: Error getting cameras: $e');
        _showErrorSnackBar('Error accessing cameras: $e');
        return;
      }

      if (cameras == null || cameras!.isEmpty) {
        print('LiveStreamScreen: No cameras found');
        _showErrorSnackBar('No cameras found on this device');
        return;
      }

      // Initialize camera controller
      _cameraController = CameraController(
        cameras![0],
        ResolutionPreset.high,
        enableAudio: true,
      );

      print('LiveStreamScreen: Initializing camera controller...');
      await _cameraController!.initialize();
      
      print('LiveStreamScreen: Camera initialized successfully');
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('LiveStreamScreen: Error initializing camera: $e');
      _showErrorSnackBar('Error initializing camera: $e');
    }
  }

  Future<void> _checkServerHealth() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final health = await LiveStreamService.checkHealth();
      if (health.success) {
        _showSuccessSnackBar('Live streaming server is running');
        await _getStreamStatus();
      } else {
        _showErrorSnackBar('Live streaming server is not available');
      }
    } catch (e) {
      _showErrorSnackBar('Error checking server health: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getStreamStatus() async {
    try {
      final status = await LiveStreamService.getLiveStatus(room: _currentRoom);
      setState(() {
        _streamStatus = status;
        _isStreaming = status.isLive;
      });
    } catch (e) {
      print('Error getting stream status: $e');
    }
  }

  Future<void> _loadAvailableRooms() async {
    try {
      final response = await LiveStreamService.getAllLiveStreams();
      if (response.success) {
        setState(() {
          _availableRooms = response.rooms;
        });
      }
    } catch (e) {
      print('Error loading available rooms: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      final response = await LiveStreamService.getMessages(room: _currentRoom);
      if (response.success) {
        setState(() {
          _messages = response.messages;
        });
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  Future<void> _loadAnalytics() async {
    try {
      final analytics = await LiveStreamService.getLiveStreamAnalytics(room: _currentRoom);
      setState(() {
        _analytics = analytics;
      });
    } catch (e) {
      print('Error loading analytics: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userProfile?.id ?? 'user_${DateTime.now().millisecondsSinceEpoch}';

      final response = await LiveStreamService.sendMessage(
        room: _currentRoom,
        userId: userId,
        message: _messageController.text.trim(),
      );

      if (response.success) {
        _messageController.clear();
        await _loadMessages(); // Refresh messages
      } else {
        _showErrorSnackBar('Failed to send message: ${response.message}');
      }
    } catch (e) {
      _showErrorSnackBar('Error sending message: $e');
    }
  }

  Future<void> _switchRoom(String roomName) async {
    setState(() {
      _currentRoom = roomName;
      _isStreaming = false;
      _userRole = 'viewer';
    });
    await _getStreamStatus();
    await _loadMessages();
    await _loadAnalytics();
  }

  Future<void> _startStream() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userProfile?.id ?? 'user_${DateTime.now().millisecondsSinceEpoch}';

      // Start live stream with integrated role assignment
      final roomResponse = await LiveStreamService.startLiveStream(
        room: _currentRoom,
        userId: userId,
      );
      
      if (roomResponse.success) {
        setState(() {
          _isStreaming = true;
          _userRole = 'broadcaster';
        });
        _showSuccessSnackBar('Live stream started successfully!');
        await _getStreamStatus();
      } else {
        _showErrorSnackBar('Failed to start live stream');
      }
    } catch (e) {
      _showErrorSnackBar('Error starting stream: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _stopStream() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final roomResponse = await LiveStreamService.stopLiveStream(room: _currentRoom);
      
      if (roomResponse.success) {
        setState(() {
          _isStreaming = false;
          _userRole = 'viewer';
        });
        _showSuccessSnackBar('Live stream stopped successfully!');
        await _getStreamStatus();
      } else {
        _showErrorSnackBar('Failed to stop live stream');
      }
    } catch (e) {
      _showErrorSnackBar('Error stopping stream: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _joinAsViewer() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userProfile?.id ?? 'user_${DateTime.now().millisecondsSinceEpoch}';

      // Join live stream with integrated viewer role assignment
      final roomResponse = await LiveStreamService.joinLiveStream(
        room: _currentRoom,
        userId: userId,
      );

      if (roomResponse.success) {
        setState(() {
          _userRole = 'viewer';
        });
        _showSuccessSnackBar('Joined as viewer!');
        await _getStreamStatus();
      } else {
        _showErrorSnackBar('Failed to join as viewer');
      }
    } catch (e) {
      _showErrorSnackBar('Error joining as viewer: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Live Darshan',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Container(
            margin: const EdgeInsets.all(8.0),
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Initializing Live Darshan...',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Camera Preview
                if (_isInitialized && _cameraController != null)
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CameraPreview(_cameraController!),
                      ),
                    ),
                  )
                else
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Camera not available',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Controls
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Stream Status
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _isStreaming ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isStreaming ? Icons.live_tv : Icons.tv_off,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isStreaming ? 'LIVE' : 'OFFLINE',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

        // Room Selection
        if (_availableRooms.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Rooms',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _availableRooms.length,
                    itemBuilder: (context, index) {
                      final room = _availableRooms[index];
                      final isSelected = room.room == _currentRoom;
                      return GestureDetector(
                        onTap: () => _switchRoom(room.room),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryColor : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryColor : Colors.grey,
                            ),
                          ),
                          child: Text(
                            room.room,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Room Info
        if (_streamStatus != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoCard(
                'Room',
                _streamStatus!.room,
                Icons.room,
              ),
              _buildInfoCard(
                'Broadcasters',
                '${_streamStatus!.broadcasterCount}',
                Icons.videocam,
              ),
              _buildInfoCard(
                'Viewers',
                '${_streamStatus!.viewerCount}',
                Icons.visibility,
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],

        // Analytics
        if (_analytics != null && _analytics!.success) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stream Analytics',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAnalyticsCard('Total Viewers', '${_analytics!.totalViewers}'),
                    _buildAnalyticsCard('Peak Viewers', '${_analytics!.peakViewers}'),
                    _buildAnalyticsCard('Avg Viewers', '${_analytics!.averageViewers.toStringAsFixed(1)}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

                        // Action Buttons
                        Row(
                          children: [
                            if (!_isStreaming) ...[
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _startStream,
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Start Stream'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _joinAsViewer,
                                  icon: const Icon(Icons.visibility),
                                  label: const Text('Join as Viewer'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _stopStream,
                                  icon: const Icon(Icons.stop),
                                  label: const Text('Stop Stream'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Messages Section
                        if (_messages.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Container(
                            height: 150,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Live Chat',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _messages.length,
                                    itemBuilder: (context, index) {
                                      final message = _messages[index];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Text(
                                          '${message.username ?? message.userId}: ${message.message}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Message Input
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: 'Type a message...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _sendMessage,
                              icon: const Icon(Icons.send),
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}
