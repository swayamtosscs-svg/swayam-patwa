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
    try {
      // Parse date with error handling
      DateTime createdAt;
      try {
        createdAt = json['createdAt'] != null 
            ? DateTime.parse(json['createdAt'])
            : (json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now());
      } catch (e) {
        createdAt = DateTime.now();
      }
      
      DateTime? updatedAt;
      try {
        if (json['updatedAt'] != null) {
          updatedAt = DateTime.parse(json['updatedAt']);
        } else if (json['updated_at'] != null) {
          updatedAt = DateTime.parse(json['updated_at']);
        }
      } catch (e) {
        updatedAt = null;
      }
      
      return UserComment(
        id: json['id'] ?? json['_id'] ?? json['commentId'] ?? '',
        content: json['content'] ?? json['comment'] ?? json['text'] ?? '',
        userId: json['userId'] ?? json['user']?['id'] ?? json['user']?['_id'] ?? json['author']?['_id'] ?? json['author']?['id'] ?? '',
        postId: json['postId'] ?? json['post'] ?? json['postId'] ?? '',
        username: json['userName'] ?? json['user']?['name'] ?? json['user']?['fullName'] ?? json['user']?['username'] ?? json['author']?['name'] ?? json['author']?['fullName'] ?? json['author']?['username'] ?? json['username'] ?? 'User',
        userAvatar: json['user']?['avatar'] ?? json['user']?['profilePicture'] ?? json['userAvatar'] ?? json['author']?['avatar'] ?? '',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      print('UserComment: Error parsing comment: $e');
      print('UserComment: Comment data: $json');
      rethrow;
    }
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
    try {
      List<dynamic> commentsData = [];
      Map<String, dynamic>? paginationData;
      
      // Handle different response structures (same as baba comments)
      // Check if comments are directly in the root
      if (json['comments'] != null && json['comments'] is List) {
        commentsData = json['comments'];
      }
      // Check if comments are in data array
      else if (json['data'] != null) {
        if (json['data'] is List) {
          // If data is directly a list of comments
          commentsData = json['data'];
        } else if (json['data'] is Map<String, dynamic>) {
          // If data is an object with comments property
          commentsData = json['data']['comments'] ?? [];
          paginationData = json['data']['pagination'];
        }
      }
      // Check for new API format - comments might be in 'result' or 'items'
      else if (json['result'] != null && json['result'] is List) {
        commentsData = json['result'];
      }
      else if (json['items'] != null && json['items'] is List) {
        commentsData = json['items'];
      }
      // Check if the entire response is an array of comments
      else if (json is List) {
        commentsData = json as List<dynamic>;
      }
      
      print('UserCommentResponse: Found ${commentsData.length} comments in response');
      
      return UserCommentResponse(
        success: json['success'] ?? json['status'] == 'success' ?? true,
        message: json['message'] ?? json['error'] ?? 'Comments loaded successfully',
        comments: commentsData
            .map((commentJson) {
              try {
                return UserComment.fromJson(commentJson);
              } catch (e) {
                print('UserCommentResponse: Error parsing comment: $e');
                print('UserCommentResponse: Comment data: $commentJson');
                return null;
              }
            })
            .where((comment) => comment != null)
            .cast<UserComment>()
            .toList(),
        pagination: paginationData ?? json['pagination'] ?? {
          'currentPage': 1,
          'totalPages': 0,
          'totalItems': 0,
          'itemsPerPage': 20,
        },
      );
    } catch (e) {
      print('UserCommentResponse: Error parsing response: $e');
      print('UserCommentResponse: Response data: $json');
      return UserCommentResponse(
        success: false,
        message: 'Error parsing response: $e',
        comments: [],
        pagination: {
          'currentPage': 1,
          'totalPages': 0,
          'totalItems': 0,
          'itemsPerPage': 20,
        },
      );
    }
  }
}

