import 'package:flutter/material.dart';
import 'lib/widgets/cross_platform_webview.dart';

void main() {
  runApp(const InAppLiveStreamTestApp());
}

class InAppLiveStreamTestApp extends StatelessWidget {
  const InAppLiveStreamTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'In-App Live Stream Test',
      theme: ThemeData(
        primarySwatch: Colors.red,
        fontFamily: 'Poppins',
      ),
      home: const InAppLiveStreamTestScreen(),
    );
  }
}

class InAppLiveStreamTestScreen extends StatefulWidget {
  const InAppLiveStreamTestScreen({super.key});

  @override
  State<InAppLiveStreamTestScreen> createState() => _InAppLiveStreamTestScreenState();
}

class _InAppLiveStreamTestScreenState extends State<InAppLiveStreamTestScreen> {
  // Test room ID from the user's example
  final String testRoomId = '2753bc0d-3380-44ab-9914-425ffca79aef';
  final String streamUrl = 'https://new-live-api.onrender.com/viewer.html?room=2753bc0d-3380-44ab-9914-425ffca79aef';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'In-App Live Stream Test',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey.withOpacity(0.1),
            child: Column(
              children: [
                const Text(
                  'Testing In-App Live Streaming',
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
                  'Stream URL: $streamUrl',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          
          // Live Stream WebView
          Expanded(
            child: CrossPlatformWebView(
              url: streamUrl,
              showLoadingIndicator: true,
            ),
          ),
          
          // Instructions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey.withOpacity(0.1),
            child: const Column(
              children: [
                Text(
                  'Instructions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'The live stream should now play directly inside the app.\n'
                  'If you see an error, try the "Retry" button.\n'
                  'If WebView fails, use "Open in Browser" as fallback.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
