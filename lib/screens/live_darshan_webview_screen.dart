import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:async';
import '../services/live_streaming_service.dart';
import '../services/camera_service.dart';

class LiveDarshanWebViewScreen extends StatefulWidget {
  const LiveDarshanWebViewScreen({super.key});

  @override
  State<LiveDarshanWebViewScreen> createState() => _LiveDarshanWebViewScreenState();
}

class _LiveDarshanWebViewScreenState extends State<LiveDarshanWebViewScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _serverStatus;
  bool _isStreamJoined = false;
  String? _currentRoomName = 'my-room';
  bool _isInitialized = false; // Prevent multiple initialization calls
  bool _isStreaming = false; // Track if currently streaming
  int _viewerCount = 0; // Track viewer count
  Map<String, dynamic>? _roomInfo; // Store room information
  List<String> _availableRooms = []; // List of available rooms
  String? _selectedRoom; // Currently selected room

  @override
  void initState() {
    super.initState();
    // Direct initialization for immediate redirect
    _initializeWebViewDirectly();
    // Start room updates
    _startRoomUpdates();
    // Fetch initial room info
    _fetchRoomInfo();
    // Load available rooms
    _loadAvailableRooms();
  }

  @override
  void dispose() {
    // Dispose camera resources
    CameraService.dispose();
    super.dispose();
  }

  void _initializeWebViewDirectly() async {
    try {
      // Prevent multiple initialization calls
      if (_isInitialized) {
        debugPrint('WebView already initialized, skipping...');
        return;
      }
      
      _isInitialized = true;
      
      // Initialize Live Streaming Service first
      LiveStreamingService.initialize();
      
      // Initialize camera for Live Darshan (only once)
      if (!CameraService.isInitialized) {
        debugPrint('Initializing camera for Live Darshan...');
        final cameraInitialized = await CameraService.initializeCamera();
        if (cameraInitialized) {
          debugPrint('Camera initialized successfully for Live Darshan');
          await CameraService.startPreview();
        } else {
          debugPrint('Camera initialization failed, continuing without camera');
        }
      } else {
        debugPrint('Camera already initialized, skipping...');
      }
      
      try {
        _controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color(0xFFFFFFFF)) // White background for mobile
          ..setUserAgent('Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
          ..enableZoom(true)
          ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              debugPrint('WebView is loading (progress : $progress%)');
              setState(() {
                if (progress < 100) {
                  _errorMessage = 'Loading Live Darshan... ($progress%)';
                  _isLoading = true;
                } else {
                  _isLoading = false;
                  _errorMessage = null;
                }
              });
            },
            onPageStarted: (String url) {
              debugPrint('Page started loading: $url');
              setState(() {
                _isLoading = true;
                _errorMessage = 'Connecting to server...';
              });
            },
            onPageFinished: (String url) {
              debugPrint('Page finished loading: $url');
              setState(() {
                _isLoading = false;
                _errorMessage = null;
              });
              // Additional mobile debugging
              debugPrint('Mobile WebView page loaded successfully');
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
              ''');
              
              // Handle specific error codes
              String errorMsg = 'Connection failed. Retrying...';
              if (error.errorCode == -2) {
                errorMsg = 'Network error. Check your internet connection.';
              } else if (error.errorCode == -6) {
                errorMsg = 'Server not responding. Retrying...';
              } else if (error.errorCode == -8) {
                errorMsg = 'SSL certificate error. Retrying...';
              }
              
              setState(() {
                _errorMessage = errorMsg;
                _isLoading = true;
              });
              
              // Retry loading after error with exponential backoff
              Future.delayed(const Duration(seconds: 5), () {
                if (mounted && _controller != null) {
                  _controller!.reload();
                }
              });
            },
            onNavigationRequest: (NavigationRequest request) {
              debugPrint('Navigation request to: ${request.url}');
              // Allow navigation within the live streaming domain and mobile-specific URLs
              if (request.url.contains('103.14.120.163') || 
                  request.url.contains('localhost') ||
                  request.url.contains('127.0.0.1') ||
                  request.url.startsWith('data:') ||
                  request.url.startsWith('javascript:') ||
                  request.url.startsWith('blob:') ||
                  request.url.startsWith('file:') ||
                  request.url.startsWith('ws:') ||
                  request.url.startsWith('wss:') ||
                  request.url.startsWith('about:blank')) {
                return NavigationDecision.navigate;
              }
              // Block external redirects
              debugPrint('Blocking external navigation to: ${request.url}');
              return NavigationDecision.prevent;
            },
            onHttpError: (HttpResponseError error) {
              debugPrint('HTTP error: ${error.response?.statusCode}');
              String errorMsg = 'Server error. Retrying...';
              if (error.response?.statusCode == 404) {
                errorMsg = 'Server not found. Retrying...';
              } else if (error.response?.statusCode == 500) {
                errorMsg = 'Server internal error. Retrying...';
              } else if (error.response?.statusCode == 503) {
                errorMsg = 'Server temporarily unavailable. Retrying...';
              }
              
              setState(() {
                _errorMessage = errorMsg;
                _isLoading = true;
              });
              
              // Retry after error
              Future.delayed(const Duration(seconds: 8), () {
                if (mounted && _controller != null) {
                  _controller!.reload();
                }
              });
            },
          ),
        )
        ..addJavaScriptChannel(
          'Toaster',
          onMessageReceived: (JavaScriptMessage message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message.message)),
            );
          },
        );
        
        // Load the URL immediately
        _loadUrlDirectly();
        
      } catch (webViewError) {
        debugPrint('WebView controller creation failed: $webViewError');
        // Continue without WebView - show error fallback
        setState(() {
          _errorMessage = 'WebView not available on this platform';
          _isLoading = false;
        });
      }
      
    } catch (e) {
      debugPrint('Error in WebView initialization: $e');
      setState(() {
        _errorMessage = 'Failed to initialize. Retrying...';
        _isLoading = true;
      });
      
      // Retry after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _initializeWebViewDirectly();
        }
      });
    }
  }


  void _loadUrlDirectly() async {
    try {
      // Check server status first
      debugPrint('Checking server status...');
      final serverStatus = await LiveStreamingService.getServerStatus();
      debugPrint('Server status: $serverStatus');
      
      // Add headers optimized for mobile WebView
      Map<String, String> headers = {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      };
      
      debugPrint('Loading Live Darshan URL: https://103.14.120.163:8443/');
      debugPrint('Headers: $headers');
      
      _controller!.loadRequest(
        Uri.parse('https://103.14.120.163:8443/'),
        headers: headers,
      );
      
      // Set a timeout to retry if loading takes too long
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _isLoading) {
          debugPrint('WebView loading timeout, trying HTTP fallback...');
          setState(() {
            _errorMessage = 'Trying alternative connection...';
          });
          _tryHttpFallback();
        }
      });
    } catch (e) {
      debugPrint('Error loading URL: $e');
      setState(() {
        _errorMessage = 'Failed to load. Retrying...';
        _isLoading = true;
      });
      
      // Retry with exponential backoff
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _loadUrlDirectly();
        }
      });
    }
  }

  void _tryHttpFallback() async {
    try {
      debugPrint('Trying HTTP fallback: http://103.14.120.163:8443/');
      
      // Try to create a Live Darshan room
      try {
        final roomInfo = await LiveStreamingService.createRoom('live_darshan');
        debugPrint('Created Live Darshan room: $roomInfo');
      } catch (e) {
        debugPrint('Room creation failed, continuing with direct access: $e');
      }
      
      Map<String, String> headers = {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      };
      
      _controller!.loadRequest(
        Uri.parse('http://103.14.120.163:8443/'),
        headers: headers,
      );
    } catch (e) {
      debugPrint('HTTP fallback failed: $e');
      setState(() {
        _errorMessage = 'Connection failed. Please check your network.';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkServerStatus() async {
    try {
      // Initialize SSL bypass for live streaming server
      await LiveStreamingService.initialize();
      
      final status = await LiveStreamingService.getServerStatus();
      setState(() {
        _serverStatus = status;
      });
      
      debugPrint('Server status: $status');
      
      // Try to join Live Darshan room as viewer
      try {
        final joinResult = await LiveStreamingService.joinRoom('live_darshan', 'viewer');
        debugPrint('Joined Live Darshan room: $joinResult');
      } catch (e) {
        debugPrint('Failed to join room, continuing with direct access: $e');
      }
      
      // If server is available, try to load WebView
      if (status['status'] == 'running') {
        debugPrint('Server is available, loading Live Darshan...');
        _loadUrlDirectly();
      } else {
        debugPrint('Server not available, retrying...');
        setState(() {
          _errorMessage = 'Server not responding. Retrying...';
        });
        // Retry server check after delay
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            _checkServerStatus();
          }
        });
      }
    } catch (e) {
      debugPrint('Error checking server status: $e');
      setState(() {
        _errorMessage = 'Server not responding. Retrying...';
      });
      // Retry server check after delay
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          _checkServerStatus();
        }
      });
    }
  }

  void _refreshPage() {
    if (_controller != null) {
      _controller!.reload();
    } else {
      // Reinitialize WebView if controller is null
      _initializeWebViewDirectly();
    }
  }

  void _goBack() {
    if (_controller != null) {
      _controller!.goBack();
    }
  }

  void _goForward() {
    if (_controller != null) {
      _controller!.goForward();
    }
  }

  void _goHome() {
    if (_controller != null) {
      _loadUrlDirectly();
    } else {
      // Reinitialize WebView if controller is null
      _initializeWebViewDirectly();
    }
  }

  // Stream Join Functionality
  Future<void> _joinStream() async {
    try {
      debugPrint('Joining stream for room: $_currentRoomName');
      
      // Step 1: Check camera permissions (optional for viewers)
      debugPrint('Checking camera permissions for viewer...');
      final permissions = await CameraService.checkPermissions();
      
      // Step 2: Join the room as viewer
      final joinResult = await LiveStreamingService.joinRoom(_currentRoomName!, 'viewer');
      debugPrint('Stream join result: $joinResult');
      
      setState(() {
        _isStreamJoined = true;
      });
      
      // Step 3: Initialize camera if permissions are available (for potential interaction)
      if (permissions['camera']! && permissions['microphone']!) {
        debugPrint('Initializing camera for viewer interaction...');
        final cameraInitialized = await CameraService.initializeCamera();
        if (cameraInitialized) {
          await CameraService.startPreview();
          debugPrint('Camera ready for viewer interaction');
        }
      }
      
      // Step 4: Show success message with connection info
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Successfully joined stream: $_currentRoomName'),
              if (joinResult['clientId'] != null)
                Text('Client ID: ${joinResult['clientId']}'),
              if (joinResult['websocketUrl'] != null)
                Text('WebSocket: ${joinResult['websocketUrl']}'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
      
    } catch (e) {
      debugPrint('Error joining stream: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join stream: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _startStream() async {
    try {
      debugPrint('Starting stream for room: $_currentRoomName');
      
      // Step 1: Check platform and camera availability
      if (Platform.isWindows) {
        debugPrint('Windows platform detected - camera not available, starting stream without camera');
        
        // Start streaming as broadcaster with exact broadcasterId from curl command
        final startResult = await LiveStreamingService.startStream(_currentRoomName!, 'broadcaster123');
        debugPrint('Stream start result: $startResult');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stream started successfully (Windows - no camera): $_currentRoomName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
      
      // Step 2: Check and request camera permissions (for mobile platforms)
      debugPrint('Checking camera permissions...');
      final permissions = await CameraService.requestPermissions();
      
      if (!permissions['camera']! || !permissions['microphone']!) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera and microphone permissions are required to start streaming'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
      
      // Step 3: Initialize camera
      debugPrint('Initializing camera for streaming...');
      final cameraInitialized = await CameraService.initializeCamera();
      
      if (!cameraInitialized) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize camera. Please check camera access.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
      
      // Step 4: Start camera preview
      debugPrint('Starting camera preview...');
      await CameraService.startPreview();
      
      // Step 5: Start streaming as broadcaster with exact broadcasterId from curl command
      debugPrint('Starting stream with broadcasterId: broadcaster123');
      final startResult = await LiveStreamingService.startStream(_currentRoomName!, 'broadcaster123');
      debugPrint('Stream start result: $startResult');
      
      // Update streaming state
      setState(() {
        _isStreaming = true;
      });
      
      // Step 6: Show success message with camera info
      final cameraInfo = CameraService.getCameraInfo();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stream started successfully: $_currentRoomName'),
              if (cameraInfo['isInitialized'] == true)
                Text('Camera: ${cameraInfo['cameraName']} (${cameraInfo['resolution']})'),
              const Text('🔴 LIVE STREAMING ACTIVE'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
      
    } catch (e) {
      debugPrint('Error starting stream: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start stream: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _stopStream() async {
    try {
      debugPrint('Stopping stream for room: $_currentRoomName');
      
      // Stop streaming as broadcaster with exact broadcasterId from curl command
      final stopResult = await LiveStreamingService.stopStream(_currentRoomName!, 'broadcaster123');
      debugPrint('Stream stop result: $stopResult');
      
      // Update streaming state
      setState(() {
        _isStreaming = false;
      });
      
      // Stop camera preview if running
      if (CameraService.isInitialized) {
        await CameraService.stopPreview();
        debugPrint('Camera preview stopped');
      }
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stream stopped successfully: $_currentRoomName'),
              if (stopResult['message'] != null)
                Text('Message: ${stopResult['message']}'),
              const Text('⏹️ STREAMING STOPPED'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      
    } catch (e) {
      debugPrint('Error stopping stream: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to stop stream: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Fetch room information and viewer count
  Future<void> _fetchRoomInfo() async {
    try {
      debugPrint('Fetching room info for: $_currentRoomName');
      final roomInfo = await LiveStreamingService.getRoomInfo(_currentRoomName!);
      setState(() {
        _roomInfo = roomInfo;
        _viewerCount = roomInfo['viewerCount'] ?? 0;
      });
      debugPrint('Room info updated: $roomInfo');
    } catch (e) {
      debugPrint('Error fetching room info: $e');
    }
  }

  // Update viewer count periodically
  void _startRoomUpdates() {
    // Fetch room info every 5 seconds
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _fetchRoomInfo();
      } else {
        timer.cancel();
      }
    });
  }

  // Show camera preview widget with live stream indicator
  Widget _buildCameraPreview() {
    // If streaming is active, show the live stream to viewers
    if (_isStreaming) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: Stack(
          children: [
            // Live Stream Display for Viewers
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.live_tv, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    const Text(
                      'LIVE STREAM',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Room: $_currentRoomName',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red, width: 1),
                      ),
                      child: const Text(
                        '🔴 LIVE NOW',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Live Stream Indicator
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.live_tv, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Viewer Count Overlay
            if (_viewerCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.visibility, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$_viewerCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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

    // If not streaming, show camera preview or placeholder
    if (Platform.isWindows || !CameraService.isInitialized) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off, color: Colors.white54, size: 48),
              SizedBox(height: 8),
              Text(
                'No Live Stream',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
              SizedBox(height: 4),
              Text(
                'Start streaming to show live feed',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    // Camera preview for broadcaster
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Stack(
        children: [
          // Camera Preview
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CameraPreview(CameraService.cameraController!),
          ),
          
          // Ready to Stream Indicator
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'READY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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

  // Show room information widget with join functionality
  Widget _buildRoomInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room Header
          Row(
            children: [
              const Icon(Icons.room, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Room: $_currentRoomName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Create Room Button
              IconButton(
                icon: const Icon(Icons.add, color: Colors.green, size: 20),
                onPressed: _createRoom,
                tooltip: 'Create New Room',
              ),
              // Select Room Button
              IconButton(
                icon: const Icon(Icons.list, color: Colors.orange, size: 20),
                onPressed: _selectRoom,
                tooltip: 'Select Room',
              ),
              // Share Room Button
              IconButton(
                icon: const Icon(Icons.share, color: Colors.blue, size: 20),
                onPressed: _shareRoom,
                tooltip: 'Share Room Link',
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Viewer Count and Status
          Row(
            children: [
              const Icon(Icons.visibility, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Viewers: $_viewerCount',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const Spacer(),
              Icon(
                _isStreaming ? Icons.live_tv : Icons.tv_off,
                color: _isStreaming ? Colors.red : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _isStreaming ? 'LIVE' : 'OFFLINE',
                style: TextStyle(
                  color: _isStreaming ? Colors.red : Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Join as Viewer Button (prominent)
          if (!_isStreamJoined)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _joinStream,
                icon: const Icon(Icons.video_call, color: Colors.white),
                label: const Text(
                  'Join as Viewer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          
          // Already Joined Status
          if (_isStreamJoined)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Successfully Joined as Viewer',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Load available rooms from server
  Future<void> _loadAvailableRooms() async {
    try {
      debugPrint('Loading available rooms from server...');
      final rooms = await LiveStreamingService.getAllRooms();
      
      setState(() {
        _availableRooms = rooms.map((room) => room['roomName'] as String).toList();
        _selectedRoom = _currentRoomName;
      });
      
      debugPrint('Available rooms loaded from server: $_availableRooms');
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded ${_availableRooms.length} rooms from server'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading rooms from server: $e');
      
      // Fallback to default rooms
      setState(() {
        _availableRooms = [
          'my-room',
          'live-darshan',
          'morning-prayer',
          'evening-darshan',
          'spiritual-talk',
        ];
        _selectedRoom = _currentRoomName;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Using default rooms (Server error: $e)'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Create a new room
  Future<void> _createRoom() async {
    try {
      final TextEditingController roomController = TextEditingController();
      
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text(
            'Create New Room',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: roomController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Room Name',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, roomController.text.trim()),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Create', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (result != null && result.isNotEmpty) {
        debugPrint('Creating room: $result');
        final createResult = await LiveStreamingService.createRoom(result);
        debugPrint('Room created: $createResult');
        
        setState(() {
          _currentRoomName = result;
          _selectedRoom = result;
        });
        
        // Add to available rooms if not already present
        if (!_availableRooms.contains(result)) {
          setState(() {
            _availableRooms.add(result);
          });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Room "$result" created successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Fetch room info for the new room
        _fetchRoomInfo();
      }
    } catch (e) {
      debugPrint('Error creating room: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create room: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Select room for joining with real room information
  Future<void> _selectRoom() async {
    try {
      // Fetch fresh room data
      final rooms = await LiveStreamingService.getAllRooms();
      
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.black87,
          title: Row(
            children: [
              const Text(
                'Browse Rooms',
                style: TextStyle(color: Colors.white),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.blue),
                onPressed: () {
                  Navigator.pop(context, 'refresh');
                },
                tooltip: 'Refresh Rooms',
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                final roomName = room['roomName'] as String;
                final viewerCount = room['viewerCount'] ?? 0;
                final broadcasterCount = room['broadcasterCount'] ?? 0;
                final isStreaming = room['isStreaming'] ?? false;
                final description = room['description'] ?? 'Live Darshan Room';
                final isSelected = roomName == _selectedRoom;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey[700]!,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      isStreaming ? Icons.live_tv : Icons.room,
                      color: isStreaming ? Colors.red : Colors.white70,
                      size: 24,
                    ),
                    title: Text(
                      roomName,
                      style: TextStyle(
                        color: isSelected ? Colors.blue : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          description,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.visibility,
                              size: 14,
                              color: Colors.white54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$viewerCount viewers',
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.videocam,
                              size: 14,
                              color: Colors.white54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$broadcasterCount broadcasters',
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: isStreaming
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: isSelected ? Colors.blue : Colors.white70,
                          ),
                    onTap: () => Navigator.pop(context, roomName),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, _selectedRoom),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Join Room', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (result == 'refresh') {
        // Refresh rooms and show dialog again
        _loadAvailableRooms();
        Future.delayed(const Duration(milliseconds: 500), () {
          _selectRoom();
        });
        return;
      }

      if (result != null && result != _currentRoomName) {
        setState(() {
          _currentRoomName = result;
          _selectedRoom = result;
          _isStreamJoined = false; // Reset join status when changing rooms
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to room: $result'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Fetch room info for the selected room
        _fetchRoomInfo();
      }
    } catch (e) {
      debugPrint('Error selecting room: $e');
    }
  }

  // Show stream URL for viewers
  Future<void> _showStreamUrl() async {
    try {
      final streamUrl = 'https://103.14.120.163:8443/api/rooms/$_currentRoomName/stream';
      
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text(
            'Live Stream URL',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Stream URL for viewers:',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: SelectableText(
                  streamUrl,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Share this URL with viewers to let them watch the live stream.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: streamUrl));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Stream URL copied to clipboard!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Copy URL', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error showing stream URL: $e');
    }
  }

  // Share room functionality
  Future<void> _shareRoom() async {
    try {
      final roomLink = 'https://103.14.120.163:8443/api/rooms/$_currentRoomName';
      final shareText = 'Join my Live Darshan room: $_currentRoomName\n\nRoom Link: $roomLink\n\nDownload R_GRam app to join the live stream!';
      
      await Clipboard.setData(ClipboardData(text: shareText));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Room link copied to clipboard!'),
              Text('Room: $_currentRoomName'),
              const Text('Share this link with others to let them join as viewers'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      debugPrint('Error sharing room: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share room: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _openStreamUrl(String url) async {
    try {
      debugPrint('Opening stream URL: $url');
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot open URL: $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error opening URL: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening URL: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildErrorFallback() {
    return Container(
      color: Colors.white, // Changed to white for mobile visibility
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Server Status Indicator
              if (_serverStatus != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _serverStatus!['status'] == 'running' ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _serverStatus!['status'] == 'running' ? 'SERVER ONLINE' : 'SERVER OFFLINE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              
              const SizedBox(height: 32),
              
              // Loading indicator with different states
              if (_isLoading)
                const CircularProgressIndicator(
                  color: Colors.orange,
                  strokeWidth: 4,
                )
              else
                const Icon(
                  Icons.wifi_off,
                  color: Colors.red,
                  size: 48,
                ),
              
              const SizedBox(height: 24),
              
              const Text(
                'Live Darshan',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 28,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                _errorMessage ?? 'Connecting to server...',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Action buttons
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _refreshPage,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          _checkServerStatus();
                        },
                        icon: const Icon(Icons.network_check),
                        label: const Text('Check Server'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Debug button for mobile troubleshooting
                  ElevatedButton.icon(
                    onPressed: () async {
                      debugPrint('=== MOBILE DEBUG INFO ===');
                      debugPrint('Controller: $_controller');
                      debugPrint('Is Loading: $_isLoading');
                      debugPrint('Error Message: $_errorMessage');
                      debugPrint('Server Status: $_serverStatus');
                      
                      // Camera info
                      final cameraInfo = CameraService.getCameraInfo();
                      debugPrint('Camera Info: $cameraInfo');
                      
                      // Permissions info
                      final permissions = await CameraService.checkPermissions();
                      debugPrint('Permissions: $permissions');
                      
                      debugPrint('========================');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Debug info printed to console\nCamera: ${(cameraInfo['isInitialized'] ?? false) ? 'Ready' : 'Not Ready'}'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                    // removed debug bug icon
                    icon: const Icon(Icons.close, color: Colors.transparent),
                    label: const Text('Debug Info'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Camera control buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final permissions = await CameraService.requestPermissions();
                          if ((permissions['camera'] ?? false) && (permissions['microphone'] ?? false)) {
                            final initialized = await CameraService.initializeCamera();
                            if (initialized) {
                              await CameraService.startPreview();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Camera started for Live Darshan')),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Camera/Microphone permission required')),
                            );
                          }
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Start Camera'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await CameraService.switchCamera();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Camera switched')),
                          );
                        },
                        icon: const Icon(Icons.switch_camera),
                        label: const Text('Switch'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Server URL
              GestureDetector(
                onTap: () async {
                  final Uri url = Uri.parse('https://103.14.120.163:8443/');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Text(
                  'https://103.14.120.163:8443/',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Help text
              const Text(
                'If connection fails, please check your internet connection and try again',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // Additional troubleshooting
              const Text(
                'Make sure you have a stable internet connection',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Live Darshan',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          // Stream Join Button
          IconButton(
            icon: Icon(
              _isStreamJoined ? Icons.video_call : Icons.video_call_outlined,
              color: _isStreamJoined ? Colors.green : Colors.white,
            ),
            onPressed: _joinStream,
            tooltip: 'Join Stream',
          ),
          // Start Stream Button
          IconButton(
            icon: const Icon(Icons.play_circle_outline, color: Colors.white),
            onPressed: _startStream,
            tooltip: 'Start Stream',
          ),
          // Stop Stream Button
          IconButton(
            icon: const Icon(Icons.stop_circle_outlined, color: Colors.white),
            onPressed: _stopStream,
            tooltip: 'Stop Stream',
          ),
          // Camera Status Indicator
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Platform.isWindows 
                ? Colors.grey 
                : (CameraService.isInitialized ? Colors.blue : Colors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              Platform.isWindows 
                ? 'NO CAMERA' 
                : (CameraService.isInitialized ? 'CAMERA ON' : 'CAMERA OFF'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Server Status Indicator
          if (_serverStatus != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _serverStatus!['status'] == 'running' ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _serverStatus!['status'] == 'running' ? 'ONLINE' : 'OFFLINE',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshPage,
          ),
        ],
      ),
      body: Column(
        children: [
          // Room Information Panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: _buildRoomInfo(),
          ),
          
          // Camera Preview Panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildCameraPreview(),
          ),
          
          const SizedBox(height: 8),
          
          // WebView Container
          Expanded(
            child: Stack(
              children: [
                // WebView or Error Fallback
                if (_controller != null)
                  WebViewWidget(controller: _controller!)
                else
                  _buildErrorFallback(),
                
                // Loading Indicator
                if (_isLoading && _controller != null)
                  Container(
                    color: Colors.black,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Loading Live Darshan...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 60,
        color: Colors.black87,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: _goBack,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
              onPressed: _goForward,
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _refreshPage,
            ),
            IconButton(
              icon: const Icon(Icons.home, color: Colors.white),
              onPressed: _goHome,
            ),
            IconButton(
              icon: const Icon(Icons.fullscreen, color: Colors.white),
              onPressed: () {
                if (_controller != null) {
                  // Toggle fullscreen mode
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        backgroundColor: Colors.black,
                        body: WebViewWidget(controller: _controller!),
                        appBar: AppBar(
                          backgroundColor: Colors.black,
                          leading: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          title: const Text(
                            'Live Darshan - Fullscreen',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.black87,
            builder: (context) => Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Live Stream Controls',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Join as Viewer (Primary Action)
                  if (!_isStreamJoined)
                    _buildStreamActionButton(
                      'Join as Viewer',
                      () {
                        Navigator.pop(context);
                        _joinStream();
                      },
                      Icons.video_call,
                      Colors.blue,
                    ),
                  
                  // Already Joined Status
                  if (_isStreamJoined)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Joined as Viewer',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 12),
                  
                  // Start Stream (for broadcasters)
                  _buildStreamActionButton(
                    'Start Broadcasting',
                    () {
                      Navigator.pop(context);
                      _startStream();
                    },
                    Icons.play_circle_outline,
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  
                  // Stop Stream
                  _buildStreamActionButton(
                    'Stop Broadcasting',
                    () {
                      Navigator.pop(context);
                      _stopStream();
                    },
                    Icons.stop_circle_outlined,
                    Colors.red,
                  ),
                  const SizedBox(height: 12),
                  
                  // Create Room
                  _buildStreamActionButton(
                    'Create New Room',
                    () {
                      Navigator.pop(context);
                      _createRoom();
                    },
                    Icons.add,
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  
                  // Select Room
                  _buildStreamActionButton(
                    'Select Room',
                    () {
                      Navigator.pop(context);
                      _selectRoom();
                    },
                    Icons.list,
                    Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  
                  // View Stream URL (for viewers)
                  if (_isStreaming)
                    _buildStreamActionButton(
                      'View Stream URL',
                      () {
                        Navigator.pop(context);
                        _showStreamUrl();
                      },
                      Icons.link,
                      Colors.cyan,
                    ),
                  
                  if (_isStreaming) const SizedBox(height: 12),
                  
                  // Share Room
                  _buildStreamActionButton(
                    'Share Room Link',
                    () {
                      Navigator.pop(context);
                      _shareRoom();
                    },
                    Icons.share,
                    Colors.purple,
                  ),
                  const SizedBox(height: 20),
                  
                  Text(
                    'Room: $_currentRoomName | Viewers: $_viewerCount',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.live_tv, color: Colors.white),
        label: const Text(
          'Join Live Stream',
          style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
        ),
      ),
    );
  }

  Widget _buildStreamActionButton(String title, VoidCallback onPressed, IconData icon, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildStreamUrlButton(String title, String url, IconData icon, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _openStreamUrl(url),
        icon: Icon(icon, color: Colors.white),
        label: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}