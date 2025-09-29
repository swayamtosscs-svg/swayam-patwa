import 'package:flutter/material.dart';
import '../models/follow_request_model.dart';
import '../utils/avatar_utils.dart';

class FollowRequestItemWidget extends StatelessWidget {
  final FollowRequest request;
  final bool isPending;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;

  const FollowRequestItemWidget({
    super.key,
    required this.request,
    required this.isPending,
    this.onAccept,
    this.onReject,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final user = isPending ? request.fromUsername : request.toUsername;
    final avatar = isPending ? request.fromUserAvatar : null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // User avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4A2C2A), width: 2),
              ),
              child: ClipOval(
                child: avatar != null && AvatarUtils.isValidAvatarUrl(avatar)
                    ? Image.network(
                        AvatarUtils.getAbsoluteAvatarUrl(avatar),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return AvatarUtils.buildDefaultAvatar(
                            name: user,
                            size: 56,
                            borderColor: const Color(0xFF4A2C2A),
                            borderWidth: 2,
                          );
                        },
                      )
                    : AvatarUtils.buildDefaultAvatar(
                        name: user,
                        size: 56,
                        borderColor: const Color(0xFF4A2C2A),
                        borderWidth: 2,
                      ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    _getRequestText(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    _getTimeAgo(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            
            // Action buttons
            if (isPending) ...[
              // Accept button
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: IconButton(
                  onPressed: onAccept,
                  icon: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Reject button
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(18),
                ),
                child: IconButton(
                  onPressed: onReject,
                  icon: const Icon(
                    Icons.close,
                    color: Colors.black54,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ] else ...[
              // Cancel button for sent requests
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.orange[300],
                  borderRadius: BorderRadius.circular(18),
                ),
                child: IconButton(
                  onPressed: onCancel,
                  icon: const Icon(
                    Icons.cancel_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getRequestText() {
    if (isPending) {
      return 'wants to follow you';
    } else {
      switch (request.status) {
        case 'pending':
          return 'Follow request sent';
        case 'accepted':
          return 'Follow request accepted';
        case 'rejected':
          return 'Follow request rejected';
        default:
          return 'Follow request sent';
      }
    }
  }

  String _getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(request.createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
