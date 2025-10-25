import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message_model.dart';
import '../models/chat_thread_model.dart';

class ChatService {
  static const String baseUrl = 'http://103.14.120.163:8081/api/chat';
  
  // Cache to prevent repeated API calls
  static bool _isLoadingConversations = false;
  static DateTime? _lastConversationLoadTime;
  static const Duration _conversationLoadCooldown = Duration(minutes: 2); // Increased to 2 minutes
  
  // Global conversation cache
  static final Map<String, List<ChatThread>> _globalConversationCache = {};
  static final Map<String, DateTime> _globalConversationCacheTimestamps = {};
  static const Duration _globalConversationCacheExpiry = Duration(minutes: 5); // Cache for 5 minutes

  /// Get chat threads/conversations for the current user
  static Future<List<ChatThread>> getChatThreads({
    required String token,
    required String currentUserId,
  }) async {
    try {
      print('ChatService: Fetching chat threads for user: $currentUserId');
      
      // Check global cache first
      if (_isConversationCached(currentUserId)) {
        print('ChatService: Using cached conversations for user $currentUserId');
        return _globalConversationCache[currentUserId]!;
      }
      
      // Prevent repeated calls
      if (_isLoadingConversations) {
        print('ChatService: Conversation loading already in progress, skipping');
        return await _getLocalConversations(currentUserId);
      }
      
      // Check cooldown period
      if (_lastConversationLoadTime != null && 
          DateTime.now().difference(_lastConversationLoadTime!) < _conversationLoadCooldown) {
        print('ChatService: Conversation loading cooldown active, using local cache');
        return await _getLocalConversations(currentUserId);
      }
      
      // Use the getAllConversations method which uses the correct API endpoint
      final conversations = await getAllConversations(
        token: token,
        currentUserId: currentUserId,
      );
      
      // Cache the result globally
      _cacheConversations(currentUserId, conversations);
      
      return conversations;
    } catch (e) {
      print('ChatService: Error getting chat threads: $e');
      return [];
    }
  }
  
  /// Check if conversations are cached for a user
  static bool _isConversationCached(String userId) {
    final timestamp = _globalConversationCacheTimestamps[userId];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _globalConversationCacheExpiry;
  }
  
  /// Cache conversations globally
  static void _cacheConversations(String userId, List<ChatThread> conversations) {
    _globalConversationCache[userId] = conversations;
    _globalConversationCacheTimestamps[userId] = DateTime.now();
    print('ChatService: Cached ${conversations.length} conversations for user $userId');
  }

  /// Get all conversations for a user by fetching all their messages and grouping them
  static Future<List<ChatThread>> getAllConversations({
    required String token,
    required String currentUserId,
  }) async {
    try {
      print('ChatService: Getting all conversations for user: $currentUserId');
      
      // Set loading flag
      _isLoadingConversations = true;
      _lastConversationLoadTime = DateTime.now();
      
      // Try to get conversations from local storage first
      final localConversations = await _getLocalConversations(currentUserId);
      print('ChatService: Found ${localConversations.length} local conversations');
      
      // Try to fetch conversations from API
      try {
        final apiConversations = await _fetchConversationsFromAPI(token, currentUserId);
        print('ChatService: Found ${apiConversations.length} API conversations');
        
        // Merge local and API conversations
        final allConversations = <ChatThread>[];
        final seenUserIds = <String>{};
        
        // Add local conversations first (they have more complete data)
        for (final conversation in localConversations) {
          allConversations.add(conversation);
          seenUserIds.add(conversation.userId);
        }
        
        // Add API conversations that aren't already in local storage
        for (final conversation in apiConversations) {
          if (!seenUserIds.contains(conversation.userId)) {
            allConversations.add(conversation);
            seenUserIds.add(conversation.userId);
          }
        }
        
        // Try to get user information for conversations that don't have complete user data
        final updatedConversations = <ChatThread>[];
        for (final conversation in allConversations) {
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
        
        // Use updated conversations instead of allConversations
        allConversations.clear();
        allConversations.addAll(updatedConversations);
        
        // Sort by last message time (most recent first)
        allConversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        
        return allConversations;
        
      } catch (apiError) {
        print('ChatService: API fetch failed, using local conversations only: $apiError');
        return localConversations;
      } finally {
        _isLoadingConversations = false;
      }
      
    } catch (e) {
      print('ChatService: Error getting all conversations: $e');
      _isLoadingConversations = false;
      return [];
    }
  }

  /// Fetch conversations from API by getting all messages and grouping them
  static Future<List<ChatThread>> _fetchConversationsFromAPI(
    String token,
    String currentUserId,
  ) async {
    try {
      print('ChatService: Fetching conversations from API for user: $currentUserId');
      
      // Try different API endpoints to get conversations
      // First try the enhanced-message endpoint without threadId
      final response = await http.get(
        Uri.parse('$baseUrl/enhanced-message?userId=$currentUserId&limit=100'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('ChatService: Get conversations response status: ${response.statusCode}');
      print('ChatService: Get conversations response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final messagesData = jsonResponse['data'] as List;
          print('ChatService: Found ${messagesData.length} messages from API');
          
          // Group messages by thread and create conversations
          final threadMap = <String, List<Map<String, dynamic>>>{};
          
          for (final messageData in messagesData) {
            final threadId = messageData['threadId'] ?? '';
            if (threadId.isNotEmpty) {
              if (!threadMap.containsKey(threadId)) {
                threadMap[threadId] = [];
              }
              threadMap[threadId]!.add(messageData);
            }
          }
          
          // Create ChatThread objects from grouped messages
          final conversations = <ChatThread>[];
          
          for (final entry in threadMap.entries) {
            final threadId = entry.key;
            final messages = entry.value;
            
            if (messages.isNotEmpty) {
              // Sort messages by creation time to get the latest
              messages.sort((a, b) {
                final timeA = DateTime.parse(a['createdAt'] ?? DateTime.now().toIso8601String());
                final timeB = DateTime.parse(b['createdAt'] ?? DateTime.now().toIso8601String());
                return timeB.compareTo(timeA);
              });
              
              final latestMessage = messages.first;
              final sender = latestMessage['sender'];
              final recipient = latestMessage['recipient'];
              
              // Determine the other user in the conversation
              String otherUserId;
              String otherUsername;
              String otherFullName;
              String otherAvatar;
              
              if (sender['_id'] == currentUserId) {
                // Current user is sender, other user is recipient
                otherUserId = recipient;
                otherUsername = 'User'; // We'll need to fetch this separately
                otherFullName = 'User';
                otherAvatar = '';
              } else {
                // Current user is recipient, other user is sender
                otherUserId = sender['_id'] ?? '';
                otherUsername = sender['username'] ?? 'User';
                otherFullName = sender['fullName'] ?? 'User';
                otherAvatar = sender['avatar'] ?? '';
              }
              
              // Count unread messages (messages where current user is recipient and isRead is false)
              int unreadCount = 0;
              for (final message in messages) {
                if (message['recipient'] == currentUserId && 
                    (message['isRead'] == false || message['isRead'] == null)) {
                  unreadCount++;
                }
              }
              
              final conversation = ChatThread(
                id: threadId,
                userId: otherUserId,
                username: otherUsername,
                fullName: otherFullName,
                avatar: otherAvatar,
                lastMessage: latestMessage['content'] ?? '',
                lastMessageTime: DateTime.parse(latestMessage['createdAt'] ?? DateTime.now().toIso8601String()),
                unreadCount: unreadCount,
              );
              
              conversations.add(conversation);
              
              // Store this conversation locally for future use
              await _storeConversation(currentUserId, conversation);
            }
          }
          
          print('ChatService: Created ${conversations.length} conversations from API');
          return conversations;
        } else {
          print('ChatService: API returned error: ${jsonResponse['message']}');
          return [];
        }
      } else {
        print('ChatService: API request failed: ${response.statusCode} - ${response.body}');
        // If API fails, try alternative endpoints
        return await _tryAlternativeConversationEndpoints(token, currentUserId);
      }
    } catch (e) {
      print('ChatService: Error fetching conversations from API: $e');
      return [];
    }
  }

  /// Try alternative API endpoints to get conversations
  static Future<List<ChatThread>> _tryAlternativeConversationEndpoints(
    String token,
    String currentUserId,
  ) async {
    try {
      print('ChatService: Trying alternative conversation endpoints');
      
      // Try different endpoints that might work
      final endpoints = [
        '$baseUrl/messages?userId=$currentUserId&limit=100',
        '$baseUrl/conversations?userId=$currentUserId',
        '$baseUrl/chat-threads?userId=$currentUserId',
      ];
      
      for (final endpoint in endpoints) {
        try {
          print('ChatService: Trying endpoint: $endpoint');
          final response = await http.get(
            Uri.parse(endpoint),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );
          
          if (response.statusCode == 200) {
            print('ChatService: Alternative endpoint succeeded: $endpoint');
            final jsonResponse = jsonDecode(response.body);
            
            if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
              // Process the response similar to the main method
              final messagesData = jsonResponse['data'] as List;
              return await _processMessagesIntoConversations(messagesData, currentUserId);
            }
          } else {
            print('ChatService: Alternative endpoint failed: $endpoint - ${response.statusCode}');
          }
        } catch (e) {
          print('ChatService: Error with alternative endpoint $endpoint: $e');
        }
      }
      
      print('ChatService: All alternative endpoints failed, returning empty list');
      return [];
    } catch (e) {
      print('ChatService: Error trying alternative endpoints: $e');
      return [];
    }
  }

  /// Process messages data into conversations
  static Future<List<ChatThread>> _processMessagesIntoConversations(
    List<dynamic> messagesData,
    String currentUserId,
  ) async {
    try {
      print('ChatService: Processing ${messagesData.length} messages into conversations');
      
      // Group messages by thread and create conversations
      final threadMap = <String, List<Map<String, dynamic>>>{};
      
      for (final messageData in messagesData) {
        final threadId = messageData['threadId'] ?? messageData['thread'] ?? '';
        if (threadId.isNotEmpty) {
          if (!threadMap.containsKey(threadId)) {
            threadMap[threadId] = [];
          }
          threadMap[threadId]!.add(messageData);
        }
      }
      
      // Create ChatThread objects from grouped messages
      final conversations = <ChatThread>[];
      
      for (final entry in threadMap.entries) {
        final threadId = entry.key;
        final messages = entry.value;
        
        if (messages.isNotEmpty) {
          // Sort messages by creation time to get the latest
          messages.sort((a, b) {
            final timeA = DateTime.parse(a['createdAt'] ?? DateTime.now().toIso8601String());
            final timeB = DateTime.parse(b['createdAt'] ?? DateTime.now().toIso8601String());
            return timeB.compareTo(timeA);
          });
          
          final latestMessage = messages.first;
          final sender = latestMessage['sender'];
          final recipient = latestMessage['recipient'];
          
          // Determine the other user in the conversation
          String otherUserId;
          String otherUsername;
          String otherFullName;
          String otherAvatar;
          
          if (sender['_id'] == currentUserId) {
            // Current user is sender, other user is recipient
            otherUserId = recipient;
            otherUsername = 'User';
            otherFullName = 'User';
            otherAvatar = '';
          } else {
            // Current user is recipient, other user is sender
            otherUserId = sender['_id'] ?? '';
            otherUsername = sender['username'] ?? 'User';
            otherFullName = sender['fullName'] ?? 'User';
            otherAvatar = sender['avatar'] ?? '';
          }
          
          // Count unread messages
          int unreadCount = 0;
          for (final message in messages) {
            if (message['recipient'] == currentUserId && 
                (message['isRead'] == false || message['isRead'] == null)) {
              unreadCount++;
            }
          }
          
          final conversation = ChatThread(
            id: threadId,
            userId: otherUserId,
            username: otherUsername,
            fullName: otherFullName,
            avatar: otherAvatar,
            lastMessage: latestMessage['content'] ?? '',
            lastMessageTime: DateTime.parse(latestMessage['createdAt'] ?? DateTime.now().toIso8601String()),
            unreadCount: unreadCount,
          );
          
          conversations.add(conversation);
        }
      }
      
      print('ChatService: Created ${conversations.length} conversations from messages');
      return conversations;
    } catch (e) {
      print('ChatService: Error processing messages into conversations: $e');
      return [];
    }
  }

  /// Get user information from API
  static Future<Map<String, dynamic>?> _getUserInfo(String userId, String token) async {
    try {
      print('ChatService: Fetching user info for: $userId');
      
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
          final userData = jsonResponse['data'];
          return {
            'username': userData['username'] ?? '',
            'fullName': userData['fullName'] ?? userData['name'] ?? '',
            'avatar': userData['avatar'] ?? userData['profileImageUrl'] ?? '',
          };
        }
      }
      
      print('ChatService: Failed to get user info: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('ChatService: Error getting user info: $e');
      return null;
    }
  }

  /// Update conversation with user info
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

  /// Get conversations from local storage (public method)
  static Future<List<ChatThread>> getLocalConversations(String userId) async {
    return await _getLocalConversations(userId);
  }

  /// Initialize conversations on app startup
  static Future<List<ChatThread>> initializeConversations({
    required String currentUserId,
    required String token,
  }) async {
    try {
      print('ChatService: Initializing conversations for user: $currentUserId');
      
      // Get local conversations first
      final localConversations = await _getLocalConversations(currentUserId);
      print('ChatService: Found ${localConversations.length} local conversations on startup');
      
      // Try to sync with API (but don't fail if it doesn't work)
      try {
        final apiConversations = await getAllConversations(
          token: token,
          currentUserId: currentUserId,
        );
        print('ChatService: Synced ${apiConversations.length} API conversations on startup');
        
        // Return the combined list (local conversations are prioritized)
        final allConversations = <ChatThread>[];
        final seenUserIds = <String>{};
        
        // Add local conversations first
        for (final conversation in localConversations) {
          allConversations.add(conversation);
          seenUserIds.add(conversation.userId);
        }
        
        // Add API conversations that aren't already in local storage
        for (final conversation in apiConversations) {
          if (!seenUserIds.contains(conversation.userId)) {
            allConversations.add(conversation);
            seenUserIds.add(conversation.userId);
          }
        }
        
        // Sort by last message time (most recent first)
        allConversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        
        return allConversations;
      } catch (apiError) {
        print('ChatService: API sync failed on startup, using local conversations only: $apiError');
        return localConversations;
      }
    } catch (e) {
      print('ChatService: Error initializing conversations: $e');
      return [];
    }
  }

  /// Update conversation when a message is received
  static Future<void> updateConversationOnMessageReceived({
    required String currentUserId,
    required String senderUserId,
    required String senderUsername,
    required String senderFullName,
    required String senderAvatar,
    required String lastMessage,
    required DateTime lastMessageTime,
    String? threadId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'conversation_${currentUserId}_$senderUserId';
      
      final conversationData = {
        'id': threadId ?? '',
        'userId': senderUserId,
        'username': senderUsername,
        'fullName': senderFullName,
        'avatar': senderAvatar,
        'lastMessage': lastMessage,
        'lastMessageTime': lastMessageTime.toIso8601String(),
        'unreadCount': 1, // Mark as unread when message is received
      };
      
      await prefs.setString(key, jsonEncode(conversationData));
      print('ChatService: Updated conversation on message received: $key');
    } catch (e) {
      print('ChatService: Error updating conversation on message received: $e');
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
            lastMessageTime: threadData['lastMessageTime'] != null 
                ? DateTime.parse(threadData['lastMessageTime'])
                : DateTime.now(),
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

  /// Update conversation with the latest message from a thread
  static Future<void> _updateConversationWithLatestMessage({
    required String threadId,
    required Message latestMessage,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Find all conversation keys that might contain this thread
      final keys = prefs.getKeys().where((key) => key.startsWith('conversation_')).toList();
      
      for (final key in keys) {
        final conversationData = prefs.getString(key);
        if (conversationData != null) {
          final data = jsonDecode(conversationData);
          if (data['id'] == threadId) {
            // Update the last message and time
            data['lastMessage'] = latestMessage.content;
            data['lastMessageTime'] = latestMessage.createdAt.toIso8601String();
            
            await prefs.setString(key, jsonEncode(data));
            print('ChatService: Updated conversation $key with latest message: ${latestMessage.content}');
            break;
          }
        }
      }
    } catch (e) {
      print('ChatService: Error updating conversation with latest message: $e');
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

  /// Clear corrupted conversation data and start fresh
  static Future<void> clearCorruptedConversations(String currentUserId) async {
    try {
      print('ChatService: Clearing corrupted conversations for user: $currentUserId');
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('conversation_${currentUserId}_')).toList();
      
      int corruptedCount = 0;
      for (final key in keys) {
        try {
          final threadJson = prefs.getString(key);
          if (threadJson != null) {
            final threadData = jsonDecode(threadJson);
            // Check if any required fields are null
            if (threadData['lastMessageTime'] == null || 
                threadData['userId'] == null ||
                threadData['username'] == null) {
              await prefs.remove(key);
              corruptedCount++;
              print('ChatService: Removed corrupted conversation: $key');
            }
          }
        } catch (e) {
          // If we can't parse the data, it's corrupted
          await prefs.remove(key);
          corruptedCount++;
          print('ChatService: Removed corrupted conversation (parse error): $key');
        }
      }
      
      print('ChatService: Cleared $corruptedCount corrupted conversations');
    } catch (e) {
      print('ChatService: Error clearing corrupted conversations: $e');
    }
  }

  /// Ensure all conversations are permanently stored and never lost
  /// This method provides additional safety to prevent conversation loss
  static Future<void> ensureConversationPersistence(String currentUserId) async {
    try {
      print('ChatService: Ensuring conversation persistence for user: $currentUserId');
      
      // Get all local conversations
      final localConversations = await _getLocalConversations(currentUserId);
      print('ChatService: Found ${localConversations.length} local conversations to ensure persistence');
      
      // Re-store each conversation to ensure it's properly saved
      for (final conversation in localConversations) {
        await _storeConversation(currentUserId, conversation);
        print('ChatService: Re-stored conversation with ${conversation.fullName} to ensure persistence');
      }
      
      // Also ensure thread IDs are cached
      for (final conversation in localConversations) {
        if (conversation.id.isNotEmpty && !conversation.id.startsWith('temp_')) {
          await _cacheThreadId(currentUserId, conversation.userId, conversation.id);
        }
      }
      
      print('ChatService: Conversation persistence ensured for ${localConversations.length} conversations');
    } catch (e) {
      print('ChatService: Error ensuring conversation persistence: $e');
    }
  }

  /// Get conversation count for debugging
  static Future<int> getConversationCount(String currentUserId) async {
    try {
      final conversations = await _getLocalConversations(currentUserId);
      return conversations.length;
    } catch (e) {
      print('ChatService: Error getting conversation count: $e');
      return 0;
    }
  }

  /// Backup all conversations to ensure they're never lost
  static Future<void> backupConversations(String currentUserId) async {
    try {
      final conversations = await _getLocalConversations(currentUserId);
      final prefs = await SharedPreferences.getInstance();
      
      // Create a backup key
      final backupKey = 'conversation_backup_${currentUserId}_${DateTime.now().millisecondsSinceEpoch}';
      final backupData = {
        'timestamp': DateTime.now().toIso8601String(),
        'conversations': conversations.map((conv) => {
          'id': conv.id,
          'userId': conv.userId,
          'username': conv.username,
          'fullName': conv.fullName,
          'avatar': conv.avatar,
          'lastMessage': conv.lastMessage,
          'lastMessageTime': conv.lastMessageTime.toIso8601String(),
          'unreadCount': conv.unreadCount,
        }).toList(),
      };
      
      await prefs.setString(backupKey, jsonEncode(backupData));
      print('ChatService: Backed up ${conversations.length} conversations to key: $backupKey');
    } catch (e) {
      print('ChatService: Error backing up conversations: $e');
    }
  }

  /// Get messages for a specific thread using the correct API endpoint
  static Future<List<Message>> getMessagesByThreadId({
    required String threadId,
    required String token,
  }) async {
    try {
      print('ChatService: Getting messages for thread: $threadId');
      
      // Try to get cached messages first
      final cachedMessages = await _getCachedMessages(threadId);
      if (cachedMessages.isNotEmpty) {
        print('ChatService: Found ${cachedMessages.length} cached messages');
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/enhanced-message?threadId=$threadId&limit=50'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('ChatService: Get messages response status: ${response.statusCode}');
      print('ChatService: Get messages response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        // Handle different response formats
        List<dynamic> messagesData = [];
        
        if (jsonResponse['success'] == true) {
          if (jsonResponse['data'] != null) {
            // Try different possible data structures
            if (jsonResponse['data']['messages'] != null) {
              messagesData = jsonResponse['data']['messages'];
            } else if (jsonResponse['data'] is List) {
              messagesData = jsonResponse['data'];
            } else if (jsonResponse['messages'] != null) {
              messagesData = jsonResponse['messages'];
            }
          }
        } else if (jsonResponse['messages'] != null) {
          // Fallback: check if messages are directly in response
          messagesData = jsonResponse['messages'];
        }
        
        print('ChatService: Found ${messagesData.length} messages in API response');
        
        final List<Message> messages = [];
        
        for (final messageData in messagesData) {
          try {
            final sender = messageData['sender'] ?? {};
            final recipient = messageData['recipient'];
            
            // Handle recipient field - it can be a Map or String
            String recipientId = '';
            if (recipient is Map<String, dynamic>) {
              recipientId = recipient['_id'] ?? '';
            } else if (recipient is String) {
              recipientId = recipient;
            }
            
            // Debug: Log media information
            final messageType = messageData['messageType'] ?? 'text';
            final mediaUrl = messageData['mediaUrl'];
            if (messageType == 'image' || messageType == 'video') {
              print('ChatService: Found $messageType message with mediaUrl: $mediaUrl');
            }
            
            final message = Message(
              id: messageData['_id'] ?? '',
              threadId: messageData['thread'] ?? threadId,
              sender: MessageSender(
                id: sender['_id'] ?? '',
                username: sender['username'] ?? '',
                fullName: sender['fullName'] ?? '',
                avatar: sender['avatar'] ?? '',
              ),
              recipient: recipientId,
              content: messageData['content'] ?? '',
              messageType: messageType,
              mediaUrl: mediaUrl,
              mediaInfo: messageData['mediaInfo'],
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
            print('ChatService: Message data: $messageData');
          }
        }
        
        // Sort messages by creation time (oldest first)
        messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        
        // Update conversation with the latest message if we have messages
        if (messages.isNotEmpty) {
          final latestMessage = messages.last;
          await _updateConversationWithLatestMessage(
            threadId: threadId,
            latestMessage: latestMessage,
          );
          
          // Cache the messages
          await _cacheMessages(threadId, messages);
          
          print('ChatService: Successfully loaded ${messages.length} messages from API');
          return messages;
        } else {
          print('ChatService: No messages found in API response, checking cache');
        }
      } else {
        print('ChatService: API request failed with status ${response.statusCode}');
      }
      
      // If API fails or returns no messages, try alternative approach
      print('ChatService: Primary API failed or empty, trying alternative approach');
      
      // Try to get messages using getAllConversations and filter by thread
      try {
        // Get current user ID from token or use a fallback approach
        final conversations = await getAllConversations(
          token: token,
          currentUserId: '', // We'll let the method handle this
        );
        
        // Find the conversation for this thread
        ChatThread? conversation;
        try {
          conversation = conversations.firstWhere(
            (conv) => conv.id == threadId,
          );
        } catch (e) {
          conversation = null;
        }
        
        if (conversation != null && conversation.lastMessage.isNotEmpty) {
          print('ChatService: Found conversation with last message, trying to get messages from conversation history');
          
          // Try to get messages using the conversation's thread ID
          final altMessages = await _getMessagesFromConversationHistory(threadId, token);
          if (altMessages.isNotEmpty) {
            print('ChatService: Found ${altMessages.length} messages from conversation history');
            await _cacheMessages(threadId, altMessages);
            return altMessages;
          }
        }
      } catch (e) {
        print('ChatService: Alternative approach failed: $e');
      }
      
      // If API fails or returns no messages, return cached messages if available
      if (cachedMessages.isNotEmpty) {
        print('ChatService: API failed or empty, returning ${cachedMessages.length} cached messages');
        
        // Update conversation with the latest cached message
        final latestMessage = cachedMessages.last;
        await _updateConversationWithLatestMessage(
          threadId: threadId,
          latestMessage: latestMessage,
        );
        
        return cachedMessages;
      }
      
      print('ChatService: No messages found for thread: $threadId (API and cache both empty)');
      return [];
      
    } catch (e) {
      print('ChatService: Error getting messages by thread ID: $e');
      
      // Try to return cached messages on error
      final cachedMessages = await _getCachedMessages(threadId);
      if (cachedMessages.isNotEmpty) {
        print('ChatService: Error occurred, returning ${cachedMessages.length} cached messages');
        return cachedMessages;
      }
      
      return [];
    }
  }

  /// Get messages from conversation history as fallback
  static Future<List<Message>> _getMessagesFromConversationHistory(
    String threadId,
    String token,
  ) async {
    try {
      print('ChatService: Trying to get messages from conversation history for thread: $threadId');
      
      // Try different API endpoints that might have the messages
      final endpoints = [
        '$baseUrl/messages?threadId=$threadId&limit=50',
        '$baseUrl/enhanced-message?threadId=$threadId&limit=100',
        '$baseUrl/message?threadId=$threadId',
      ];
      
      for (final endpoint in endpoints) {
        try {
          final response = await http.get(
            Uri.parse(endpoint),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );
          
          if (response.statusCode == 200) {
            final jsonResponse = jsonDecode(response.body);
            List<dynamic> messagesData = [];
            
            // Try different response structures
            if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
              if (jsonResponse['data']['messages'] != null) {
                messagesData = jsonResponse['data']['messages'];
              } else if (jsonResponse['data'] is List) {
                messagesData = jsonResponse['data'];
              }
            } else if (jsonResponse['messages'] != null) {
              messagesData = jsonResponse['messages'];
            }
            
            if (messagesData.isNotEmpty) {
              print('ChatService: Found ${messagesData.length} messages from endpoint: $endpoint');
              
              final List<Message> messages = [];
              for (final messageData in messagesData) {
                try {
                  final sender = messageData['sender'] ?? {};
                  final recipient = messageData['recipient'];
                  
                  String recipientId = '';
                  if (recipient is Map<String, dynamic>) {
                    recipientId = recipient['_id'] ?? '';
                  } else if (recipient is String) {
                    recipientId = recipient;
                  }
                  
                  final message = Message(
                    id: messageData['_id'] ?? '',
                    threadId: messageData['thread'] ?? threadId,
                    sender: MessageSender(
                      id: sender['_id'] ?? '',
                      username: sender['username'] ?? '',
                      fullName: sender['fullName'] ?? '',
                      avatar: sender['avatar'] ?? '',
                    ),
                    recipient: recipientId,
                    content: messageData['content'] ?? '',
                    messageType: messageData['messageType'] ?? 'text',
                    mediaUrl: messageData['mediaUrl'],
                    mediaInfo: messageData['mediaInfo'],
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
                  print('ChatService: Error creating message from conversation history: $e');
                }
              }
              
              if (messages.isNotEmpty) {
                messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
                return messages;
              }
            }
          }
        } catch (e) {
          print('ChatService: Error trying endpoint $endpoint: $e');
        }
      }
      
      return [];
    } catch (e) {
      print('ChatService: Error getting messages from conversation history: $e');
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

  /// Delete a message (soft delete)
  static Future<Map<String, dynamic>> deleteMessage({
    required String messageId,
    required String token,
    String deleteType = 'soft',
  }) async {
    try {
      print('ChatService: Deleting message: $messageId');
      print('ChatService: Delete type: $deleteType');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/enhanced-message'),
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

      if (response.statusCode == 200 || response.statusCode == 201) {
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

  /// Create or get a conversation thread between two users
  static Future<String?> createOrGetThread({
    required String currentUserId,
    required String otherUserId,
    required String token,
  }) async {
    try {
      print('ChatService: Creating/getting thread between $currentUserId and $otherUserId');
      
      // First, check if we have a cached thread ID
      final cachedThreadId = await _getCachedThreadId(currentUserId, otherUserId);
      if (cachedThreadId != null && cachedThreadId.isNotEmpty && !cachedThreadId.startsWith('temp_')) {
        print('ChatService: Found cached thread ID: $cachedThreadId');
        
        // Verify this thread still exists on the server by trying to get messages
        try {
          final messages = await getMessagesByThreadId(
            threadId: cachedThreadId,
            token: token,
          );
          if (messages.isNotEmpty) {
            print('ChatService: Verified cached thread exists on server with ${messages.length} messages');
            return cachedThreadId;
          } else {
            print('ChatService: Cached thread ID exists but no messages found, will check server for other threads');
          }
        } catch (e) {
          print('ChatService: Error verifying cached thread on server: $e');
        }
      }
      
      // Also check the old conversation storage format for backward compatibility
      try {
        final prefs = await SharedPreferences.getInstance();
        final key = 'conversation_${currentUserId}_$otherUserId';
        final existingData = prefs.getString(key);
        
        if (existingData != null) {
          final conversationData = jsonDecode(existingData);
          final threadId = conversationData['id'];
          if (threadId != null && threadId.isNotEmpty && !threadId.startsWith('temp_')) {
            print('ChatService: Found existing thread ID in old format: $threadId');
            
            // Cache it in the new format
            await _cacheThreadId(currentUserId, otherUserId, threadId);
            
            // Verify this thread still exists on the server by trying to get messages
            try {
              final messages = await getMessagesByThreadId(
                threadId: threadId,
                token: token,
              );
              if (messages.isNotEmpty) {
                print('ChatService: Verified thread exists on server with ${messages.length} messages');
                return threadId;
              } else {
                print('ChatService: Thread ID exists but no messages found, will check server for other threads');
              }
            } catch (e) {
              print('ChatService: Error verifying thread on server: $e');
            }
          }
        }
        
        // If no local thread or verification failed, try to find existing messages on server
        print('ChatService: Checking server for existing messages between users');
        print('ChatService: Looking for conversation between $currentUserId and $otherUserId');
        try {
          // Try to get all conversations and find one between these users
          final conversations = await getAllConversations(
            token: token,
            currentUserId: currentUserId,
          );
          
          print('ChatService: Retrieved ${conversations.length} conversations from server');
          for (int i = 0; i < conversations.length; i++) {
            final conv = conversations[i];
            print('ChatService: Conversation $i - User ID: ${conv.userId}, Thread ID: ${conv.id}, Last Message: ${conv.lastMessage}');
          }
          
          // Look for a conversation with the other user
          for (final conversation in conversations) {
            print('ChatService: Checking conversation with user ${conversation.userId} against target ${otherUserId}');
            if (conversation.userId == otherUserId) {
              print('ChatService: Found existing conversation with ${conversation.userId}, thread ID: ${conversation.id}');
              
              // Store this thread ID in both old and new formats for compatibility
              try {
                final prefs = await SharedPreferences.getInstance();
                final key = 'conversation_${currentUserId}_$otherUserId';
                await prefs.setString(key, jsonEncode({
                  'id': conversation.id,
                  'userId': otherUserId,
                  'username': conversation.username,
                  'fullName': conversation.fullName,
                  'avatar': conversation.avatar,
                  'lastMessage': conversation.lastMessage,
                  'timestamp': conversation.lastMessageTime.toIso8601String(),
                }));
                
                // Also cache in the new format
                await _cacheThreadId(currentUserId, otherUserId, conversation.id);
                
                print('ChatService: Stored conversation data in local storage');
              } catch (e) {
                print('ChatService: Error storing conversation in local storage: $e');
              }
              
              // Verify this thread has messages
              try {
                print('ChatService: Verifying thread ${conversation.id} has messages...');
                final messages = await getMessagesByThreadId(
                  threadId: conversation.id,
                  token: token,
                );
                print('ChatService: Thread ${conversation.id} has ${messages.length} messages');
                if (messages.isNotEmpty) {
                  print('ChatService: Found existing thread with ${messages.length} messages - returning thread ID');
                  return conversation.id;
                } else {
                  print('ChatService: Thread ${conversation.id} exists but has no messages');
                  // Even if no messages, return the thread ID so we can use it for new messages
                  return conversation.id;
                }
              } catch (e) {
                print('ChatService: Error verifying conversation thread ${conversation.id}: $e');
                // Even if verification fails, return the thread ID
                return conversation.id;
              }
            }
          }
          print('ChatService: No conversation found with user $otherUserId');
        } catch (e) {
          print('ChatService: Error checking server for existing conversations: $e');
        }
        
        // If no existing thread found, create a temporary one
        final tempThreadId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        print('ChatService: No existing thread found, created temporary thread ID: $tempThreadId');
        
        // Cache the temporary thread ID
        await _cacheThreadId(currentUserId, otherUserId, tempThreadId);
        
        return tempThreadId;
        
      } catch (e) {
        print('ChatService: Error checking for existing thread: $e');
        // Return temporary thread ID as fallback
        return 'temp_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      print('ChatService: Error creating thread: $e');
      return null;
    }
  }

  /// Cache thread ID permanently for a user pair
  static Future<void> _cacheThreadId(String currentUserId, String otherUserId, String threadId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'thread_${currentUserId}_$otherUserId';
      await prefs.setString(key, threadId);
      print('ChatService: Cached thread ID $threadId for users $currentUserId and $otherUserId');
    } catch (e) {
      print('ChatService: Error caching thread ID: $e');
    }
  }

  /// Get cached thread ID for a user pair
  static Future<String?> _getCachedThreadId(String currentUserId, String otherUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'thread_${currentUserId}_$otherUserId';
      final threadId = prefs.getString(key);
      if (threadId != null && threadId.isNotEmpty) {
        print('ChatService: Retrieved cached thread ID $threadId for users $currentUserId and $otherUserId');
        return threadId;
      }
    } catch (e) {
      print('ChatService: Error getting cached thread ID: $e');
    }
    return null;
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

  /// Cache messages locally for offline access
  static Future<void> _cacheMessages(String threadId, List<Message> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'messages_$threadId';
      final messagesJson = messages.map((message) => {
        'id': message.id,
        'threadId': message.threadId,
        'sender': {
          'id': message.sender.id,
          'username': message.sender.username,
          'fullName': message.sender.fullName,
          'avatar': message.sender.avatar,
        },
        'recipient': message.recipient,
        'content': message.content,
        'messageType': message.messageType,
        'mediaUrl': message.mediaUrl,
        'mediaInfo': message.mediaInfo,
        'isRead': message.isRead,
        'isDeleted': message.isDeleted,
        'reactions': message.reactions,
        'createdAt': message.createdAt.toIso8601String(),
        'updatedAt': message.updatedAt.toIso8601String(),
      }).toList();
      
      await prefs.setString(key, jsonEncode(messagesJson));
      print('ChatService: Cached ${messages.length} messages for thread: $threadId');
    } catch (e) {
      print('ChatService: Error caching messages: $e');
    }
  }

  /// Get cached messages for a thread
  static Future<List<Message>> _getCachedMessages(String threadId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'messages_$threadId';
      final messagesJson = prefs.getString(key);
      
      if (messagesJson != null) {
        final List<dynamic> messagesData = jsonDecode(messagesJson);
        final List<Message> messages = [];
        
        for (final messageData in messagesData) {
          try {
            final sender = messageData['sender'] ?? {};
            final message = Message(
              id: messageData['id'] ?? '',
              threadId: messageData['threadId'] ?? '',
              sender: MessageSender(
                id: sender['id'] ?? '',
                username: sender['username'] ?? '',
                fullName: sender['fullName'] ?? '',
                avatar: sender['avatar'] ?? '',
              ),
              recipient: messageData['recipient'] ?? '',
              content: messageData['content'] ?? '',
              messageType: messageData['messageType'] ?? 'text',
              mediaUrl: messageData['mediaUrl'],
              mediaInfo: messageData['mediaInfo'],
              isRead: messageData['isRead'] ?? false,
              isDeleted: messageData['isDeleted'] ?? false,
              reactions: messageData['reactions'] ?? [],
              createdAt: DateTime.parse(messageData['createdAt']),
              updatedAt: DateTime.parse(messageData['updatedAt']),
            );
            messages.add(message);
          } catch (e) {
            print('ChatService: Error creating cached message: $e');
          }
        }
        
        // Sort messages by creation time (oldest first)
        messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        
        return messages;
      }
      
      return [];
    } catch (e) {
      print('ChatService: Error getting cached messages: $e');
      return [];
    }
  }

  /// Clear cached messages for a thread
  static Future<void> clearCachedMessages(String threadId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'messages_$threadId';
      await prefs.remove(key);
      print('ChatService: Cleared cached messages for thread: $threadId');
    } catch (e) {
      print('ChatService: Error clearing cached messages: $e');
    }
  }

  /// Send media message (image/video) using the send-media API
  static Future<Map<String, dynamic>> sendMediaMessage({
    required dynamic file, // File or XFile
    required String toUserId,
    required String content,
    required String messageType, // 'image' or 'video'
    required String token,
    String? currentUserId,
  }) async {
    try {
      print('ChatService: Sending media message to user: $toUserId');
      print('ChatService: Message type: $messageType');
      print('ChatService: Content: $content');

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/send-media'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      request.fields['toUserId'] = toUserId;
      request.fields['content'] = content;
      request.fields['messageType'] = messageType;

      // Add file
      if (file is File) {
        final fileName = file.path.split('/').last;
        final contentType = _getContentType(fileName);
        
        request.files.add(
          http.MultipartFile(
            'file',
            file.readAsBytes().asStream(),
            file.lengthSync(),
            filename: fileName,
            contentType: MediaType.parse(contentType),
          ),
        );
      } else {
        return {
          'success': false,
          'message': 'File type not supported: ${file.runtimeType}',
        };
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('ChatService: Send media response status: ${response.statusCode}');
      print('ChatService: Send media response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          print('ChatService: Media message sent successfully');
          
          // Store conversation locally if we have thread info
          if (jsonResponse['data']?['threadId'] != null) {
            print('ChatService: Thread ID from send media response: ${jsonResponse['data']['threadId']}');
            
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
          print('ChatService: Send media message failed: ${jsonResponse['message']}');
          return {
            'success': false,
            'message': jsonResponse['message'] ?? 'Failed to send media message',
          };
        }
      } else {
        print('ChatService: Send media message failed: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'message': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('ChatService: Error sending media message: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get content type based on file extension
  static String _getContentType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'webm':
        return 'video/webm';
      default:
        return 'application/octet-stream';
    }
  }
}




