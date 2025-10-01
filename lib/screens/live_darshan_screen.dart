import 'package:flutter/material.dart';
import '../services/live_streaming_service.dart';

class LiveDarshanScreen extends StatefulWidget {
  final String roomName;
  final String? authToken;

  const LiveDarshanScreen({
    Key? key,
    required this.roomName,
    this.authToken,
  }) : super(key: key);

  @override
  State<LiveDarshanScreen> createState() => _LiveDarshanScreenState();
}

class _LiveDarshanScreenState extends State<LiveDarshanScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _roomInfo;

  @override
  void initState() {
    super.initState();
    _loadRoomInfo();
  }

  Future<void> _loadRoomInfo() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final roomInfo = await LiveStreamingService.getRoomInfo(widget.roomName);
      setState(() {
        _roomInfo = roomInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load room info: $e';
        _isLoading = false;
      });
    }
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
        title: Text(
          'Live Darshan - ${widget.roomName}',
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
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
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Loading room information...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      );
    }

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
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadRoomInfo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.temple_hindu,
            color: Colors.orange,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Room: ${widget.roomName}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (_roomInfo != null) ...[
            Text(
              'Viewers: ${_roomInfo!['viewerCount'] ?? 0}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              'Broadcasters: ${_roomInfo!['broadcasterCount'] ?? 0}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Live Darshan functionality will be available here',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}