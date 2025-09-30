import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../models/chat_thread_model.dart';
import '../services/chat_service.dart';
import '../widgets/user_avatar_widget.dart';
import '../widgets/dp_widget.dart';
import 'chat_screen.dart';
import 'search_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with WidgetsBindingObserver {
  List<ChatThread> _chatThreads = [];
  List<ChatThread> _filteredChatThreads = [];
  bool _isLoading = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadChatThreads();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
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
        
        // Use the new initialization method that handles both local and API conversations
        final threads = await ChatService.initializeConversations(
          currentUserId: authProvider.userProfile!.id,
          token: authProvider.authToken!,
        );
        
        if (mounted) {
          setState(() {
            _chatThreads = threads;
            _filteredChatThreads = threads;
            _isLoading = false;
          });
          print('ChatListScreen: Loaded ${threads.length} total chat threads');
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

  /// Filter chat threads based on search query
  void _filterChats(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredChatThreads = _chatThreads;
      } else {
        _filteredChatThreads = _chatThreads.where((thread) {
          return thread.fullName.toLowerCase().contains(query.toLowerCase()) ||
                 thread.username.toLowerCase().contains(query.toLowerCase()) ||
                 thread.lastMessage.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  /// Toggle search mode
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filteredChatThreads = _chatThreads;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
              // Custom App Bar
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
                child: _isSearching ? _buildSearchBar() : _buildNormalHeader(),
              ),
              // Messages Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshChats,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.black))
                      : _filteredChatThreads.isEmpty
                          ? _buildEmptyState()
                          : _buildChatList(),
                ),
              ),
            ],
          ),
        ),
      ),
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
              Icons.message_outlined,
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
              'Start a conversation with someone',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black.withOpacity(0.8),
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
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
                backgroundColor: Colors.white.withOpacity(0.2),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: const Text(
                'Find People',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredChatThreads.length,
      itemBuilder: (context, index) {
        final thread = _filteredChatThreads[index];
        return _buildChatTile(thread);
      },
    );
  }

  Widget _buildChatTile(ChatThread thread) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: DPWidget(
          currentImageUrl: thread.avatar,
          userId: thread.userId,
          token: Provider.of<AuthProvider>(context, listen: false).authToken ?? '',
          userName: thread.fullName,
          onImageChanged: (String newImageUrl) {
            // Update the avatar if needed
            print('ChatListScreen: Avatar changed to: $newImageUrl');
          },
          size: 50,
          borderColor: Colors.white.withOpacity(0.2),
          showEditButton: false, // Don't show edit button for other users' profiles
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                thread.fullName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black,
                  fontFamily: 'Poppins',
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _getTimeAgo(thread.lastMessageTime),
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withOpacity(0.7),
                fontFamily: 'Poppins',
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
                  color: Colors.black.withOpacity(0.8),
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (thread.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  thread.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
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
      ),
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

  Widget _buildNormalHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        const Expanded(
          child: Text(
            'Messages',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black),
          onPressed: _toggleSearch,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _toggleSearch,
        ),
        Expanded(
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'Search messages...',
              hintStyle: TextStyle(
                color: Colors.black.withOpacity(0.6),
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: _filterChats,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.black),
          onPressed: () {
            _searchController.clear();
            _filterChats('');
          },
        ),
      ],
    );
  }
}




