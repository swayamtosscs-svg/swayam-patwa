import 'package:flutter/material.dart';
import '../models/baba_page_comment_model.dart';
import '../services/baba_comment_service.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import 'package:provider/provider.dart';

class BabaCommentDialog extends StatefulWidget {
  final String postId;
  final String babaPageId;
  final bool isReel;
  final VoidCallback? onCommentAdded;

  const BabaCommentDialog({
    super.key,
    required this.postId,
    required this.babaPageId,
    this.isReel = false,
    this.onCommentAdded,
  });

  @override
  State<BabaCommentDialog> createState() => _BabaCommentDialogState();
}

class _BabaCommentDialogState extends State<BabaCommentDialog> {
  final TextEditingController _commentController = TextEditingController();
  List<BabaPageComment> _comments = [];
  bool _isLoading = false;
  bool _isAddingComment = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;

      // Debug comment endpoints
      if (!widget.isReel) {
        await BabaCommentService.debugCommentEndpoints(
          postId: widget.postId,
          babaPageId: widget.babaPageId,
          token: token,
        );
      }

      final response = widget.isReel
          ? await BabaCommentService.getReelComments(
              reelId: widget.postId,
              babaPageId: widget.babaPageId,
              token: token,
            )
          : await BabaCommentService.getComments(
              postId: widget.postId,
              babaPageId: widget.babaPageId,
              token: token,
            );

      if (response.success) {
        print('BabaCommentDialog: Response successful, comments count: ${response.comments.length}');
        setState(() {
          _comments = response.comments;
          _isLoading = false;
        });
        print('BabaCommentDialog: Successfully loaded ${_comments.length} comments');
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
        print('BabaCommentDialog: Failed to load comments: ${response.message}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading comments: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userProfile?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to add comments'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isAddingComment = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;

      final response = widget.isReel
          ? await BabaCommentService.addReelComment(
              userId: userId,
              reelId: widget.postId,
              babaPageId: widget.babaPageId,
              content: content,
              token: token,
            )
          : await BabaCommentService.addCommentWithFallback(
              userId: userId,
              postId: widget.postId,
              babaPageId: widget.babaPageId,
              content: content,
              token: token,
            );

      if (response != null && response['success'] == true) {
        print('BabaCommentDialog: Comment added successfully, refreshing comments...');
        setState(() {
          _commentController.clear();
        });
        await _loadComments(); // Refresh comments
        widget.onCommentAdded?.call(); // Notify parent
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        print('BabaCommentDialog: Comments refreshed, total comments: ${_comments.length}');
      } else {
        String errorMessage = response?['message'] ?? 'Failed to add comment';
        
        // Handle specific error cases
        if (errorMessage.contains('User not found')) {
          final userName = authProvider.userProfile?.name ?? authProvider.userProfile?.username ?? 'User';
          errorMessage = 'Sorry $userName, your account needs to be registered in the comment system. Please contact support or try again later.';
        } else if (errorMessage.contains('Post not found')) {
          errorMessage = 'This post is no longer available for comments.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding comment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isAddingComment = false;
      });
    }
  }

  Future<void> _deleteComment(BabaPageComment comment) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userProfile?.id;
    final token = authProvider.authToken;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to delete comments'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
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
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await BabaCommentService.deleteComment(
        commentId: comment.id,
        userId: userId,
        token: token,
      );

      if (response != null && response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadComments(); // Refresh comments
        widget.onCommentAdded?.call(); // Notify parent
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response?['message'] ?? 'Failed to delete comment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting comment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.comment,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Comments (${_comments.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Comments List
            Expanded(
              child: _buildCommentsList(),
            ),
            
            // Add Comment Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontFamily: 'Poppins',
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(
                            color: Colors.grey[300]!,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(
                            color: Colors.grey[300]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _addComment(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _isAddingComment ? null : _addComment,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isAddingComment 
                            ? Colors.grey[400] 
                            : AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: _isAddingComment
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadComments,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.comment_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No comments yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to comment on this post',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        final comment = _comments[index];
        return _buildCommentItem(comment);
      },
    );
  }

  Widget _buildCommentItem(BabaPageComment comment) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userProfile?.id;
    final isOwnComment = _isOwnComment(comment, currentUserId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Icon(
                  Icons.person,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getDisplayName(comment, authProvider),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              Text(
                _formatCommentDate(comment.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontFamily: 'Poppins',
                ),
              ),
              if (isOwnComment) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _deleteComment(comment),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.content,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
              fontFamily: 'Poppins',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCommentDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

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

  String _getDisplayName(BabaPageComment comment, AuthProvider authProvider) {
    final currentUserId = authProvider.userProfile?.id;
    
    // Check if this comment belongs to the current user (considering the mapping)
    if (comment.userId == '68b53b03f09b98a6dcded481' && currentUserId == '68c98967a921a001da9787b3') {
      // This is a comment from the mapped user, show current user's name
      return authProvider.userProfile?.name ?? authProvider.userProfile?.username ?? 'You';
    } else if (comment.userId == currentUserId) {
      // This is a direct comment from current user
      return authProvider.userProfile?.name ?? authProvider.userProfile?.username ?? 'You';
    } else {
      // This is a comment from another user
      return comment.userName ?? 'Anonymous';
    }
  }

  bool _isOwnComment(BabaPageComment comment, String? currentUserId) {
    if (currentUserId == null) return false;
    
    // Check if this comment belongs to the current user (considering the mapping)
    if (comment.userId == '68b53b03f09b98a6dcded481' && currentUserId == '68c98967a921a001da9787b3') {
      // This is a comment from the mapped user, treat as own comment
      return true;
    } else if (comment.userId == currentUserId) {
      // This is a direct comment from current user
      return true;
    } else {
      // This is a comment from another user
      return false;
    }
  }
}