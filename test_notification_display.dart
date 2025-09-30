import 'package:flutter/material.dart';
import 'lib/models/notification_model.dart';
import 'lib/widgets/notification_item_widget.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notification Display Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NotificationTestScreen(),
    );
  }
}

class NotificationTestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Create test notifications with different data structures
    final testNotifications = [
      // Test 1: Notification with follower info in data field
      NotificationModel(
        id: '1',
        type: 'follow',
        title: 'New Follower',
        message: 'John Doe started following you',
        isRead: false,
        createdAt: DateTime.now().subtract(Duration(days: 1)),
        data: {
          'followerId': 'user123',
          'followerName': 'John Doe',
          'followerProfileImage': 'https://via.placeholder.com/150',
          'action': 'follow',
        },
      ),
      
      // Test 2: Notification with follower info in main JSON (simulated)
      NotificationModel(
        id: '2',
        type: 'follow',
        title: 'New Follower',
        message: 'Jane Smith started following you',
        isRead: false,
        createdAt: DateTime.now().subtract(Duration(days: 3)),
        data: {
          'followerId': 'user456',
          'followerName': 'Jane Smith',
          'action': 'follow',
        },
      ),
      
      // Test 3: Notification with minimal data (like current API response)
      NotificationModel(
        id: '3',
        type: 'follow',
        title: 'New Follower',
        message: 'Someone started following you',
        isRead: false,
        createdAt: DateTime.now().subtract(Duration(days: 6)),
        data: null,
      ),
      
      // Test 4: Notification with follower name extracted from message
      NotificationModel(
        id: '4',
        type: 'follow',
        title: 'New Follower',
        message: 'Mike Johnson started following you',
        isRead: false,
        createdAt: DateTime.now().subtract(Duration(days: 2)),
        data: null,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF0EBE1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0EBE1),
        elevation: 0,
        title: const Text(
          'Notification Display Test',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: testNotifications.length,
        itemBuilder: (context, index) {
          final notification = testNotifications[index];
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Test ${index + 1}: ${notification.message}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              NotificationItemWidget(
                notification: notification,
                onTap: () {
                  print('Tapped notification: ${notification.id}');
                  print('Follower name: ${notification.followerName}');
                  print('Formatted message: ${notification.formattedMessage}');
                },
              ),
              SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}
