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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Set the thread ID if provided
    _currentThreadId = widget.threadId;
    _loadMessages();
    
    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);
    
    // Start real-time updates only after we have a real thread ID
    // This will be handled in _sendMessage when the first message is sent
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only refresh messages if we haven't refreshed recently
    if (_currentThreadId != null && !_currentThreadId!.startsWith('temp_')) {
      final now = DateTime.now();
      if (_lastRefreshTime == null || now.difference(_lastRefreshTime!).inSeconds >= 30) {
        _loadMessages();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh messages when app becomes active, but only if we haven't refreshed recently
    if (state == AppLifecycleState.resumed && _currentThreadId != null && !_currentThreadId!.startsWith('temp_')) {
      final now = DateTime.now();
      if (_lastRefreshTime == null || now.difference(_lastRefreshTime!).inSeconds >= 30) {
        _loadMessages();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    // Stop real-time updates
    _lastRefreshTime = null;
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // If we have a real thread ID (not temp), load messages from that thread
      if (_currentThreadId != null && !_currentThreadId!.startsWith('temp_')) {
        print('ChatScreen: Loading messages for real thread: $_currentThreadId');
        print('ChatScreen: Current messages count before loading: ${_messages.length}');
        
        final messages = await ChatService.getMessagesByThreadId(
          threadId: _currentThreadId!,
          token: authProvider.authToken!,
        );
        
        if (mounted) {
          setState(() {
            // Store existing messages to preserve them
            final existingMessages = List<Message>.from(_messages);
            
            // Merge new messages with existing ones, avoiding duplicates
            final existingMessageIds = existingMessages.map((m) => m.id).toSet();
            final newMessages = messages.where((m) => !existingMessageIds.contains(m.id)).toList();
            
            // Start with existing messages and add new ones
            _messages = existingMessages;
            _messages.addAll(newMessages);
            
            // Sort messages by creation time to maintain chronological order
            _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            
            _isLoading = false;
          });
          _scrollToBottom();
          _lastRefreshTime = DateTime.now();
          print('ChatScreen: Loaded ${messages.length} messages from API, total messages: ${_messages.length}');
        }
      } else if (_currentThreadId != null && _currentThreadId!.startsWith('temp_')) {
        // We have a temporary thread ID, just show the local messages
        print('ChatScreen: Using temporary thread ID, keeping local messages');
        setState(() {
          _isLoading = false;
        });
      } else {
        // If no thread ID, try to find existing conversation with this user
        print('ChatScreen: No thread ID provided, checking for existing conversation with ${widget.recipientUserId}');
        
        final allThreads = await ChatService.getAllConversations(
          token: authProvider.authToken!,
          currentUserId: authProvider.userProfile!.id,
        );
        
        // Look for existing thread with this user
        final existingThread = allThreads.firstWhere(
          (thread) => thread.userId == widget.recipientUserId,
          orElse: () => ChatThread(
            id: '',
            userId: '',
            username: '',
            fullName: '',
            avatar: '',
            lastMessage: '',
            lastMessageTime: DateTime.now(),
            unreadCount: 0,
          ),
        );
        
        if (existingThread.id.isNotEmpty) {
          // Found existing conversation
          _currentThreadId = existingThread.id;
          print('ChatScreen: Found existing thread: $_currentThreadId');
          
          // Load messages from the existing thread
          final messages = await ChatService.getMessagesByThreadId(
            threadId: _currentThreadId!,
            token: authProvider.authToken!,
          );
          
          if (mounted) {
            setState(() {
              // Merge new messages with existing ones, avoiding duplicates
              final existingMessageIds = _messages.map((m) => m.id).toSet();
              final newMessages = messages.where((m) => !existingMessageIds.contains(m.id)).toList();
              
              // Add new messages to the existing list
              _messages.addAll(newMessages);
              
              // Sort messages by creation time to maintain chronological order
              _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
              
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
          // No existing conversation, start fresh
          print('ChatScreen: No existing conversation found, starting fresh');
          setState(() {
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
      if (_currentThreadId == null) {
        print('ChatScreen: No thread ID, creating new chat thread');
        final threadResponse = await ChatService.createChatThread(
          toUserId: widget.recipientUserId,
          token: authProvider.authToken!,
        );
        
        if (threadResponse['success'] == true && threadResponse['data']?['threadId'] != null) {
          _currentThreadId = threadResponse['data']['threadId'];
          print('ChatScreen: Created new thread with ID: $_currentThreadId');
        } else {
          print('ChatScreen: Failed to create thread: ${threadResponse['message']}');
          // Continue anyway, the message API might create the thread
        }
      }
      
      final response = await ChatService.sendMessage(
        toUserId: widget.recipientUserId,
        content: message,
        messageType: 'text',
        token: authProvider.authToken!,
      );

      if (response['success'] == true && mounted) {
        _messageController.clear();
        
        // Get the thread ID from the response and update it immediately
        if (response['data']?['threadId'] != null) {
          final realThreadId = response['data']['threadId'];
          if (_currentThreadId != realThreadId) {
            _currentThreadId = realThreadId;
            print('ChatScreen: Updated thread ID to real ID: $_currentThreadId');
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
        
        // Start real-time updates only if not already running
        if (_currentThreadId != null && !_currentThreadId!.startsWith('temp_')) {
          // Only start real-time updates if we haven't started them yet
          if (_lastRefreshTime == null) {
            _startRealTimeUpdates();
          }
        }
        
        // Reload messages after a short delay to ensure consistency
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _currentThreadId != null && !_currentThreadId!.startsWith('temp_')) {
            print('ChatScreen: Reloading messages after delay with real thread ID: $_currentThreadId');
            _loadMessages(); // This now uses merging logic
          }
        });
        
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
      // Only refresh if we haven't refreshed recently
      if (_currentThreadId != null && !_currentThreadId!.startsWith('temp_')) {
        final now = DateTime.now();
        if (_lastRefreshTime == null || now.difference(_lastRefreshTime!).inSeconds >= 15) {
          _loadMessages();
        }
      }
    }
  }

  /// Refresh messages periodically for real-time updates
  void _startRealTimeUpdates() {
    // Only start real-time updates if we have a real thread ID and the screen is active
    if (!mounted || _currentThreadId == null || _currentThreadId!.startsWith('temp_')) {
      return;
    }
    
    // Check if the screen is still active before refreshing
    if (mounted && _currentThreadId != null && !_currentThreadId!.startsWith('temp_')) {
      print('ChatScreen: Refreshing messages for real thread: $_currentThreadId');
      
      // Only refresh if we haven't refreshed recently (within last 10 seconds)
      final now = DateTime.now();
      if (_lastRefreshTime == null || now.difference(_lastRefreshTime!).inSeconds >= 10) {
        _loadMessages();
        _lastRefreshTime = now;
      } else {
        print('ChatScreen: Skipping refresh - last refresh was ${now.difference(_lastRefreshTime!).inSeconds} seconds ago');
      }
      
      // Schedule next refresh only if screen is still mounted and active
      if (mounted) {
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted) {
            _startRealTimeUpdates();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.userProfile;

    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: themeService.backgroundColor,
          appBar: AppBar(
        backgroundColor: themeService.surfaceColor,
        foregroundColor: themeService.onSurfaceColor,
        title: Row(
          children: [
            // Recipient Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: themeService.primaryColor,
              child: widget.recipientAvatar != null && widget.recipientAvatar!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        widget.recipientAvatar!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Text(
                          widget.recipientUsername[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      widget.recipientUsername[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.recipientFullName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: themeService.onSurfaceColor,
                  ),
                ),
                Text(
                  '@${widget.recipientUsername}',
                  style: TextStyle(
                    fontSize: 12,
                    color: themeService.onSurfaceColor.withOpacity(0.6),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadMessages,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessagesList(authProvider.userProfile),
          ),
          
          // Message Input
          _buildMessageInput(),
        ],
      ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with ${widget.recipientFullName}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(UserModel? currentUser) {
    return RefreshIndicator(
      onRefresh: _loadMessages,
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
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor,
              child: message.sender.avatar.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        message.sender.avatar,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Text(
                          message.sender.username[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      message.sender.username[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
          ],
          
          // Message Content
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isCurrentUser ? AppTheme.primaryColor : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
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
                          style: TextStyle(
                            fontSize: 14,
                            color: isCurrentUser ? Colors.white : AppTheme.textPrimary,
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
                            color: isCurrentUser ? Colors.white70 : Colors.grey[600],
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
                      color: isCurrentUser ? Colors.white70 : Colors.grey[500],
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
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF10B981),
              child: currentUser?.profileImageUrl != null && currentUser!.profileImageUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        currentUser.profileImageUrl!,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Text(
                          currentUser.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      currentUser?.name[0].toUpperCase() ?? 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Message Input Field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontFamily: 'Poppins',
                  ),
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
                color: _isSending ? Colors.grey : AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
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
