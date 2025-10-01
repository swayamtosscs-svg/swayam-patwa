import 'package:flutter/material.dart';
import 'lib/services/live_streaming_service.dart';

class TestLiveDarshanIntegration extends StatefulWidget {
  const TestLiveDarshanIntegration({Key? key}) : super(key: key);

  @override
  State<TestLiveDarshanIntegration> createState() => _TestLiveDarshanIntegrationState();
}

class _TestLiveDarshanIntegrationState extends State<TestLiveDarshanIntegration> {
  String _status = 'Ready to test';
  bool _isLoading = false;
  Map<String, dynamic>? _serverStatus;

  Future<void> _testServerConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing server connection...';
    });

    try {
      final status = await LiveStreamingService.getServerStatus();
      setState(() {
        _serverStatus = status;
        _status = 'Server Status: ${status['status']} - Port: ${status['port']}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testCreateRoom() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing room creation...';
    });

    try {
      final response = await LiveStreamingService.createRoom('test-room-${DateTime.now().millisecondsSinceEpoch}');
      setState(() {
        _status = 'Room created: ${response['roomName']}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error creating room: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Darshan Integration Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Live Darshan Server Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _status,
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testServerConnection,
              child: const Text('Test Server Connection'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testCreateRoom,
              child: const Text('Test Create Room'),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Server Information:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('URL: https://103.14.120.163:8443/'),
                    const Text('Protocol: HTTPS/WSS'),
                    const Text('Features: Live streaming, Room management, WebSocket'),
                    if (_serverStatus != null) ...[
                      const SizedBox(height: 8),
                      Text('Status: ${_serverStatus!['status']}'),
                      Text('Port: ${_serverStatus!['port']}'),
                      Text('Uptime: ${_serverStatus!['uptime'].toStringAsFixed(1)}s'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Integration Features:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('✅ WebView integration for direct server access'),
                    const Text('✅ API service for room management'),
                    const Text('✅ Server status monitoring'),
                    const Text('✅ Live streaming capabilities'),
                    const Text('✅ Cross-platform compatibility'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
