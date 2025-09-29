class PrivacySettings {
  final String userId;
  final bool isPrivate;
  final bool allowDirectMessages;
  final bool allowStoryViews;
  final bool allowPostComments;
  final bool allowFollowRequests;
  final DateTime createdAt;
  final DateTime updatedAt;

  PrivacySettings({
    required this.userId,
    required this.isPrivate,
    required this.allowDirectMessages,
    required this.allowStoryViews,
    required this.allowPostComments,
    required this.allowFollowRequests,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      userId: json['userId'] ?? json['_id'] ?? '',
      isPrivate: json['isPrivate'] ?? false,
      allowDirectMessages: json['allowDirectMessages'] ?? true,
      allowStoryViews: json['allowStoryViews'] ?? true,
      allowPostComments: json['allowPostComments'] ?? true,
      allowFollowRequests: json['allowFollowRequests'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'isPrivate': isPrivate,
      'allowDirectMessages': allowDirectMessages,
      'allowStoryViews': allowStoryViews,
      'allowPostComments': allowPostComments,
      'allowFollowRequests': allowFollowRequests,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  PrivacySettings copyWith({
    String? userId,
    bool? isPrivate,
    bool? allowDirectMessages,
    bool? allowStoryViews,
    bool? allowPostComments,
    bool? allowFollowRequests,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PrivacySettings(
      userId: userId ?? this.userId,
      isPrivate: isPrivate ?? this.isPrivate,
      allowDirectMessages: allowDirectMessages ?? this.allowDirectMessages,
      allowStoryViews: allowStoryViews ?? this.allowStoryViews,
      allowPostComments: allowPostComments ?? this.allowPostComments,
      allowFollowRequests: allowFollowRequests ?? this.allowFollowRequests,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
