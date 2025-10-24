import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../widgets/notification_item_widget.dart';
import 'follow_requests_screen.dart';
import 'test_follow_request_demo.dart';
import 'test_rupesh_follow_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<NotificationModel> _allNotifications = [];
  List<NotificationModel> _unreadNotifications = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotifications();
    _markNotificationsAsViewed();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _markNotificationsAsViewed() async {
    try {
      await NotificationService.markNotificationsAsViewed();
    } catch (e) {
      print('Error marking notifications as viewed: $e');
    }
  }

  Future<void> _loadNotifications({bool loadMore = false}) async {
    if (_isLoading && !loadMore) return;
    if (_isLoadingMore && loadMore) return;

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _currentPage = 1;
        _hasMoreData = true;
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final page = loadMore ? _currentPage + 1 : 1;

      final allNotifications = await NotificationService.getNotifications(
        token: token,
        page: page,
        limit: _pageSize,
      );

      final unreadNotifications =
          await NotificationService.getUnreadNotifications(
        token: token,
        page: page,
        limit: _pageSize,
      );

      if (mounted) {
        setState(() {
          if (loadMore) {
            _allNotifications.addAll(allNotifications);
            _unreadNotifications.addAll(unreadNotifications);
            _currentPage = page;
          } else {
            _allNotifications = allNotifications;
            _unreadNotifications = unreadNotifications;
            _currentPage = 1;
          }

          _hasMoreData = allNotifications.length == _pageSize;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading notifications: $e',
              style: const TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final success = await NotificationService.markAllAsRead(token: token);
      if (success && mounted) {
        await _loadNotifications();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'All notifications marked as read',
              style: TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error marking notifications as read: $e',
              style: TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onNotificationTapped(NotificationModel notification) async {
    if (!notification.isRead) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          await NotificationService.markAsRead(
            notificationId: notification.id,
            token: token,
          );

          setState(() {
            final index =
                _allNotifications.indexWhere((n) => n.id == notification.id);
            if (index != -1) {
              _allNotifications[index] = notification.copyWith(isRead: true);
            }

            _unreadNotifications.removeWhere((n) => n.id == notification.id);
          });
        }
      } catch (e) {
        print('Error marking notification as read: $e');
      }
    }
  }

  Future<void> _onNotificationDeleted(NotificationModel notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        final success = await NotificationService.deleteNotification(
          notificationId: notification.id,
          token: token,
        );

        if (success && mounted) {
          setState(() {
            _allNotifications.removeWhere((n) => n.id == notification.id);
            _unreadNotifications.removeWhere((n) => n.id == notification.id);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Notification deleted',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Failed to delete notification',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        print('Error deleting notification: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error deleting notification: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _unreadNotifications.length;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5), // Light beige/off-white like the body
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6A5ACD), // Purple color like in the image
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: _markAllAsRead,
            icon: const Icon(Icons.done_all, color: Colors.black),
            tooltip: 'Mark all as read',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Unread'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Signup page bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Blur effect overlay
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
              child: Container(
                color: Colors.transparent,
              ),
            ),
            // Main content
            TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationsList(_allNotifications),
                _buildNotificationsList(_unreadNotifications),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(List<NotificationModel> notifications) {
    if (_isLoading && notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.black,
        ),
      );
    }

    if (notifications.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.black54,
            ),
            SizedBox(height: 16),
            Text(
              'No notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'When you get notifications, they\'ll appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadNotifications(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == notifications.length) {
            if (_isLoadingMore) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    color: Colors.black,
                  ),
                ),
              );
            } else if (_hasMoreData) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadNotifications(loadMore: true);
              });
              return const SizedBox.shrink();
            } else {
              return const SizedBox.shrink();
            }
          }

          final notification = notifications[index];
          return NotificationItemWidget(
            notification: notification,
            onTap: () => _onNotificationTapped(notification),
            onDismissed: () => _onNotificationDeleted(notification),
          );
        },
      ),
    );
  }
}
