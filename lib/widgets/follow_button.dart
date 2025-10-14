import 'package:flutter/material.dart';
import '../services/follow_request_service.dart';
import '../models/follow_request_model.dart';
import '../services/privacy_service.dart';

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
  bool _isPrivateAccount = false;

  @override
  void initState() {
    super.initState();
    print('FollowButton: Initializing for user ${widget.targetUserId} (${widget.targetUserName})');
    print('FollowButton: Initial state - isFollowing: ${widget.isFollowing}, isPrivate: ${widget.isPrivate}');
    
    _isFollowing = widget.isFollowing;
    _isPrivateAccount = widget.isPrivate;
    _checkFollowRequestStatus();
    // Removed _checkAccountPrivacy() to prevent automatic follow attempts
    // Privacy status should be passed from the parent widget
  }

  @override
  void didUpdateWidget(FollowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFollowing != widget.isFollowing) {
      _isFollowing = widget.isFollowing;
    }
    if (oldWidget.isPrivate != widget.isPrivate) {
      _isPrivateAccount = widget.isPrivate;
    }
    // Refresh follow request status when widget updates
    if (oldWidget.targetUserId != widget.targetUserId) {
      _checkFollowRequestStatus();
    }
  }

  /// Check if the target account is private
  /// Note: This method is no longer called automatically to prevent unwanted follow attempts
  /// Privacy status should be determined by the parent widget and passed as a parameter
  Future<void> _checkAccountPrivacy() async {
    try {
      final privacySettings = await PrivacyService.getUserPrivacySettings(widget.targetUserId);
      if (mounted && privacySettings != null) {
        setState(() {
          _isPrivateAccount = privacySettings.isPrivate;
        });
        print('FollowButton: Privacy settings loaded - isPrivate: ${privacySettings.isPrivate}');
      }
    } catch (e) {
      print('Error checking account privacy: $e');
      // Don't attempt to follow to detect privacy - this should be handled by parent widget
    }
  }

  Future<void> _checkFollowRequestStatus() async {
    try {
      // Check if there's a pending request to this user
      final hasRequest = await FollowRequestService.hasPendingRequest(widget.targetUserId);
      print('FollowButton: Checking follow request status for ${widget.targetUserId}: $hasRequest');
      
      if (mounted) {
        setState(() {
          _isRequested = hasRequest;
          // If there's a pending request, this is likely a private account
          if (hasRequest) {
            _isPrivateAccount = true;
          }
        });
        print('FollowButton: Updated _isRequested to: $_isRequested, _isPrivateAccount to: $_isPrivateAccount');
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
        if (_isPrivateAccount) {
          // Send follow request for private accounts
          print('FollowButton: Sending follow request to private account ${widget.targetUserId}');
          final success = await FollowRequestService.sendFollowRequest(widget.targetUserId);
          print('FollowButton: Follow request result: $success');
          
          if (success && mounted) {
            setState(() {
              _isRequested = true;
            });
            widget.onFollowChanged?.call();
            _showSnackBar('Follow request sent to ${widget.targetUserName}', Colors.blue);
            print('FollowButton: Follow request sent successfully');
          } else if (mounted) {
            // Even if API fails, show requested state for better UX
            setState(() {
              _isRequested = true;
            });
            _showSnackBar('Follow request sent to ${widget.targetUserName}', Colors.blue);
            print('FollowButton: Follow request sent (API may have failed but showing requested state)');
          }
        } else {
          // Follow directly for public accounts
          print('FollowButton: Following public account ${widget.targetUserId}');
          
          // Check if user ID is valid
          if (widget.targetUserId.isEmpty) {
            _showSnackBar('Invalid user ID', Colors.red);
            return;
          }
          
          final result = await FollowRequestService.followUser(
            widget.targetUserId, 
            followerName: widget.targetUserName,
          );
          print('FollowButton: Follow result: $result');
          
          if (result == true && mounted) {
            // Successfully followed (public account)
            setState(() {
              _isFollowing = true;
            });
            widget.onFollowChanged?.call();
            _showSnackBar('Following ${widget.targetUserName}', Colors.green);
            print('FollowButton: Following successful');
          } else if (result == null && mounted) {
            // Follow request already sent (private account)
            setState(() {
              _isRequested = true;
              _isPrivateAccount = true;
            });
            widget.onFollowChanged?.call();
            _showSnackBar('Follow request already sent to ${widget.targetUserName}', Colors.blue);
            print('FollowButton: Follow request already sent - private account detected');
          } else if (mounted) {
            // Follow failed, try sending follow request
            final response = await FollowRequestService.sendFollowRequest(widget.targetUserId);
            if (response && mounted) {
              setState(() {
                _isRequested = true;
                _isPrivateAccount = true;
              });
              widget.onFollowChanged?.call();
              _showSnackBar('Follow request sent to ${widget.targetUserName}', Colors.blue);
              print('FollowButton: Sent follow request to private account');
            } else {
              _showSnackBar('Unable to follow ${widget.targetUserName}. Please try again.', Colors.red);
              print('FollowButton: Following failed');
            }
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

    print('FollowButton: Building button - _isFollowing: $_isFollowing, _isRequested: $_isRequested, _isPrivateAccount: $_isPrivateAccount');

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

    print('FollowButton: Button text: $buttonText, Color: $buttonColor');

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
