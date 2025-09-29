import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../screens/notifications_screen.dart';

class NotificationBellWidget extends StatefulWidget {
  final VoidCallback? onPressed;
  final double size;
  final Color? color;

  const NotificationBellWidget({
    super.key,
    this.onPressed,
    this.size = 24.0,
    this.color,
  });

  @override
  State<NotificationBellWidget> createState() => _NotificationBellWidgetState();
}

class _NotificationBellWidgetState extends State<NotificationBellWidget> {
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _hasViewedNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _checkViewedStatus();
  }

  Future<void> _loadUnreadCount() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        final count = await NotificationService.getUnreadCount(token: token);
        if (mounted) {
          setState(() {
            _unreadCount = count;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading unread count: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkViewedStatus() async {
    try {
      final hasViewed = await NotificationService.hasNotificationsBeenViewed();
      if (mounted) {
        setState(() {
          _hasViewedNotifications = hasViewed;
        });
      }
    } catch (e) {
      print('Error checking viewed status: $e');
    }
  }

  void _handleTap() {
    if (widget.onPressed != null) {
      widget.onPressed!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const NotificationsScreen(),
        ),
      ).then((_) {
        // Mark notifications as viewed and refresh count
        NotificationService.markNotificationsAsViewed();
        _loadUnreadCount();
        _checkViewedStatus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Stack(
        children: [
          Icon(
            Icons.notifications_outlined,
            size: widget.size,
            color: widget.color ?? Colors.black,
          ),
          if (_unreadCount > 0 && !_hasViewedNotifications)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.black, // changed to black
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          if (_isLoading)
            Positioned(
              right: 0,
              top: 0,
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.color ?? Colors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
