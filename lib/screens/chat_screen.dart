import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../models/chat_thread_model.dart';
import '../services/chat_service.dart';
import '../models/chat_response_model.dart';
import '../widgets/app_loader.dart';
import '../utils/app_theme.dart';
import '../services/theme_service.dart';
import '../widgets/user_avatar_widget.dart';

class ChatScreen extends StatefulWidget {
  final String recipientUserId;
  final String recipientUsername;
  final String recipientFullName;
  final String? recipientAvatar;
  final String? threadId; // Optional thread ID if coming from existing conversation

  const ChatScreen({
    super.key,
    required this.recipientUserId,
    required this.recipientUsername,
    required this.recipientFullName,
    this.recipientAvatar,
    this.threadId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = false;
  String? _currentThreadId;
  bool _isSending = false;
  DateTime? _lastRefreshTime;
  Timer? _messagePollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Set the thread ID if provided
    _currentThreadId = widget.threadId;
    
    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
    
    // Load messages and start polling
    _loadMessages();
    _startMessagePolling();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load messages when screen becomes active if we have a real thread ID
    if (_currentThreadId != null && !_currentThreadId!.startsWith('temp_')) {
      _loadMessages();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh messages when app becomes active if we have a real thread ID
    if (state == AppLifecycleState.resumed && _currentThreadId != null && !_currentThreadId!.startsWith('temp_')) {
      _loadMessages();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    // Stop real-time updates
    _stopMessagePolling();
    _lastRefreshTime = null;
    super.dispose();
  }

  Future<void> _loadMessages() async {
    // Don't reload if we already have messages and it's been less than 30 seconds since last load
    if (_messages.isNotEmpty && _lastRefreshTime != null) {
      final timeSinceLastLoad = DateTime.now().difference(_lastRefreshTime!);
      if (timeSinceLastLoad.inSeconds < 30) {
        print('ChatScreen: Skipping reload - messages loaded recently');
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // If we have a real thread ID (not temp and not empty), load messages from that thread
      if (_currentThreadId != null && 
          _currentThreadId!.isNotEmpty && 
          !_currentThreadId!.startsWith('temp_')) {
        print('ChatScreen: Loading messages for real thread: $_currentThreadId');
        print('ChatScreen: Current messages count before loading: ${_messages.length}');
        
        final messages = await ChatService.getMessagesByThreadId(
          threadId: _currentThreadId!,
          token: authProvider.authToken!,
        );
        
        if (mounted) {
          setState(() {
            // Always update messages to ensure we have the latest
            _messages = messages;
            print('ChatScreen: Loaded ${messages.length} messages from API');
            
            _isLoading = false;
          });
          _scrollToBottom();
          _lastRefreshTime = DateTime.now();
        }
      } else if (_currentThreadId != null && _currentThreadId!.startsWith('temp_')) {
        // We have a temporary thread ID, don't load any messages - just show empty state
        print('ChatScreen: Using temporary thread ID, no messages to load');
        setState(() {
          _messages = []; // Clear any existing messages
          _isLoading = false;
        });
      } else {
        // If no thread ID, try to create or get a thread with this user
        print('ChatScreen: No thread ID provided, creating/getting thread with ${widget.recipientUserId}');
        
        final threadId = await ChatService.createOrGetThread(
          currentUserId: authProvider.userProfile!.id,
          otherUserId: widget.recipientUserId,
          token: authProvider.authToken!,
        );
        
        if (threadId != null) {
          _currentThreadId = threadId;
          print('ChatScreen: Got thread ID: $_currentThreadId');
          
          // Only load messages if we have a real thread ID
          if (!_currentThreadId!.startsWith('temp_')) {
            final messages = await ChatService.getMessagesByThreadId(
              threadId: _currentThreadId!,
              token: authProvider.authToken!,
            );
            
            if (mounted) {
              setState(() {
                _messages = messages;
                _isLoading = false;
              });
              _scrollToBottom();
              
              // Mark messages as read
              if (messages.isNotEmpty) {
                ChatService.markMessagesAsRead(
                  threadId: _currentThreadId!,
                  token: authProvider.authToken!,
                );
              }
            }
          } else {
            // Temporary thread, no messages to load
            setState(() {
              _messages = [];
              _isLoading = false;
            });
          }
        } else {
          // Failed to create thread, start fresh
          print('ChatScreen: Failed to create thread, starting fresh');
          setState(() {
            _messages = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('ChatScreen: Error loading messages: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading messages: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Start polling for new messages
  void _startMessagePolling() {
    // Only start polling if we have a real thread ID
    if (_currentThreadId != null && !_currentThreadId!.startsWith('temp_')) {
      print('ChatScreen: Starting message polling for thread: $_currentThreadId');
      _messagePollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        _pollForNewMessages();
      });
    } else {
      print('ChatScreen: Not starting polling - no real thread ID yet');
    }
  }

  /// Stop polling for new messages
  void _stopMessagePolling() {
    if (_messagePollingTimer != null) {
      print('ChatScreen: Stopping message polling');
      _messagePollingTimer!.cancel();
      _messagePollingTimer = null;
    }
  }

  /// Poll for new messages
  Future<void> _pollForNewMessages() async {
    if (_currentThreadId == null || _currentThreadId!.startsWith('temp_')) {
      return; // Don't poll if we don't have a real thread ID
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final messages = await ChatService.getMessagesByThreadId(
        threadId: _currentThreadId!,
        token: authProvider.authToken!,
      );

      if (mounted && messages.isNotEmpty) {
        // Check if we have new messages
        final existingMessageIds = _messages.map((m) => m.id).toSet();
        final newMessages = messages.where((m) => !existingMessageIds.contains(m.id)).toList();

        if (newMessages.isNotEmpty) {
          print('ChatScreen: Found ${newMessages.length} new messages via polling');
          setState(() {
            _messages.addAll(newMessages);
            // Sort messages by creation time to maintain chronological order
            _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      print('ChatScreen: Error polling for new messages: $e');
    }
  }

  // Edit message
  Future<void> _editMessage(Message message, String newContent) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final authToken = authProvider.authToken;
      
      if (authToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication token not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final response = await ChatService.updateMessage(
        messageId: message.id,
        content: newContent,
        token: authToken,
      );

      if (response['success'] == true && mounted) {
        // Update the message in the local list
        setState(() {
          final index = _messages.indexWhere((m) => m.id == message.id);
          if (index != -1) {
            _messages[index] = Message(
              id: message.id,
              threadId: message.threadId,
              sender: message.sender,
              recipient: message.recipient,
              content: newContent,
              messageType: message.messageType,
              isRead: message.isRead,
              isDeleted: message.isDeleted,
              reactions: message.reactions,
              createdAt: message.createdAt,
              updatedAt: DateTime.now(),
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Message updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to edit message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error editing message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Delete message
  Future<void> _deleteMessage(Message message) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final authToken = authProvider.authToken;
      
      if (authToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication token not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final response = await ChatService.deleteMessage(
        messageId: message.id,
        token: authToken,
        deleteType: 'soft',
      );

      if (response['success'] == true && mounted) {
        // Remove the message from the local list
        setState(() {
          _messages.removeWhere((m) => m.id == message.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Message deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to delete message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show edit message dialog
  void _showEditDialog(Message message) {
    final TextEditingController editController = TextEditingController(text: message.content);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(
            hintText: 'Enter new message content',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
                      ElevatedButton(
              onPressed: () {
                final newContent = editController.text.trim();
                if (newContent.isNotEmpty && newContent != message.content) {
                  Navigator.of(context).pop();
                  _editMessage(message, newContent);
                }
              },
              child: const Text('Update'),
            ),
        ],
      ),
    );
  }

  // Show message options menu
  void _showMessageOptions(Message message, bool isCurrentUser) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrentUser) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit Message'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showEditDialog(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Message'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showDeleteConfirmation(message);
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Message'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showDeleteConfirmation(message);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  // Show delete confirmation dialog
  void _showDeleteConfirmation(Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteMessage(message);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // If no thread ID exists, try to create one first
      if (_currentThreadId == null || _currentThreadId!.startsWith('temp_')) {
        print('ChatScreen: No thread ID or temporary thread, creating new chat thread');
        final threadId = await ChatService.createOrGetThread(
          currentUserId: authProvider.userProfile!.id,
          otherUserId: widget.recipientUserId,
          token: authProvider.authToken!,
        );
        
        if (threadId != null) {
          _currentThreadId = threadId;
          print('ChatScreen: Created new thread with ID: $_currentThreadId');
        } else {
          print('ChatScreen: Failed to create thread, continuing with temporary');
        }
      }
      
      final response = await ChatService.sendMessage(
        toUserId: widget.recipientUserId,
        content: message,
        messageType: 'text',
        token: authProvider.authToken!,
        currentUserId: authProvider.userProfile!.id,
      );

      if (response['success'] == true && mounted) {
        _messageController.clear();
        
        // Get the thread ID from the response and update it immediately
        if (response['data']?['threadId'] != null) {
          final realThreadId = response['data']['threadId'];
          if (_currentThreadId != realThreadId) {
            _currentThreadId = realThreadId;
            print('ChatScreen: Updated thread ID to real ID: $_currentThreadId');
            
            // Start polling now that we have a real thread ID
            _startMessagePolling();
          }
        }
        
        // Add the new message to the list immediately with proper data from API
        final newMessage = Message(
          id: response['data']?['messageId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          threadId: _currentThreadId ?? '',
          sender: MessageSender(
            id: authProvider.userProfile!.id,
            username: authProvider.userProfile!.username ?? 'Unknown',
            fullName: authProvider.userProfile!.fullName,
            avatar: authProvider.userProfile!.profileImageUrl ?? '',
          ),
          recipient: widget.recipientUserId,
          content: message,
          messageType: 'text',
          isRead: false,
          isDeleted: false,
          reactions: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        print('ChatScreen: Adding new message to local list: ${newMessage.content}');
        print('ChatScreen: Using thread ID: $_currentThreadId');
        setState(() {
          _messages.add(newMessage);
        });
        
        print('ChatScreen: Total messages in list: ${_messages.length}');
        _scrollToBottom();
        
        // Real-time updates disabled to prevent constant refreshing
        
        // No need to reload messages - they are already added to the list
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message sent successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        if (mounted) {
          final errorMessage = response['message'] ?? 'Failed to send message';
          print('ChatScreen: Message send failed: $errorMessage');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('ChatScreen: Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }





  /// Handle scroll events for pagination
  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.minScrollExtent) {
      // User scrolled to top, could load more messages here
      // Only load more messages if we have very few messages
      if (_currentThreadId != null && !_currentThreadId!.startsWith('temp_') && _messages.length < 5) {
        _loadMessages();
      }
    }
  }

  /// Manual refresh method for when user explicitly wants to refresh
  void _manualRefresh() {
    if (_currentThreadId != null && !_currentThreadId!.startsWith('temp_')) {
      print('ChatScreen: Manual refresh requested');
      _loadMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.userProfile;

    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Signup page bg.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Custom App Bar - Glassmorphism style
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () => Navigator.pop(context),
                        ),
                        // Recipient Avatar
                        UserAvatarWidget(
                          avatarUrl: widget.recipientAvatar,
                          userName: widget.recipientUsername,
                          size: 36,
                          borderColor: Colors.white.withOpacity(0.2),
                          borderWidth: 2,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.recipientFullName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                '@${widget.recipientUsername}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black.withOpacity(0.7),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _manualRefresh,
                          icon: const Icon(Icons.refresh, color: Colors.black),
                          tooltip: 'Refresh Messages',
                        ),
                      ],
                    ),
                  ),
                  
                  // Messages List
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.black))
                        : _messages.isEmpty
                            ? _buildEmptyState()
                            : _buildMessagesList(authProvider.userProfile),
                  ),
                  
                  // Message Input
                  _buildMessageInput(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.black.withOpacity(0.8),
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with ${widget.recipientFullName}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black.withOpacity(0.8),
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(UserModel? currentUser) {
    return RefreshIndicator(
      onRefresh: () async {
        _manualRefresh();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          final isCurrentUser = currentUser?.id == message.sender.id;
          
          return _buildMessageBubble(message, isCurrentUser, currentUser);
        },
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isCurrentUser, UserModel? currentUser) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            // Sender Avatar
            UserAvatarWidget(
              avatarUrl: message.sender.avatar,
              userName: message.sender.username,
              size: 32,
              borderColor: Colors.white.withOpacity(0.2),
              borderWidth: 1,
            ),
            const SizedBox(width: 8),
          ],
          
          // Message Content
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isCurrentUser 
                    ? Colors.white.withOpacity(0.2) 
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          message.content,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      // 3-dot menu button
                      GestureDetector(
                        onTap: () => _showMessageOptions(message, isCurrentUser),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.more_vert,
                            size: 18,
                            color: Colors.black.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black.withOpacity(0.7),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            // Current User Avatar
            UserAvatarWidget(
              avatarUrl: currentUser?.profileImageUrl,
              userName: currentUser?.name,
              size: 32,
              borderColor: Colors.white.withOpacity(0.2),
              borderWidth: 1,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Message Input Field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: 'Poppins',
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: Colors.black.withOpacity(0.7),
                    fontSize: 15,
                    fontFamily: 'Poppins',
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Send Button
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _isSending 
                    ? Colors.white.withOpacity(0.3) 
                    : Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.black,
                      size: 24,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}
