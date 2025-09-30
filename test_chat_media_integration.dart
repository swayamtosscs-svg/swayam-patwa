import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'lib/services/chat_service.dart';

/// Test file for chat media integration
/// This file demonstrates how to use the new media sending functionality
class ChatMediaIntegrationTest {
  
  /// Test sending an image message
  static Future<void> testSendImage() async {
    print('Testing image sending...');
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        final File file = File(image.path);
        
        final response = await ChatService.sendMediaMessage(
          file: file,
          toUserId: '68ad57cdceb840899bef3405', // Test user ID
          content: 'Test image message',
          messageType: 'image',
          token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2OGRiOWY4MTk3NTgwZDJhN2ZiMzk2MWUiLCJpYXQiOjE3NTkyMjM2ODEsImV4cCI6MTc2MTgxNTY4MX0.u6MbYB-Bc9wZcJVv1zqTIf4reyyYoZyOuoAR_GYmucI',
          currentUserId: '68db9f8197580d2a7fb3961e',
        );

        if (response['success'] == true) {
          print('✅ Image sent successfully!');
          print('Thread ID: ${response['data']?['threadId']}');
          print('Message ID: ${response['data']?['message']?['_id']}');
        } else {
          print('❌ Failed to send image: ${response['message']}');
        }
      } else {
        print('❌ No image selected');
      }
    } catch (e) {
      print('❌ Error testing image send: $e');
    }
  }

  /// Test sending a video message
  static Future<void> testSendVideo() async {
    print('Testing video sending...');
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null) {
        final File file = File(video.path);
        
        final response = await ChatService.sendMediaMessage(
          file: file,
          toUserId: '68ad57cdceb840899bef3405', // Test user ID
          content: 'Test video message',
          messageType: 'video',
          token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2OGRiOWY4MTk3NTgwZDJhN2ZiMzk2MWUiLCJpYXQiOjE3NTkyMjM2ODEsImV4cCI6MTc2MTgxNTY4MX0.u6MbYB-Bc9wZcJVv1zqTIf4reyyYoZyOuoAR_GYmucI',
          currentUserId: '68db9f8197580d2a7fb3961e',
        );

        if (response['success'] == true) {
          print('✅ Video sent successfully!');
          print('Thread ID: ${response['data']?['threadId']}');
          print('Message ID: ${response['data']?['message']?['_id']}');
          print('Media URL: ${response['data']?['message']?['mediaUrl']}');
        } else {
          print('❌ Failed to send video: ${response['message']}');
        }
      } else {
        print('❌ No video selected');
      }
    } catch (e) {
      print('❌ Error testing video send: $e');
    }
  }

  /// Test retrieving messages with media
  static Future<void> testRetrieveMessages() async {
    print('Testing message retrieval...');
    
    try {
      final messages = await ChatService.getMessagesByThreadId(
        threadId: '68dba01f97580d2a7fb39678', // Test thread ID
        token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2OGRiOWY4MTk3NTgwZDJhN2ZiMzk2MWUiLCJpYXQiOjE3NTkyMjM2ODEsImV4cCI6MTc2MTgxNTY4MX0.u6MbYB-Bc9wZcJVv1zqTIf4reyyYoZyOuoAR_GYmucI',
      );

      print('✅ Retrieved ${messages.length} messages');
      
      for (final message in messages) {
        print('Message: ${message.content}');
        print('Type: ${message.messageType}');
        if (message.mediaUrl != null) {
          print('Media URL: ${message.mediaUrl}');
        }
        if (message.mediaInfo != null) {
          print('Media Info: ${message.mediaInfo}');
        }
        print('---');
      }
    } catch (e) {
      print('❌ Error testing message retrieval: $e');
    }
  }

  /// Run all tests
  static Future<void> runAllTests() async {
    print('🚀 Starting Chat Media Integration Tests...\n');
    
    await testRetrieveMessages();
    print('');
    
    // Uncomment these to test sending (requires user interaction)
    // await testSendImage();
    // print('');
    // await testSendVideo();
    
    print('✅ All tests completed!');
  }
}

/// Example usage in a Flutter app
class ChatMediaTestWidget extends StatelessWidget {
  const ChatMediaTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Media Integration Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => ChatMediaIntegrationTest.testRetrieveMessages(),
              child: const Text('Test Message Retrieval'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ChatMediaIntegrationTest.testSendImage(),
              child: const Text('Test Send Image'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ChatMediaIntegrationTest.testSendVideo(),
              child: const Text('Test Send Video'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ChatMediaIntegrationTest.runAllTests(),
              child: const Text('Run All Tests'),
            ),
          ],
        ),
      ),
    );
  }
}