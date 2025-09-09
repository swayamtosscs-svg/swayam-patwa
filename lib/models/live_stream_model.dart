class LiveStreamHealth {
  final bool success;
  final String message;
  final double uptime;
  final String timestamp;

  LiveStreamHealth({
    required this.success,
    required this.message,
    required this.uptime,
    required this.timestamp,
  });

  factory LiveStreamHealth.fromJson(Map<String, dynamic> json) {
    return LiveStreamHealth(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      uptime: (json['uptime'] ?? 0).toDouble(),
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class LiveStreamStatus {
  final bool success;
  final String room;
  final bool isLive;
  final int broadcasterCount;
  final int viewerCount;
  final String timestamp;

  LiveStreamStatus({
    required this.success,
    required this.room,
    required this.isLive,
    required this.broadcasterCount,
    required this.viewerCount,
    required this.timestamp,
  });

  factory LiveStreamStatus.fromJson(Map<String, dynamic> json) {
    return LiveStreamStatus(
      success: json['success'] ?? false,
      room: json['room'] ?? '',
      isLive: json['isLive'] ?? false,
      broadcasterCount: json['broadcasterCount'] ?? 0,
      viewerCount: json['viewerCount'] ?? 0,
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class LiveStreamRoom {
  final bool success;
  final String room;
  final bool isActive;
  final int broadcasterCount;
  final int viewerCount;
  final String timestamp;

  LiveStreamRoom({
    required this.success,
    required this.room,
    required this.isActive,
    required this.broadcasterCount,
    required this.viewerCount,
    required this.timestamp,
  });

  factory LiveStreamRoom.fromJson(Map<String, dynamic> json) {
    return LiveStreamRoom(
      success: json['success'] ?? false,
      room: json['room'] ?? '',
      isActive: json['status']?['isActive'] ?? false,
      broadcasterCount: json['status']?['broadcasterCount'] ?? 0,
      viewerCount: json['status']?['viewerCount'] ?? 0,
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class LiveStreamUser {
  final String userId;
  final String role;
  final String room;
  final String? socketId;
  final String joinedAt;
  final String? updatedAt;

  LiveStreamUser({
    required this.userId,
    required this.role,
    required this.room,
    this.socketId,
    required this.joinedAt,
    this.updatedAt,
  });

  factory LiveStreamUser.fromJson(Map<String, dynamic> json) {
    return LiveStreamUser(
      userId: json['userId'] ?? '',
      role: json['role'] ?? '',
      room: json['room'] ?? '',
      socketId: json['socketId'],
      joinedAt: json['joinedAt'] ?? '',
      updatedAt: json['updatedAt'],
    );
  }
}

class LiveStreamUserResponse {
  final bool success;
  final String message;
  final LiveStreamUser user;
  final String timestamp;

  LiveStreamUserResponse({
    required this.success,
    required this.message,
    required this.user,
    required this.timestamp,
  });

  factory LiveStreamUserResponse.fromJson(Map<String, dynamic> json) {
    return LiveStreamUserResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      user: LiveStreamUser.fromJson(json['user'] ?? {}),
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class LiveStreamRoomUsersResponse {
  final bool success;
  final List<LiveStreamUser> users;
  final String timestamp;

  LiveStreamRoomUsersResponse({
    required this.success,
    required this.users,
    required this.timestamp,
  });

  factory LiveStreamRoomUsersResponse.fromJson(Map<String, dynamic> json) {
    return LiveStreamRoomUsersResponse(
      success: json['success'] ?? false,
      users: (json['users'] as List<dynamic>?)
              ?.map((user) => LiveStreamUser.fromJson(user))
              .toList() ??
          [],
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class LiveStreamRequest {
  final String room;

  LiveStreamRequest({
    required this.room,
  });

  Map<String, dynamic> toJson() {
    return {
      'room': room,
    };
  }
}

class RoleAssignmentRequest {
  final String userId;
  final String role;
  final String room;

  RoleAssignmentRequest({
    required this.userId,
    required this.role,
    required this.room,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'role': role,
      'room': room,
    };
  }
}

class RoleUpdateRequest {
  final String role;

  RoleUpdateRequest({
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'role': role,
    };
  }
}

class LiveStreamRoomsResponse {
  final bool success;
  final List<LiveStreamRoom> rooms;
  final String timestamp;

  LiveStreamRoomsResponse({
    required this.success,
    required this.rooms,
    required this.timestamp,
  });

  factory LiveStreamRoomsResponse.fromJson(Map<String, dynamic> json) {
    return LiveStreamRoomsResponse(
      success: json['success'] ?? false,
      rooms: (json['rooms'] as List<dynamic>?)
              ?.map((room) => LiveStreamRoom.fromJson(room))
              .toList() ??
          [],
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class LiveStreamAnalytics {
  final bool success;
  final String room;
  final int totalViewers;
  final int peakViewers;
  final double averageViewers;
  final int totalDuration; // in seconds
  final String startTime;
  final String endTime;
  final String timestamp;

  LiveStreamAnalytics({
    required this.success,
    required this.room,
    required this.totalViewers,
    required this.peakViewers,
    required this.averageViewers,
    required this.totalDuration,
    required this.startTime,
    required this.endTime,
    required this.timestamp,
  });

  factory LiveStreamAnalytics.fromJson(Map<String, dynamic> json) {
    return LiveStreamAnalytics(
      success: json['success'] ?? false,
      room: json['room'] ?? '',
      totalViewers: json['totalViewers'] ?? 0,
      peakViewers: json['peakViewers'] ?? 0,
      averageViewers: (json['averageViewers'] ?? 0).toDouble(),
      totalDuration: json['totalDuration'] ?? 0,
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class LiveStreamMessage {
  final String messageId;
  final String userId;
  final String room;
  final String message;
  final String timestamp;
  final String? username;

  LiveStreamMessage({
    required this.messageId,
    required this.userId,
    required this.room,
    required this.message,
    required this.timestamp,
    this.username,
  });

  factory LiveStreamMessage.fromJson(Map<String, dynamic> json) {
    return LiveStreamMessage(
      messageId: json['messageId'] ?? '',
      userId: json['userId'] ?? '',
      room: json['room'] ?? '',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] ?? '',
      username: json['username'],
    );
  }
}

class LiveStreamMessageRequest {
  final String room;
  final String userId;
  final String message;

  LiveStreamMessageRequest({
    required this.room,
    required this.userId,
    required this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'room': room,
      'userId': userId,
      'message': message,
    };
  }
}

class LiveStreamMessageResponse {
  final bool success;
  final String message;
  final String messageId;
  final String timestamp;

  LiveStreamMessageResponse({
    required this.success,
    required this.message,
    required this.messageId,
    required this.timestamp,
  });

  factory LiveStreamMessageResponse.fromJson(Map<String, dynamic> json) {
    return LiveStreamMessageResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      messageId: json['messageId'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class LiveStreamMessagesResponse {
  final bool success;
  final List<LiveStreamMessage> messages;
  final String timestamp;

  LiveStreamMessagesResponse({
    required this.success,
    required this.messages,
    required this.timestamp,
  });

  factory LiveStreamMessagesResponse.fromJson(Map<String, dynamic> json) {
    return LiveStreamMessagesResponse(
      success: json['success'] ?? false,
      messages: (json['messages'] as List<dynamic>?)
              ?.map((message) => LiveStreamMessage.fromJson(message))
              .toList() ??
          [],
      timestamp: json['timestamp'] ?? '',
    );
  }
}