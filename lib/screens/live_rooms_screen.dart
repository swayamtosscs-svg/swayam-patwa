import 'package:flutter/material.dart';
import '../services/live_streaming_service.dart';
import 'live_darshan_screen.dart';

class LiveRoomsScreen extends StatefulWidget {
  final String? authToken;

  const LiveRoomsScreen({
    Key? key,
    this.authToken,
  }) : super(key: key);

  @override
  State<LiveRoomsScreen> createState() => _LiveRoomsScreenState();
}

class _LiveRoomsScreenState extends State<LiveRoomsScreen> {
  List<LiveStreamRoom> _rooms = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _serverStatus;

  @override
  void initState() {
    super.initState();
    _loadServerStatus();
    _loadRooms();
  }

  Future<void> _loadServerStatus() async {
    try {
      final status = await LiveStreamingService.getServerStatus();
      setState(() {
        _serverStatus = status;
      });
    } catch (e) {
      print('Error loading server status: $e');
    }
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // For demo purposes, we'll create some sample rooms
      // In a real implementation, you would fetch actual rooms from the server
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _rooms = [
          LiveStreamRoom(
            roomName: 'Morning Darshan',
            viewerCount: 45,
            broadcasterCount: 1,
            viewers: ['user1', 'user2', 'user3'],
            broadcasters: ['baba_ji'],
            isStreaming: true,
            streamUrl: 'wss://103.14.120.163:8443',
          ),
          LiveStreamRoom(
            roomName: 'Evening Prayer',
            viewerCount: 23,
            broadcasterCount: 1,
            viewers: ['user4', 'user5'],
            broadcasters: ['guru_ji'],
            isStreaming: true,
            streamUrl: 'wss://103.14.120.163:8443',
          ),
          LiveStreamRoom(
            roomName: 'Spiritual Discourse',
            viewerCount: 0,
            broadcasterCount: 0,
            viewers: [],
            broadcasters: [],
            isStreaming: false,
          ),
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load rooms: $e';
        _isLoading = false;
      });
    }
  }

  void _joinRoom(String roomName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveDarshanScreen(
          roomName: roomName,
          authToken: widget.authToken,
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
          'Live Darshan Rooms',
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
            onPressed: _loadRooms,
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
              'Loading live rooms...',
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
              onPressed: _loadRooms,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Server Status Card
        if (_serverStatus != null)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Server Status',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        '${_serverStatus!['status']} - Port ${_serverStatus!['port']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_serverStatus!['totalConnections']} connections',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),

        // Rooms List
        Expanded(
          child: _rooms.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.tv_off,
                        color: Colors.grey,
                        size: 64,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No live rooms available',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Check back later for live darshan sessions',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _rooms.length,
                  itemBuilder: (context, index) {
                    final room = _rooms[index];
                    return _buildRoomCard(room);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRoomCard(LiveStreamRoom room) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _joinRoom(room.roomName),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Room Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: room.isStreaming 
                            ? Colors.red.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.temple_hindu,
                        color: room.isStreaming ? Colors.red : Colors.grey,
                        size: 24,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Room Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room.roomName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.people,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${room.viewerCount} viewers',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: room.isStreaming ? Colors.red : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        room.isStreaming ? 'LIVE' : 'OFFLINE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Description
                Text(
                  room.isStreaming 
                      ? 'Join this live darshan session for spiritual guidance'
                      : 'This room is currently offline',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Join Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _joinRoom(room.roomName),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: room.isStreaming 
                          ? const Color(0xFFEF4444)
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      room.isStreaming ? 'Join Live Darshan' : 'View Room',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
