import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_response_model.dart';
import '../models/message_model.dart';
import '../models/chat_thread_model.dart';

class ChatService {
  static const String baseUrl = 'http://103.14.120.163:8081/api/chat';

  /// Get chat threads/conversations for the current user
  static Future<List<ChatThread>> getChatThreads({
    required String token,
    required String currentUserId,
  }) async {
    try {
      print('ChatService: Fetching chat threads for user: $currentUserId');
      
      // Use the getAllConversations method which uses the correct API endpoint
      return await getAllConversations(
        token: token,
        currentUserId: currentUserId,
      );
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
      
      // Try to get conversations from local storage first
      final localConversations = await _getLocalConversations(currentUserId);
      if (localConversations.isNotEmpty) {
        print('ChatService: Found ${localConversations.length} local conversations');
        
        // Try to get user information for conversations that don't have complete user data
        final updatedConversations = <ChatThread>[];
        for (final conversation in localConversations) {
          if (conversation.username == 'User' || conversation.fullName == 'User') {
            // Try to get user info from the API
            final userInfo = await _getUserInfo(conversation.userId, token);
            if (userInfo != null) {
              final updatedThread = ChatThread(
                id: conversation.id,
                userId: conversation.userId,
                username: userInfo['username'] ?? conversation.username,
                fullName: userInfo['fullName'] ?? conversation.fullName,
                avatar: userInfo['avatar'] ?? conversation.avatar,
                lastMessage: conversation.lastMessage,
                lastMessageTime: conversation.lastMessageTime,
                unreadCount: conversation.unreadCount,
              );
              updatedConversations.add(updatedThread);
              
              // Update the stored conversation with user info
              await _updateConversationUserInfo(currentUserId, conversation.userId, userInfo);
            } else {
              updatedConversations.add(conversation);
            }
          } else {
            updatedConversations.add(conversation);
          }
        }
        
        return updatedConversations;
      }
      
      // Since the message-crud endpoint is not working, return empty list
      print('ChatService: message-crud endpoint not available, returning empty conversations list');
      return [];
      
    } catch (e) {
      print('ChatService: Error getting all conversations: $e');
      return [];
    }
  }

  /// Store conversation locally
  static Future<void> _storeConversation(String userId, ChatThread thread) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'conversation_${userId}_${thread.userId}';
      final threadJson = jsonEncode({
        'id': thread.id,
        'userId': thread.userId,
        'username': thread.username,
        'fullName': thread.fullName,
        'avatar': thread.avatar,
        'lastMessage': thread.lastMessage,
        'lastMessageTime': thread.lastMessageTime.toIso8601String(),
        'unreadCount': thread.unreadCount,
      });
      await prefs.setString(key, threadJson);
      print('ChatService: Stored conversation locally: $key');
    } catch (e) {
      print('ChatService: Error storing conversation: $e');
    }
  }

  /// Get conversations from local storage
  static Future<List<ChatThread>> _getLocalConversations(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('conversation_${userId}_')).toList();
      final conversations = <ChatThread>[];
      
      for (final key in keys) {
        final threadJson = prefs.getString(key);
        if (threadJson != null) {
          final threadData = jsonDecode(threadJson);
          final thread = ChatThread(
            id: threadData['id'] ?? '',
            userId: threadData['userId'] ?? '',
            username: threadData['username'] ?? '',
            fullName: threadData['fullName'] ?? '',
            avatar: threadData['avatar'] ?? '',
            lastMessage: threadData['lastMessage'] ?? '',
            lastMessageTime: DateTime.parse(threadData['lastMessageTime']),
            unreadCount: threadData['unreadCount'] ?? 0,
          );
          conversations.add(thread);
        }
      }
      
      return conversations;
    } catch (e) {
      print('ChatService: Error getting local conversations: $e');
      return [];
    }
  }

  /// Store message conversation data
  static Future<void> _storeMessageConversation({
    required String currentUserId,
    required String otherUserId,
    required String threadId,
    required String lastMessage,
    required DateTime lastMessageTime,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'conversation_${currentUserId}_$otherUserId';
      
      // Get existing conversation data or create new
      final existingData = prefs.getString(key);
      Map<String, dynamic> conversationData;
      
      if (existingData != null) {
        conversationData = jsonDecode(existingData);
      } else {
        conversationData = {
          'id': threadId,
          'userId': otherUserId,
          'username': 'User', // We'll update this when we get user info
          'fullName': 'User',
          'avatar': '',
          'unreadCount': 0,
        };
      }
      
      // Update with latest message info
      conversationData['lastMessage'] = lastMessage;
      conversationData['lastMessageTime'] = lastMessageTime.toIso8601String();
      
      await prefs.setString(key, jsonEncode(conversationData));
      print('ChatService: Stored message conversation: $key');
    } catch (e) {
      print('ChatService: Error storing message conversation: $e');
    }
  }

  /// Get user information from API
  static Future<Map<String, dynamic>?> _getUserInfo(String userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('http://103.14.120.163:8081/api/user/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          return jsonResponse['data'];
        }
      }
      return null;
    } catch (e) {
      print('ChatService: Error getting user info: $e');
      return null;
    }
  }

  /// Update conversation with user information
  static Future<void> _updateConversationUserInfo(
    String currentUserId,
    String otherUserId,
    Map<String, dynamic> userInfo,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'conversation_${currentUserId}_$otherUserId';
      final existingData = prefs.getString(key);
      
      if (existingData != null) {
        final conversationData = jsonDecode(existingData);
        conversationData['username'] = userInfo['username'] ?? conversationData['username'];
        conversationData['fullName'] = userInfo['fullName'] ?? conversationData['fullName'];
        conversationData['avatar'] = userInfo['avatar'] ?? conversationData['avatar'];
        
        await prefs.setString(key, jsonEncode(conversationData));
        print('ChatService: Updated conversation user info: $key');
      }
    } catch (e) {
      print('ChatService: Error updating conversation user info: $e');
    }
  }

  /// Add a conversation manually (when starting a new chat)
  static Future<void> addConversation({
    required String currentUserId,
    required String otherUserId,
    required String otherUsername,
    required String otherFullName,
    required String otherAvatar,
    String? threadId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'conversation_${currentUserId}_$otherUserId';
      
      final conversationData = {
        'id': threadId ?? '',
        'userId': otherUserId,
        'username': otherUsername,
        'fullName': otherFullName,
        'avatar': otherAvatar,
        'lastMessage': '',
        'lastMessageTime': DateTime.now().toIso8601String(),
        'unreadCount': 0,
      };
      
      await prefs.setString(key, jsonEncode(conversationData));
      print('ChatService: Added manual conversation: $key');
    } catch (e) {
      print('ChatService: Error adding manual conversation: $e');
    }
  }

  /// Update conversation with thread ID
  static Future<void> _updateConversationThreadId(
    String currentUserId,
    String otherUserId,
    String threadId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'conversation_${currentUserId}_$otherUserId';
      final existingData = prefs.getString(key);
      
      if (existingData != null) {
        final conversationData = jsonDecode(existingData);
        conversationData['id'] = threadId;
        
        await prefs.setString(key, jsonEncode(conversationData));
        print('ChatService: Updated conversation thread ID: $key -> $threadId');
      }
    } catch (e) {
      print('ChatService: Error updating conversation thread ID: $e');
    }
  }

  /// Refresh conversation data to ensure thread IDs are up to date
  static Future<void> refreshConversationData(String currentUserId, String token) async {
    try {
      print('ChatService: Refreshing conversation data for user: $currentUserId');
      
      // Get all local conversations
      final conversations = await _getLocalConversations(currentUserId);
      
      // For each conversation without a thread ID, try to get messages to find the thread
      for (final conversation in conversations) {
        if (conversation.id.isEmpty) {
          print('ChatService: Conversation with ${conversation.userId} has no thread ID, skipping');
          // We can't do much here without a thread ID, but we'll log it
        }
      }
      
      print('ChatService: Conversation data refresh completed');
    } catch (e) {
      print('ChatService: Error refreshing conversation data: $e');
    }
  }

  /// Clear all conversation data (for debugging/testing)
  static Future<void> clearAllConversations(String currentUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('conversation_${currentUserId}_')).toList();
      
      for (final key in keys) {
        await prefs.remove(key);
        print('ChatService: Removed conversation: $key');
      }
      
      print('ChatService: Cleared ${keys.length} conversations');
    } catch (e) {
      print('ChatService: Error clearing conversations: $e');
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
    String? currentUserId,
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
          
          // Store conversation locally if we have thread info
          if (jsonResponse['data']?['threadId'] != null) {
            print('ChatService: Thread ID from send response: ${jsonResponse['data']['threadId']}');
            
            // Store this conversation for future reference
            if (currentUserId != null) {
              await _storeMessageConversation(
                currentUserId: currentUserId,
                otherUserId: toUserId,
                threadId: jsonResponse['data']['threadId'],
                lastMessage: content,
                lastMessageTime: DateTime.now(),
              );
              
              // Also update any existing conversation with the threadId
              await _updateConversationThreadId(
                currentUserId,
                toUserId,
                jsonResponse['data']['threadId'],
              );
            }
          }
          
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

  /// Create or get a conversation thread between two users
  static Future<String?> createOrGetThread({
    required String currentUserId,
    required String otherUserId,
    required String token,
  }) async {
    try {
      print('ChatService: Creating/getting thread between $currentUserId and $otherUserId');
      
      // Try to send a message to create the thread
      final response = await sendMessage(
        toUserId: otherUserId,
        content: 'Hello', // Initial message to create thread
        messageType: 'text',
        token: token,
        currentUserId: currentUserId,
      );
      
      print('ChatService: Thread creation response: $response');
      
      if (response['success'] == true && response['data']?['threadId'] != null) {
        print('ChatService: Thread created with ID: ${response['data']['threadId']}');
        return response['data']['threadId'];
      }
      
      print('ChatService: Failed to create thread - response: $response');
      return null;
    } catch (e) {
      print('ChatService: Error creating thread: $e');
      return null;
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




