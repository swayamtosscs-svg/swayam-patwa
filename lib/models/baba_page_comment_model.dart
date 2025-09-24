class BabaPageComment {
  final String id;
  final String? userId;
  final String? userName;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  BabaPageComment({
    required this.id,
    this.userId,
    this.userName,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BabaPageComment.fromJson(Map<String, dynamic> json) {
    try {
      return BabaPageComment(
        id: json['_id'] ?? json['id'] ?? json['commentId'] ?? '',
        userId: json['userId'] ?? json['user']?['id'] ?? json['user']?['_id'] ?? json['user']?['userId'] ?? json['author']?['_id'] ?? json['author']?['id'],
        userName: json['user']?['name'] ?? json['user']?['fullName'] ?? json['user']?['username'] ?? json['author']?['name'] ?? json['author']?['fullName'] ?? json['author']?['username'] ?? 'Anonymous',
        content: json['content'] ?? json['comment'] ?? json['text'] ?? '',
        createdAt: _parseDateTime(json['createdAt'] ?? json['created_at'] ?? json['timestamp']),
        updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at'] ?? json['modifiedAt']),
      );
    } catch (e) {
      print('BabaPageComment: Error parsing comment: $e');
      print('BabaPageComment: Comment data: $json');
      rethrow;
    }
  }

  static DateTime _parseDateTime(dynamic dateValue) {
    try {
      if (dateValue == null) {
        return DateTime.now();
      }
      if (dateValue is String) {
        return DateTime.parse(dateValue);
      }
      return DateTime.now();
    } catch (e) {
      print('BabaPageComment: Error parsing date: $e');
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BabaPageComment copyWith({
    String? id,
    String? userId,
    String? userName,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BabaPageComment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BabaPageCommentResponse {
  final bool success;
  final String message;
  final List<BabaPageComment> comments;
  final BabaPageCommentPagination? pagination;

  BabaPageCommentResponse({
    required this.success,
    required this.message,
    required this.comments,
    this.pagination,
  });

  factory BabaPageCommentResponse.fromJson(Map<String, dynamic> json) {
    try {
      // Handle different response structures
      List<dynamic> commentsData = [];
      Map<String, dynamic>? paginationData;
      
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
      
      print('BabaPageCommentResponse: Found ${commentsData.length} comments in response');
      
      return BabaPageCommentResponse(
        success: json['success'] ?? json['status'] == 'success' ?? true, // Default to true if not specified
        message: json['message'] ?? json['error'] ?? '',
        comments: commentsData
            .map((commentJson) {
              try {
                return BabaPageComment.fromJson(commentJson);
              } catch (e) {
                print('BabaPageCommentResponse: Error parsing comment: $e');
                print('BabaPageCommentResponse: Comment data: $commentJson');
                return null;
              }
            })
            .where((comment) => comment != null)
            .cast<BabaPageComment>()
            .toList(),
        pagination: paginationData != null
            ? BabaPageCommentPagination.fromJson(paginationData)
            : null,
      );
    } catch (e) {
      print('BabaPageCommentResponse: Error parsing response: $e');
      print('BabaPageCommentResponse: Response data: $json');
      return BabaPageCommentResponse(
        success: false,
        message: 'Error parsing response: $e',
        comments: [],
      );
    }
  }
}

class BabaPageCommentPagination {
  final int currentPage;
  final int totalPages;
  final int totalComments;
  final int commentsPerPage;

  BabaPageCommentPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalComments,
    required this.commentsPerPage,
  });

  factory BabaPageCommentPagination.fromJson(Map<String, dynamic> json) {
    return BabaPageCommentPagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalComments: json['totalComments'] ?? 0,
      commentsPerPage: json['commentsPerPage'] ?? 10,
    );
  }
}
