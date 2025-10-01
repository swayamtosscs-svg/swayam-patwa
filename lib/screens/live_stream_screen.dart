import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/live_streaming_service.dart';
import 'live_darshan_webview_screen.dart';
import 'live_rooms_screen.dart';
import 'live_streaming_setup_screen.dart';
import '../utils/app_theme.dart';

class LiveStreamScreen extends StatefulWidget {
  const LiveStreamScreen({super.key});

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _serverStatus;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkServerStatus();
  }

  Future<void> _checkServerStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Initialize SSL bypass for live streaming server
      await LiveStreamingService.initialize();
      
      final status = await LiveStreamingService.getServerStatus();
      setState(() {
        _serverStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to connect to live streaming server: $e';
        _isLoading = false;
      });
    }
  }

  void _openLiveDarshanWebView() {
    // Direct redirect to live streaming server
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LiveDarshanWebViewScreen(),
      ),
    );
  }

  void _navigateToLiveRooms() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveRoomsScreen(
          authToken: authProvider.authToken,
        ),
      ),
    );
  }

  void _navigateToStreamingSetup() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveStreamingSetupScreen(
          authToken: authProvider.authToken,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Live Darshan',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1A1A1A)),
            onPressed: _checkServerStatus,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF6366F1)),
            SizedBox(height: 16),
            Text(
              'Checking server status...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                  fontSize: 16,
                  color: Colors.red,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _checkServerStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Live Darshan',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Connect with spiritual leaders through live streaming',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 32),

          // Server Status Card
          if (_serverStatus != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Server Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Status: ${_serverStatus!['status']}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    'Port: ${_serverStatus!['port']} | Protocol: ${_serverStatus!['protocol']}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    'Uptime: ${_serverStatus!['uptime'].toStringAsFixed(1)}s',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32),

          // Main Options
          _buildOptionCard(
            icon: Icons.live_tv,
            title: 'Open Live Darshan',
            subtitle: 'Direct access to live streaming server',
            color: const Color(0xFFEF4444),
            onTap: _openLiveDarshanWebView,
            isPrimary: true,
          ),

          const SizedBox(height: 16),

          _buildOptionCard(
            icon: Icons.people,
            title: 'Browse Rooms',
            subtitle: 'View available live darshan rooms',
            color: const Color(0xFF6366F1),
            onTap: _navigateToLiveRooms,
          ),

          const SizedBox(height: 16),

          _buildOptionCard(
            icon: Icons.videocam,
            title: 'Start Streaming',
            subtitle: 'Begin streaming your spiritual teachings',
            color: const Color(0xFF10B981),
            onTap: _navigateToStreamingSetup,
          ),

          const SizedBox(height: 32),

          // Features Info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Live Darshan Features',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '• Direct access to live streaming server\n'
                  '• Real-time spiritual teachings and guidance\n'
                  '• Interactive chat with spiritual leaders\n'
                  '• Multiple rooms for different sessions\n'
                  '• High-quality video streaming\n'
                  '• Cross-platform compatibility',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    fontFamily: 'Poppins',
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Server Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Server Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'URL: https://103.14.120.163:8443/',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    fontFamily: 'Poppins',
                  ),
                ),
                const Text(
                  'Protocol: HTTPS/WSS',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    fontFamily: 'Poppins',
                  ),
                ),
                const Text(
                  'Status: Live streaming server',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: isPrimary ? Border.all(color: color.withOpacity(0.3), width: 2) : null,
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            
            const SizedBox(width: 20),
            
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow icon
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}