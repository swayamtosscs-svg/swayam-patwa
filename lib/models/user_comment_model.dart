class UserComment {
  final String id;
  final String content;
  final String userId;
  final String postId;
  final String username;
  final String userAvatar;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserComment({
    required this.id,
    required this.content,
    required this.userId,
    required this.postId,
    required this.username,
    required this.userAvatar,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserComment.fromJson(Map<String, dynamic> json) {
    return UserComment(
      id: json['id'] ?? json['_id'] ?? '',
      content: json['content'] ?? '',
      userId: json['userId'] ?? json['user']?['id'] ?? '',
      postId: json['postId'] ?? json['post'] ?? '',
      username: json['user']?['username'] ?? json['username'] ?? 'Unknown',
      userAvatar: json['user']?['avatar'] ?? json['userAvatar'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'userId': userId,
      'postId': postId,
      'username': username,
      'userAvatar': userAvatar,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class UserCommentResponse {
  final bool success;
  final String message;
  final List<UserComment> comments;
  final Map<String, dynamic> pagination;

  UserCommentResponse({
    required this.success,
    required this.message,
    required this.comments,
    required this.pagination,
  });

  factory UserCommentResponse.fromJson(Map<String, dynamic> json) {
    List<UserComment> commentsList = [];
    
    if (json['data']?['comments'] != null) {
      commentsList = (json['data']['comments'] as List)
          .map((comment) => UserComment.fromJson(comment))
          .toList();
    } else if (json['comments'] != null) {
      commentsList = (json['comments'] as List)
          .map((comment) => UserComment.fromJson(comment))
          .toList();
    }

    return UserCommentResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? 'Comments loaded successfully',
      comments: commentsList,
      pagination: json['data']?['pagination'] ?? json['pagination'] ?? {
        'currentPage': 1,
        'totalPages': 0,
        'totalItems': 0,
        'itemsPerPage': 20,
      },
    );
  }
}
