class FollowRequest {
  final String id;
  final String fromUserId;
  final String fromUsername;
  final String? fromUserAvatar;
  final String toUserId;
  final String toUsername;
  final DateTime createdAt;
  final String status; // 'pending', 'accepted', 'rejected'

  FollowRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUsername,
    this.fromUserAvatar,
    required this.toUserId,
    required this.toUsername,
    required this.createdAt,
    required this.status,
  });

  factory FollowRequest.fromMap(Map<String, dynamic> data) {
    return FollowRequest(
      id: data['_id'] ?? data['id'] ?? '',
      fromUserId: data['fromUser']?['_id'] ?? data['fromUserId'] ?? '',
      fromUsername: data['fromUser']?['username'] ?? data['fromUsername'] ?? '',
      fromUserAvatar: data['fromUser']?['avatar'] ?? data['fromUserAvatar'],
      toUserId: data['toUser']?['_id'] ?? data['toUserId'] ?? '',
      toUsername: data['toUser']?['username'] ?? data['toUsername'] ?? '',
      createdAt: data['createdAt'] != null 
          ? DateTime.parse(data['createdAt']) 
          : DateTime.now(),
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'fromUsername': fromUsername,
      'fromUserAvatar': fromUserAvatar,
      'toUserId': toUserId,
      'toUsername': toUsername,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  FollowRequest copyWith({
    String? id,
    String? fromUserId,
    String? fromUsername,
    String? fromUserAvatar,
    String? toUserId,
    String? toUsername,
    DateTime? createdAt,
    String? status,
  }) {
    return FollowRequest(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUsername: fromUsername ?? this.fromUsername,
      fromUserAvatar: fromUserAvatar ?? this.fromUserAvatar,
      toUserId: toUserId ?? this.toUserId,
      toUsername: toUsername ?? this.toUsername,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}

