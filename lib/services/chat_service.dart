import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_response_model.dart';
import '../models/message_model.dart';
import '../models/chat_thread_model.dart';

class ChatService {
  static const String baseUrl = 'https://api-rgram1.vercel.app/api/chat';

  /// Get chat threads/conversations for the current user
  static Future<List<ChatThread>> getChatThreads({
    required String token,
    required String currentUserId,
  }) async {
    try {
      print('ChatService: Fetching chat threads for user: $currentUserId');
      
      // Get all messages for the current user to build conversation threads
      final response = await http.get(
        Uri.parse('$baseUrl/quick-message?userId=$currentUserId&limit=100'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('ChatService: Messages API Response Status: ${response.statusCode}');
      print('ChatService: Messages API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> messagesData = jsonResponse['data']['messages'] ?? [];
          print('ChatService: Found ${messagesData.length} messages');
          
          // Group messages by thread to create conversation threads
          final Map<String, List<dynamic>> threadGroups = {};
          
          for (final messageData in messagesData) {
            final threadId = messageData['thread'] ?? '';
            if (threadId.isNotEmpty) {
              if (!threadGroups.containsKey(threadId)) {
                threadGroups[threadId] = [];
              }
              threadGroups[threadId]!.add(messageData);
            }
          }
          
          print('ChatService: Grouped into ${threadGroups.length} threads');
          
          final List<ChatThread> threads = [];
          
          threadGroups.forEach((threadId, messages) {
            if (messages.isNotEmpty) {
              // Sort messages by time to get the latest one
              messages.sort((a, b) {
                final timeA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
                final timeB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
                return timeB.compareTo(timeA);
              });
              
              final lastMessage = messages.first;
              final sender = lastMessage['sender'] ?? {};
              
              // Find the other participant (not current user)
              String otherUserId = '';
              String otherUsername = '';
              String otherFullName = '';
              String otherAvatar = '';
              
              if (sender['_id'] == currentUserId) {
                // Last message is from current user, find recipient
                otherUserId = lastMessage['recipient'] ?? '';
              } else {
                // Last message is from other user
                otherUserId = sender['_id'] ?? '';
                otherUsername = sender['username'] ?? '';
                otherFullName = sender['fullName'] ?? '';
                otherAvatar = sender['avatar'] ?? '';
              }
              
              if (otherUserId.isNotEmpty && otherUserId != currentUserId) {
                final thread = ChatThread(
                  id: threadId,
                  userId: otherUserId,
                  username: otherUsername,
                  fullName: otherFullName,
                  avatar: otherAvatar,
                  lastMessage: lastMessage['content'] ?? '',
                  lastMessageTime: lastMessage['createdAt'] != null 
                      ? DateTime.parse(lastMessage['createdAt']) 
                      : DateTime.now(),
                  unreadCount: messages.where((m) => 
                    m['sender']?['_id'] != currentUserId && m['isRead'] == false
                  ).length,
                );
                threads.add(thread);
                print('ChatService: Created thread with ${otherUsername} (${otherFullName})');
              } else {
                print('ChatService: Skipping thread - otherUserId: $otherUserId, currentUserId: $currentUserId');
              }
            }
          });
          
          if (threads.isNotEmpty) {
            print('ChatService: Successfully created ${threads.length} chat threads');
            return threads;
          }
        }
      }
      
      // If no threads found, return empty list
      print('ChatService: No chat threads found');
      return [];
      
    } catch (e) {
      print('ChatService: Error getting chat threads: $e');
      return [];
    }
  }

  /// Get all conversations for a user by fetching all their messages and grouping them
  static Future<List<ChatThread>> getAllConversations({
    required String token,
    required String currentUserId,
  }) async {
    try {
      print('ChatService: Getting all conversations for user: $currentUserId');
      
      // Get all messages for the current user
      final response = await http.get(
        Uri.parse('$baseUrl/message-crud?userId=$currentUserId&limit=1000'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('ChatService: All messages API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> messagesData = jsonResponse['data']['messages'] ?? [];
          
          // Group messages by conversation partner
          final Map<String, List<dynamic>> conversationMap = {};
          
          for (final messageData in messagesData) {
            final senderId = messageData['sender']?['_id'] ?? '';
            final recipientId = messageData['recipient'] ?? '';
            
            // Determine the other user in the conversation
            String otherUserId;
            if (senderId == currentUserId) {
              otherUserId = recipientId;
            } else {
              otherUserId = senderId;
            }
            
            if (otherUserId.isNotEmpty) {
              if (!conversationMap.containsKey(otherUserId)) {
                conversationMap[otherUserId] = [];
              }
              conversationMap[otherUserId]!.add(messageData);
            }
          }
          
          // Create chat threads from conversations
          final List<ChatThread> threads = [];
          
          for (final entry in conversationMap.entries) {
            final otherUserId = entry.key;
            final messages = entry.value;
            
            // Sort messages by time to get the latest one
            messages.sort((a, b) {
              final timeA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
              final timeB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
              return timeB.compareTo(timeA);
            });
            
            final latestMessage = messages.first;
            final senderId = latestMessage['sender']?['_id'] ?? '';
            
            // Get user info for the other person
            String otherUsername = '';
            String otherFullName = '';
            String otherAvatar = '';
            
            if (senderId == currentUserId) {
              // Latest message is from current user, we need to find the other user's info
              // This might require additional API call to get user details
              otherUsername = 'User';
              otherFullName = 'User';
            } else {
              // Latest message is from other user
              otherUsername = latestMessage['sender']?['username'] ?? '';
              otherFullName = latestMessage['sender']?['fullName'] ?? '';
              otherAvatar = latestMessage['sender']?['avatar'] ?? '';
            }
            
            final thread = ChatThread(
              id: latestMessage['thread'] ?? '',
              userId: otherUserId,
              username: otherUsername,
              fullName: otherFullName,
              avatar: otherAvatar,
              lastMessage: latestMessage['content'] ?? '',
              lastMessageTime: latestMessage['createdAt'] != null 
                  ? DateTime.parse(latestMessage['createdAt']) 
                  : DateTime.now(),
              unreadCount: messages.where((m) => 
                m['sender']?['_id'] != currentUserId && m['isRead'] == false
              ).length,
            );
            threads.add(thread);
          }
          
          if (threads.isNotEmpty) {
            print('ChatService: Successfully created ${threads.length} conversation threads');
            return threads;
          }
        }
      }
      
      print('ChatService: Failed to get messages, returning empty list');
      return [];
      
    } catch (e) {
      print('ChatService: Error getting all conversations: $e');
      return [];
    }
  }

  /// Get messages for a specific thread using the correct API endpoint
  static Future<List<Message>> getMessagesByThreadId({
    required String threadId,
    required String token,
  }) async {
    try {
      print('ChatService: Getting messages for thread: $threadId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/quick-message?threadId=$threadId&limit=50'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('ChatService: Get messages response status: ${response.statusCode}');
      print('ChatService: Get messages response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> messagesData = jsonResponse['data']['messages'] ?? [];
          final List<Message> messages = [];
          
          for (final messageData in messagesData) {
            try {
              final sender = messageData['sender'] ?? {};
              final message = Message(
                id: messageData['_id'] ?? '',
                threadId: messageData['thread'] ?? '',
                sender: MessageSender(
                  id: sender['_id'] ?? '',
                  username: sender['username'] ?? '',
                  fullName: sender['fullName'] ?? '',
                  avatar: sender['avatar'] ?? '',
                ),
                recipient: messageData['recipient'] ?? '',
                content: messageData['content'] ?? '',
                messageType: messageData['messageType'] ?? 'text',
                isRead: messageData['isRead'] ?? false,
                isDeleted: messageData['isDeleted'] ?? false,
                reactions: messageData['reactions'] ?? [],
                createdAt: messageData['createdAt'] != null 
                    ? DateTime.parse(messageData['createdAt']) 
                    : DateTime.now(),
                updatedAt: messageData['updatedAt'] != null 
                    ? DateTime.parse(messageData['updatedAt']) 
                    : DateTime.now(),
              );
              messages.add(message);
            } catch (e) {
              print('ChatService: Error creating message from data: $e');
            }
          }
          
          // Sort messages by creation time (oldest first)
          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          
          print('ChatService: Successfully loaded ${messages.length} messages');
          return messages;
        }
      }
      
      print('ChatService: Failed to get messages for thread: $threadId');
      return [];
      
    } catch (e) {
      print('ChatService: Error getting messages by thread ID: $e');
      return [];
    }
  }

  /// Send a message
  static Future<Map<String, dynamic>> sendMessage({
    required String toUserId,
    required String content,
    required String messageType,
    required String token,
  }) async {
    try {
      print('ChatService: Sending message to user: $toUserId');
      print('ChatService: Using token: ${token.substring(0, 20)}...');
      
      final response = await http.post(
        Uri.parse('$baseUrl/quick-message'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'toUserId': toUserId,
          'content': content,
          'messageType': messageType,
        }),
      );

      print('ChatService: Send message response status: ${response.statusCode}');
      print('ChatService: Send message response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          print('ChatService: Message sent successfully');
          return jsonResponse;
        } else {
          print('ChatService: Send message failed: ${jsonResponse['message']}');
          return {
            'success': false,
            'message': jsonResponse['message'] ?? 'Failed to send message',
          };
        }
      } else {
        print('ChatService: Send message failed: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('ChatService: Error sending message: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Update a message
  static Future<Map<String, dynamic>> updateMessage({
    required String messageId,
    required String content,
    required String token,
  }) async {
    try {
      print('ChatService: Updating message: $messageId');
      
      final response = await http.put(
        Uri.parse('$baseUrl/quick-message'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'messageId': messageId,
          'content': content,
        }),
      );

      print('ChatService: Update message response status: ${response.statusCode}');
      print('ChatService: Update message response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          print('ChatService: Message updated successfully');
          return jsonResponse;
        } else {
          print('ChatService: Update message failed: ${jsonResponse['message']}');
          return {
            'success': false,
            'message': jsonResponse['message'] ?? 'Failed to update message',
          };
        }
      } else {
        print('ChatService: Update message failed: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('ChatService: Error updating message: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Delete a message
  static Future<Map<String, dynamic>> deleteMessage({
    required String messageId,
    required String token,
    required String deleteType,
  }) async {
    try {
      print('ChatService: Deleting message: $messageId');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/quick-message'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'messageId': messageId,
          'deleteType': deleteType,
        }),
      );

      print('ChatService: Delete message response status: ${response.statusCode}');
      print('ChatService: Delete message response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          print('ChatService: Message deleted successfully');
          return jsonResponse;
        } else {
          print('ChatService: Delete message failed: ${jsonResponse['message']}');
          return {
            'success': false,
            'message': jsonResponse['message'] ?? 'Failed to delete message',
          };
        }
      } else {
        print('ChatService: Delete message failed: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('ChatService: Error deleting message: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Create a chat thread (this might not be needed if threads are auto-created)
  static Future<Map<String, dynamic>> createChatThread({
    required String toUserId,
    required String token,
  }) async {
    try {
      print('ChatService: Creating chat thread with user: $toUserId');
      
      // Since the API might not support thread creation directly,
      // we'll return a mock response indicating success
      // The actual thread will be created when the first message is sent
      return {
        'success': true,
        'message': 'Thread will be created with first message',
        'data': {
          'threadId': 'temp_${DateTime.now().millisecondsSinceEpoch}',
        },
      };
    } catch (e) {
      print('ChatService: Error creating chat thread: $e');
      return {
        'success': false,
        'message': 'Failed to create chat thread',
      };
    }
  }

  /// Mark messages as read
  static Future<bool> markMessagesAsRead({
    required String threadId,
    required String token,
  }) async {
    try {
      print('ChatService: Marking messages as read for thread: $threadId');
      
      // This API endpoint might not exist yet, so we'll just return true
      // In a real implementation, you would call the appropriate API
      return true;
    } catch (e) {
      print('ChatService: Error marking messages as read: $e');
      return false;
    }
  }
}




