import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/live_stream_service.dart';
import '../widgets/cross_platform_webview.dart';

class InAppViewerScreen extends StatefulWidget {
  final Map<String, dynamic> stream;
  final String? userName;

  const InAppViewerScreen({
    super.key,
    required this.stream,
    this.userName,
  });

  @override
  State<InAppViewerScreen> createState() => _InAppViewerScreenState();
}

class _InAppViewerScreenState extends State<InAppViewerScreen> {
  WebViewController? _webViewController;
  bool _isLoading = true;
  bool _isJoined = false;
  Map<String, dynamic>? _analytics;
  Map<String, dynamic>? _joinData;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _joinRoom();
  }

  Future<void> _joinRoom() async {
    if (kIsWeb) return; // Skip join on web, just show stream
    
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await LiveStreamService.joinRoom(
        roomId: widget.stream['id'],
        userName: widget.userName ?? 'Viewer',
      );

      if (result['success'] == true) {
        setState(() {
          _joinData = result['data'];
          _isJoined = true;
          _userId = result['data']['viewer']['id'];
        });
        _loadAnalytics();
        print('Successfully joined room as ${result['data']['viewer']['name']}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to join room'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error joining room: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAnalytics() async {
    try {
      final result = await LiveStreamService.getRoomAnalytics(widget.stream['id']);
      if (result['success'] == true) {
        setState(() {
          _analytics = result['data'];
        });
      }
    } catch (e) {
      print('Error loading analytics: $e');
    }
  }

  Future<void> _leaveRoom() async {
    if (!_isJoined || _userId == null) return;
    
    try {
      print('Leaving room ${widget.stream['id']} as user $_userId');
      final result = await LiveStreamService.leaveRoom(
        roomId: widget.stream['id'],
        userId: _userId!,
      );
      
      if (result['success'] == true) {
        print('Successfully left room');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Left the room'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        print('Failed to leave room: ${result['message']}');
      }
    } catch (e) {
      print('Error leaving room: $e');
    }
  }

  void _initializeWebView() {
    if (kIsWeb) return;
    
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
            setState(() {
              _isLoading = false;
            });
          },
        ),
      );
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
            
            // Stream Content
            Expanded(
              child: Stack(
                children: [
                  // Cross-platform WebView or Stream Content
                  CrossPlatformWebView(
                    url: 'https://new-live-api.onrender.com/viewer.html?room=${widget.stream['id']}',
                    showLoadingIndicator: true,
                  ),
                  
                  // Loading Indicator
                  if (_isLoading)
                    Container(
                      color: Colors.black,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading stream...',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Bottom Info Panel
            _buildBottomPanel(),
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
                  widget.stream['title'] ?? 'Live Stream',
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
                  'by ${widget.stream['hostName'] ?? 'Unknown'}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontFamily: 'Poppins',
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Live Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebView() {
    if (_webViewController == null) {
      _initializeWebView();
      final joinUrl = 'https://new-live-api.onrender.com/viewer.html?room=${widget.stream['id']}';
      _webViewController?.loadRequest(Uri.parse(joinUrl));
    }
    
    return _webViewController != null
        ? WebViewWidget(controller: _webViewController!)
        : const Center(
            child: Text(
              'WebView not available',
              style: TextStyle(color: Colors.white),
            ),
          );
  }

  Widget _buildWindowsFallback() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success Icon
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 16),
            
            // Stream Title
            Text(
              widget.stream['title'] ?? 'Live Stream',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            
            // Host Name
            Text(
              'by ${widget.stream['hostName'] ?? 'Unknown'}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 24),
            
            // Join Status
            if (_isJoined && _joinData != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green),
                ),
                child: Text(
                  'Successfully joined as ${_joinData!['viewer']['name']}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Open Stream Button
            ElevatedButton.icon(
              onPressed: () async {
                await _openStreamInBrowser();
              },
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Open Live Stream'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Live Stream Ready!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Click "Open Live Stream" to watch in your browser.\nThe stream will open in a new tab.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_joinData != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Room: ${_joinData!['room']['title']}',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openStreamInBrowser() async {
    try {
      // Use the join API URL format
      final joinUrl = 'https://new-live-api.onrender.com/viewer.html?room=${widget.stream['id']}';
      
      // Launch in browser
      await launchUrl(
        Uri.parse(joinUrl),
        mode: LaunchMode.externalApplication,
      );
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening live stream in browser...'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error opening stream URL: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open stream in browser: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildWebFallback() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.play_circle_outline,
              color: Colors.white,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              widget.stream['title'] ?? 'Live Stream',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'by ${widget.stream['hostName'] ?? 'Unknown'}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // On web, we could open in same tab or show message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Stream viewing optimized for mobile app'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('View Stream'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stream Stats
          Row(
            children: [
              _buildStatItem(
                icon: Icons.visibility,
                value: '${widget.stream['viewerCount'] ?? 0}',
                label: 'Viewers',
              ),
              const SizedBox(width: 24),
              if (_analytics != null) ...[
                _buildStatItem(
                  icon: Icons.favorite,
                  value: '${_analytics!['likes'] ?? 0}',
                  label: 'Likes',
                ),
                const SizedBox(width: 24),
              ],
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Description
          if (widget.stream['description'] != null && widget.stream['description'].isNotEmpty) ...[
            const Text(
              'Description',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.stream['description'],
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Tags
          if (widget.stream['tags'] != null && (widget.stream['tags'] as List).isNotEmpty) ...[
            const Text(
              'Tags',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (widget.stream['tags'] as List).map<Widget>((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.deepPurple.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '#$tag',
                    style: const TextStyle(
                      color: Colors.deepPurple,
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          
          // Join Status and Leave Button
          if (_isJoined && _joinData != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Joined as ${_joinData!['viewer']['name']}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _leaveRoom();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.exit_to_app, size: 16),
                  label: const Text('Leave'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.7),
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontFamily: 'Poppins',
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Leave the room when the user navigates away
    if (_isJoined && _userId != null) {
      _leaveRoom();
    }
    super.dispose();
  }
}
