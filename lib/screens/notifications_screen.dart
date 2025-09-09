import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import '../screens/user_profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to view notifications'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final notifications = await NotificationService.getNotifications(
        token: token,
        page: _currentPage,
        limit: _pageSize,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _notifications = notifications;
          } else {
            _notifications.addAll(notifications);
          }
          _hasMore = notifications.length == _pageSize;
          _currentPage++;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;
      
      if (token == null) return;

      final success = await NotificationService.markAsRead(
        notificationId: notification.id,
        token: token,
      );

      if (success && mounted) {
        setState(() {
          final index = _notifications.indexWhere((n) => n.id == notification.id);
          if (index != -1) {
            _notifications[index] = _notifications[index].copyWith(isRead: true);
          }
        });
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;
      
      if (token == null) return;

      final success = await NotificationService.markAllAsRead(token: token);

      if (success && mounted) {
        setState(() {
          _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking all as read: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read first
    _markAsRead(notification);

    // Handle different notification types
    switch (notification.type.toLowerCase()) {
      case 'follow':
      case 'friend_request':
        // Navigate to user profile
        if (notification.targetId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfileScreen(
                userId: notification.targetId!,
                username: notification.data?['username'] ?? 'User',
                fullName: notification.data?['fullName'] ?? 'User',
                avatar: notification.data?['avatar'] ?? '',
                bio: notification.data?['bio'] ?? '',
                followersCount: notification.data?['followersCount'] ?? 0,
                followingCount: notification.data?['followingCount'] ?? 0,
                postsCount: notification.data?['postsCount'] ?? 0,
                isPrivate: notification.data?['isPrivate'] ?? false,
              ),
            ),
          );
        }
        break;
      case 'like':
      case 'comment':
      case 'mention':
        // Navigate to post view
        if (notification.targetId != null) {
          // TODO: Navigate to post view screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Navigate to ${notification.type}'),
              backgroundColor: Colors.blue,
            ),
          );
        }
        break;
      default:
        // Show notification details
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(notification.message),
            backgroundColor: Colors.blue,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_notifications.any((n) => !n.isRead))
            IconButton(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all),
              tooltip: 'Mark all as read',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadNotifications(refresh: true),
        child: _notifications.isEmpty && !_isLoading
            ? _buildEmptyState()
            : _buildNotificationsList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see notifications about likes, comments, and friend requests here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _notifications.length) {
          // Show load more indicator
          if (_hasMore) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        final notification = _notifications[index];
        return _buildNotificationItem(notification);
      },
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Color(int.parse(notification.color.replaceAll('#', '0xFF'))),
          child: Text(
            notification.icon,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
            color: notification.isRead ? Colors.grey[600] : Colors.black,
            fontFamily: 'Poppins',
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              notification.timeAgo,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF6366F1),
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () => _handleNotificationTap(notification),
      ),
    );
  }
}
