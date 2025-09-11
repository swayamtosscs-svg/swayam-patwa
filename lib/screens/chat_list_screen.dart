import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../models/chat_thread_model.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import 'search_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with WidgetsBindingObserver {
  List<ChatThread> _chatThreads = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadChatThreads();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh chat threads when app becomes active
    if (state == AppLifecycleState.resumed) {
      _refreshChats();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh chat threads when screen becomes active
    _refreshChats();
  }

  Future<void> _loadChatThreads() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.authToken != null && authProvider.userProfile != null) {
        print('ChatListScreen: Loading chat threads for user: ${authProvider.userProfile!.id}');
        
        // Fetch real chat threads from the API
        final threads = await ChatService.getChatThreads(
          token: authProvider.authToken!,
          currentUserId: authProvider.userProfile!.id,
        );
        
        if (mounted) {
          setState(() {
            _chatThreads = threads;
            _isLoading = false;
          });
          print('ChatListScreen: Loaded ${threads.length} chat threads');
        }
      } else {
        print('ChatListScreen: No auth token or user profile found');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('ChatListScreen: Error loading chat threads: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading chats: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Refresh chat threads (pull to refresh)
  Future<void> _refreshChats() async {
    await _loadChatThreads();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {
              // TODO: Implement more options
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshChats,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _chatThreads.isEmpty
                ? _buildEmptyState()
                : _buildChatList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.message_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with someone',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to search users screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Find People',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      itemCount: _chatThreads.length,
      itemBuilder: (context, index) {
        final thread = _chatThreads[index];
        return _buildChatTile(thread);
      },
    );
  }

  Widget _buildChatTile(ChatThread thread) {
    return ListTile(
      leading: CircleAvatar(
        radius: 25,
        backgroundColor: Colors.grey[300],
        child: thread.avatar.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  thread.avatar,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.grey[600],
                    );
                  },
                ),
              )
            : Icon(
                Icons.person,
                size: 30,
                color: Colors.grey[600],
              ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              thread.fullName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            _getTimeAgo(thread.lastMessageTime),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              thread.lastMessage,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (thread.unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                thread.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () async {
        // Navigate to chat screen and refresh when returning
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              recipientUserId: thread.userId,
              recipientUsername: thread.username,
              recipientFullName: thread.fullName,
              recipientAvatar: thread.avatar,
              threadId: thread.id,
            ),
          ),
        );
        
        // Refresh chat threads when returning from chat
        _refreshChats();
      },
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}




