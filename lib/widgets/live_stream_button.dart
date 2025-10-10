import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/live_stream_provider.dart';
import '../providers/auth_provider.dart';
import '../models/live_stream_model.dart';
import '../utils/app_theme.dart';

class LiveStreamButton extends StatelessWidget {
  const LiveStreamButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<LiveStreamProvider, AuthProvider>(
      builder: (context, liveProvider, authProvider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // Create Live Stream Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToCreateLiveStream(context),
                  icon: const Icon(
                    Icons.videocam,
                    color: Colors.white,
                    size: 24,
                  ),
                  label: const Text(
                    'Go Live',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Active Live Rooms Section
              if (liveProvider.activeRooms.isNotEmpty) ...[
                const Text(
                  'Live Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: liveProvider.activeRooms.length,
                    itemBuilder: (context, index) {
                      final room = liveProvider.activeRooms[index];
                      return _buildLiveRoomCard(context, room);
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveRoomCard(BuildContext context, LiveRoom room) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToLiveStreamViewer(context, room),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Room Title
              Text(
                room.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 4),
              
              // Host Name
              Text(
                'by ${room.hostName}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontFamily: 'Poppins',
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              const Spacer(),
              
              // Live Indicator and Stats
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  Row(
                    children: [
                      Icon(
                        Icons.visibility,
                        color: Colors.white.withOpacity(0.7),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        room.formattedViews,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontFamily: 'Poppins',
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCreateLiveStream(BuildContext context) {
    Navigator.of(context).pushNamed('/create-live-stream').then((result) {
      if (result != null && result is Map<String, dynamic>) {
        // Room created successfully, show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Live room created! Room ID: ${result['roomId']}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        
        // Optionally navigate to the live stream viewer
        if (result['room'] != null) {
          _navigateToLiveStreamViewer(context, result['room']);
        }
      }
    });
  }

  void _navigateToLiveStreamViewer(BuildContext context, LiveRoom room) {
    Navigator.of(context).pushNamed(
      '/live-stream-viewer',
      arguments: {
        'room': room,
        'authToken': Provider.of<AuthProvider>(context, listen: false).authToken,
      },
    );
  }
}
