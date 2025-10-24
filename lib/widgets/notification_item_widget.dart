import 'package:flutter/material.dart';
import '../models/notification_model.dart';

class NotificationItemWidget extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;

  const NotificationItemWidget({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 28,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Notification'),
              content: const Text('Are you sure you want to delete this notification?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        if (onDismissed != null) {
          onDismissed!();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notification icon - purple circle like in the image
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A5ACD), // Purple color like in the image
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: notification.type.toLowerCase() == 'follow' && 
                             notification.followerProfileImage.isNotEmpty
                          ? Image.network(
                              notification.followerProfileImage,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFF6A5ACD),
                                  child: const Center(
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                );
                              },
                            )
                          : const Center(
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Notification content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title - "Notification" like in the image
                        const Text(
                          'Notification',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Message - "Someone started following you" like in the image
                        Text(
                          notification.formattedMessage,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Time and status
                        Row(
                          children: [
                            Text(
                              notification.timeAgo,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            
                            if (!notification.isRead) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Action buttons - checkmark and X like in the image
                  if (notification.type.toLowerCase() == 'friend_request' ||
                      notification.type.toLowerCase() == 'follow')
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      child: Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getActionText(String type) {
    switch (type.toLowerCase()) {
      case 'follow':
        return ' started following you';
      case 'like':
        return ' liked your post';
      case 'comment':
        return ' commented on your post';
      case 'video':
      case 'reel':
        return ' posted a new video';
      case 'share':
        return ' shared your post';
      case 'mention':
        return ' mentioned you';
      case 'friend_request':
        return ' sent you a friend request';
      default:
        return ' sent you a notification';
    }
  }

  Color _getNotificationColor() {
    switch (notification.type.toLowerCase()) {
      case 'like':
        return const Color(0xFFE91E63);
      case 'comment':
        return const Color(0xFF4CAF50);
      case 'follow':
      case 'friend_request':
        return const Color(0xFF2196F3);
      case 'mention':
        return const Color(0xFFFF9800);
      case 'share':
        return const Color(0xFF9C27B0);
      case 'video':
      case 'reel':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF6366F1);
    }
  }
}