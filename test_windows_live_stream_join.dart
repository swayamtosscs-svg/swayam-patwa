import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'lib/services/live_stream_service.dart';

void main() {
  runApp(const WindowsLiveStreamTestApp());
}

class WindowsLiveStreamTestApp extends StatelessWidget {
  const WindowsLiveStreamTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Windows Live Stream Test',
      theme: ThemeData(
        primarySwatch: Colors.red,
        fontFamily: 'Poppins',
      ),
      home: const WindowsLiveStreamTestScreen(),
    );
  }
}

class WindowsLiveStreamTestScreen extends StatefulWidget {
  const WindowsLiveStreamTestScreen({super.key});

  @override
  State<WindowsLiveStreamTestScreen> createState() => _WindowsLiveStreamTestScreenState();
}

class _WindowsLiveStreamTestScreenState extends State<WindowsLiveStreamTestScreen> {
  bool _isLoading = false;
  bool _isJoined = false;
  Map<String, dynamic>? _joinData;
  String _statusMessage = 'Ready to test live stream join';

  // Test room ID from the user's example
  final String testRoomId = '2753bc0d-3380-44ab-9914-425ffca79aef';
  final String testUserName = 'Windows Viewer';

  Future<void> _testJoinRoom() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Joining room...';
    });

    try {
      print('Testing join room API...');
      final result = await LiveStreamService.joinRoom(
        roomId: testRoomId,
        userName: testUserName,
      );

      if (result['success'] == true) {
        setState(() {
          _isJoined = true;
          _joinData = result['data'];
          _statusMessage = 'Successfully joined room!';
        });
        print('Join successful: ${result['data']}');
      } else {
        setState(() {
          _statusMessage = 'Failed to join: ${result['message']}';
        });
        print('Join failed: ${result['message']}');
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
      print('Join error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openStreamInBrowser() async {
    try {
      final joinUrl = 'https://new-live-api.onrender.com/viewer.html?room=$testRoomId';
      await launchUrl(
        Uri.parse(joinUrl),
        mode: LaunchMode.externalApplication,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening live stream in browser...'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening browser: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Windows Live Stream Test',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test Room Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Test Room Information',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Room ID: $testRoomId',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    'User Name: $testUserName',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Status Message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isJoined ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isJoined ? Colors.green : Colors.blue,
                ),
              ),
              child: Text(
                _statusMessage,
                style: TextStyle(
                  color: _isJoined ? Colors.green : Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Join Data Display
            if (_joinData != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Join Response Data',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Viewer ID: ${_joinData!['viewer']['id']}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      'Viewer Name: ${_joinData!['viewer']['name']}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      'Room Title: ${_joinData!['room']['title']}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      'Host Name: ${_joinData!['room']['hostName']}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      'Viewer Count: ${_joinData!['room']['viewerCount']}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      'Is Live: ${_joinData!['room']['isLive']}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Action Buttons
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testJoinRoom,
              icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.login),
              label: Text(_isLoading ? 'Joining...' : 'Test Join Room'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _openStreamInBrowser,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Open Stream in Browser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            
            const Spacer(),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: const Column(
                children: [
                  Text(
                    'Test Instructions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Click "Test Join Room" to test the join API\n'
                    '2. If successful, click "Open Stream in Browser"\n'
                    '3. The live stream should open in your default browser\n'
                    '4. Check the console for detailed API responses',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
