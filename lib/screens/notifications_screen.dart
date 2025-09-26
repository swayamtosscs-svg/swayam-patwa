import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import '../screens/user_profile_screen.dart';
import '../utils/responsive_utils.dart';

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
    // Mark all notifications as read when screen is opened
    _markAllAsReadOnOpen();
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
          final index =
              _notifications.indexWhere((n) => n.id == notification.id);
          if (index != -1) {
            _notifications[index] =
                _notifications[index].copyWith(isRead: true);
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
          _notifications = _notifications
              .map((n) => n.copyWith(isRead: true))
              .toList();
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

  Future<void> _markAllAsReadOnOpen() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;

      if (token == null) return;

      // Silently mark all notifications as read when screen opens
      await NotificationService.markAllAsRead(token: token);
    } catch (e) {
      print('Error marking all notifications as read on open: $e');
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
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.black),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Text(
                              'Notifications',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize:
                                    ResponsiveUtils.getResponsiveFontSize(
                                        context, 20),
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (_notifications.any((n) => !n.isRead))
                            IconButton(
                              onPressed: _markAllAsRead,
                              icon: const Icon(Icons.done_all,
                                  color: Colors.black),
                              tooltip: 'Mark all as read',
                            )
                          else
                            const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Main Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _loadNotifications(refresh: true),
                  child: _notifications.isEmpty && !_isLoading
                      ? _buildEmptyState()
                      : _buildNotificationsList(),
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
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 3,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 80,
                  color: Colors.black.withOpacity(0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: TextStyle(
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 20),
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'ll see notifications about likes, comments, and friend requests here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 14),
                    color: Colors.black.withOpacity(0.7),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _notifications.length) {
          if (_hasMore) {
            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  ),
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
    // Custom readable message
    String displayMessage;
    switch (notification.type.toLowerCase()) {
      case 'follow':
        displayMessage =
            "${notification.data?['username'] ?? 'Someone'} started following you";
        break;
      case 'friend_request':
        displayMessage =
            "${notification.data?['username'] ?? 'Someone'} sent you a friend request";
        break;
      case 'like':
        displayMessage =
            "${notification.data?['username'] ?? 'Someone'} liked your post";
        break;
      case 'comment':
        displayMessage =
            "${notification.data?['username'] ?? 'Someone'} commented on your post";
        break;
      case 'mention':
        displayMessage =
            "${notification.data?['username'] ?? 'Someone'} mentioned you in a post";
        break;
      default:
        displayMessage = notification.message.isNotEmpty
            ? notification.message
            : 'You have a new notification';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Color(
                  int.parse(notification.color.replaceAll('#', '0xFF'))),
              child: Text(
                notification.icon,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ),
            title: Text(
              notification.title.isNotEmpty
                  ? notification.title
                  : 'Notification',
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                fontWeight:
                    notification.isRead ? FontWeight.w500 : FontWeight.w600,
                color: Colors.black,
                fontFamily: 'Poppins',
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  displayMessage,
                  style: TextStyle(
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 14),
                    color: Colors.black,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notification.timeAgo,
                  style: TextStyle(
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 12),
                    color: Colors.black,
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
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                  ),
            onTap: () => _handleNotificationTap(notification),
          ),
        ),
      ),
    );
  }
}
