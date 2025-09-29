import 'package:flutter/material.dart';
import '../services/follow_request_service.dart';
import '../models/follow_request_model.dart';

class FollowButton extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;
  final bool isPrivate;
  final bool isFollowing;
  final VoidCallback? onFollowChanged;

  const FollowButton({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    this.isPrivate = false,
    this.isFollowing = false,
    this.onFollowChanged,
  });

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool _isLoading = false;
  bool _isFollowing = false;
  bool _isRequested = false;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.isFollowing;
    _checkFollowRequestStatus();
  }

  @override
  void didUpdateWidget(FollowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFollowing != widget.isFollowing) {
      _isFollowing = widget.isFollowing;
    }
  }

  Future<void> _checkFollowRequestStatus() async {
    try {
      final hasRequest = await FollowRequestService.hasPendingRequest(widget.targetUserId);
      if (mounted) {
        setState(() {
          _isRequested = hasRequest;
        });
      }
    } catch (e) {
      print('Error checking follow request status: $e');
    }
  }

  Future<void> _handleFollowAction() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isFollowing) {
        // Unfollow user
        final success = await FollowRequestService.unfollowUser(widget.targetUserId);
        if (success && mounted) {
          setState(() {
            _isFollowing = false;
            _isRequested = false;
          });
          widget.onFollowChanged?.call();
          _showSnackBar('Unfollowed ${widget.targetUserName}', Colors.green);
        }
      } else if (_isRequested) {
        // Cancel follow request - we need to find the request ID first
        // For now, we'll use a different approach or implement a method to get request ID
        final success = await FollowRequestService.cancelFollowRequestByUserId(widget.targetUserId);
        if (success && mounted) {
          setState(() {
            _isRequested = false;
          });
          widget.onFollowChanged?.call();
          _showSnackBar('Follow request cancelled', Colors.orange);
        }
      } else {
        // Send follow request or follow directly
        if (widget.isPrivate) {
          // Send follow request for private accounts
          final success = await FollowRequestService.sendFollowRequest(widget.targetUserId);
          if (success && mounted) {
            setState(() {
              _isRequested = true;
            });
            widget.onFollowChanged?.call();
            _showSnackBar('Follow request sent to ${widget.targetUserName}', Colors.blue);
          }
        } else {
          // Follow directly for public accounts
          final success = await FollowRequestService.followUser(
            widget.targetUserId, 
            followerName: widget.targetUserName,
          );
          if (success && mounted) {
            setState(() {
              _isFollowing = true;
            });
            widget.onFollowChanged?.call();
            _showSnackBar('Following ${widget.targetUserName}', Colors.green);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: double.infinity,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    String buttonText;
    Color buttonColor;
    Color textColor = Colors.white;

    if (_isFollowing) {
      buttonText = 'Following';
      buttonColor = Colors.grey[300]!;
      textColor = Colors.black;
    } else if (_isRequested) {
      buttonText = 'Requested';
      buttonColor = Colors.orange;
    } else {
      buttonText = 'Follow';
      buttonColor = const Color(0xFF6366F1);
    }

    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton(
        onPressed: _handleFollowAction,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          buttonText,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}
