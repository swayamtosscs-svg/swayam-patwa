import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/live_stream_service.dart';
import '../services/camera_service.dart';
import '../providers/auth_provider.dart';

class NativeStreamHostScreen extends StatefulWidget {
  final String roomId;
  final String streamKey;
  final String title;
  final String hostName;

  const NativeStreamHostScreen({
    super.key,
    required this.roomId,
    required this.streamKey,
    required this.title,
    required this.hostName,
  });

  @override
  State<NativeStreamHostScreen> createState() => _NativeStreamHostScreenState();
}

class _NativeStreamHostScreenState extends State<NativeStreamHostScreen> {
  bool _isStreaming = false;
  bool _isLoading = false;
  bool _cameraReady = false;
  Map<String, dynamic>? _roomStatus;
  Map<String, dynamic>? _analytics;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadRoomStatus();
  }

  Future<void> _initializeCamera() async {
    try {
      print('NativeStreamHostScreen: Starting camera initialization...');
      
      if (kIsWeb) {
        // For web platform, skip native camera initialization
        print('NativeStreamHostScreen: Web platform detected, skipping native camera...');
        _cameraReady = true; // Set to true to show web interface
        print('NativeStreamHostScreen: Web camera ready: $_cameraReady');
      } else {
        // Use native camera service for mobile platforms
        _cameraReady = await CameraService.initializeCamera();
        print('NativeStreamHostScreen: Native camera ready: $_cameraReady');
        
        if (_cameraReady) {
          print('NativeStreamHostScreen: Starting native camera preview...');
          await CameraService.startPreview();
          print('NativeStreamHostScreen: Native camera preview started');
        }
      }
      
      // Auto-start streaming if room is already live
      if (_roomStatus != null && _roomStatus!['isLive'] == true) {
        setState(() {
          _isStreaming = true;
        });
      }
    } catch (e) {
      print('NativeStreamHostScreen: Camera error: $e');
      setState(() {
        _errorMessage = 'Camera initialization failed: $e';
      });
    }
  }

  Future<void> _loadRoomStatus() async {
    try {
      print('NativeStreamHostScreen: Loading room status...');
      final result = await LiveStreamService.getRoomStatus(widget.roomId);
      if (result['success'] == true) {
        setState(() {
          _roomStatus = result['data'];
          _isStreaming = _roomStatus?['isLive'] ?? false;
        });
        print('NativeStreamHostScreen: Room status loaded - isLive: $_isStreaming');
      } else {
        print('NativeStreamHostScreen: Failed to load room status: ${result['message']}');
      }
    } catch (e) {
      print('NativeStreamHostScreen: Error loading room status: $e');
    }
  }

  Future<void> _loadAnalytics() async {
    try {
      final result = await LiveStreamService.getRoomAnalytics(widget.roomId);
      if (result['success'] == true) {
        setState(() {
          _analytics = result['data'];
        });
      }
    } catch (e) {
      print('Error loading analytics: $e');
    }
  }

  Future<void> _startStreaming() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('NativeStreamHostScreen: Starting live stream...');
      final result = await LiveStreamService.startLiveStream(
        roomId: widget.roomId,
        streamKey: widget.streamKey,
      );

      print('NativeStreamHostScreen: Start stream result: ${result['success']}');
      
      if (result['success'] == true) {
        setState(() {
          _isStreaming = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Live stream started successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRoomStatus();
        _loadAnalytics();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to start stream'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('NativeStreamHostScreen: Error starting stream: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting stream: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _stopStreaming() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await LiveStreamService.stopLiveStream(
        roomId: widget.roomId,
      );

      if (result['success'] == true) {
        setState(() {
          _isStreaming = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Live stream stopped'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadRoomStatus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to stop stream'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error stopping stream: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(),
            
            // Main Content
            Expanded(
              child: _buildMainContent(),
            ),
            
            // Bottom Controls
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Stream Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Host: ${widget.hostName}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontFamily: 'Poppins',
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Live Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isStreaming ? Colors.red : Colors.grey,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isStreaming ? 'LIVE' : 'OFFLINE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
                _initializeCamera();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!_cameraReady) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Initializing camera...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
                _initializeCamera();
              },
              child: const Text('Retry Camera'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Camera Preview or Web Interface
        if (kIsWeb)
          // Web interface
          _buildWebStreamInterface()
        else if (CameraService.cameraController != null)
          // Native camera preview (mobile/Windows)
          Center(
            child: AspectRatio(
              aspectRatio: CameraService.cameraController!.value.aspectRatio,
              child: CameraPreview(CameraService.cameraController!),
            ),
          )
        else
          // Fallback interface
          _buildWebStreamInterface(),
        
        // Streaming Overlay
        if (_isStreaming)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.videocam,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'STREAMING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Stats Overlay
        if (_analytics != null)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Viewers: ${_analytics!['viewerCount'] ?? 0}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Duration: ${_formatDuration(_analytics!['duration'] ?? 0)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Web Host Button (for web platforms)
          if (kIsWeb)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Open web host page in new tab
                  final hostUrl = 'https://new-live-api.onrender.com/host.html?room=${widget.roomId}&key=${widget.streamKey}';
                  try {
                    await launchUrl(Uri.parse(hostUrl), webOnlyWindowName: '_blank');
                  } catch (e) {
                    print('Error opening web host page: $e');
                  }
                },
                icon: const Icon(Icons.web),
                label: const Text('Open Web Host Page'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          // Main Control Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : (_isStreaming ? _stopStreaming : _startStreaming),
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(_isStreaming ? Icons.stop : Icons.play_arrow),
              label: Text(
                _isLoading
                    ? (_isStreaming ? 'Stopping...' : 'Starting...')
                    : (_isStreaming ? 'Stop Stream' : 'Start Stream'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isStreaming ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Room Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Room ID: ${widget.roomId}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stream Key: ${widget.streamKey}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebStreamInterface() {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Web Camera Video Element
          if (kIsWeb)
            Positioned.fill(
              child: _buildWebCameraView(),
            ),
          
          // Overlay Content
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Host: ${widget.hostName}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Status Indicator
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isStreaming ? Colors.red : Colors.grey,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isStreaming ? Icons.videocam : Icons.videocam_off,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isStreaming ? 'LIVE' : 'READY',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebCameraView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.videocam,
              color: Colors.white,
              size: 80,
            ),
            const SizedBox(height: 24),
            const Text(
              'Web Camera Access',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Click "Open Web Host Page" to access camera\nand start streaming with full browser support',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final hostUrl = 'https://new-live-api.onrender.com/host.html?room=${widget.roomId}&key=${widget.streamKey}';
                try {
                  await launchUrl(Uri.parse(hostUrl), webOnlyWindowName: '_blank');
                } catch (e) {
                  print('Error opening web host page: $e');
                }
              },
              icon: const Icon(Icons.videocam),
              label: const Text('Access Camera & Stream'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      CameraService.dispose();
    }
    super.dispose();
  }
}
