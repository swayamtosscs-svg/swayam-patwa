class Message {
  final String id;
  final String threadId;
  final MessageSender sender;
  final String recipient;
  final String content;
  final String messageType;
  final bool isRead;
  final bool isDeleted;
  final List<dynamic> reactions;
  final DateTime createdAt;
  final DateTime updatedAt;

  Message({
    required this.id,
    required this.threadId,
    required this.sender,
    required this.recipient,
    required this.content,
    required this.messageType,
    required this.isRead,
    required this.isDeleted,
    required this.reactions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? '',
      threadId: json['thread'] ?? '',
      sender: MessageSender.fromJson(json['sender'] ?? {}),
      recipient: json['recipient'] ?? '',
      content: json['content'] ?? '',
      messageType: json['messageType'] ?? 'text',
      isRead: json['isRead'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      reactions: List<dynamic>.from(json['reactions'] ?? []),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'thread': threadId,
      'sender': sender.toJson(),
      'recipient': recipient,
      'content': content,
      'messageType': messageType,
      'isRead': isRead,
      'isDeleted': isDeleted,
      'reactions': reactions,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class MessageSender {
  final String id;
  final String username;
  final String fullName;
  final String avatar;

  MessageSender({
    required this.id,
    required this.username,
    required this.fullName,
    required this.avatar,
  });

  factory MessageSender.fromJson(Map<String, dynamic> json) {
    return MessageSender(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      fullName: json['fullName'] ?? '',
      avatar: json['avatar'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'fullName': fullName,
      'avatar': avatar,
    };
  }
}

class MessageResponse {
  final bool success;
  final String message;
  final List<Message> messages;
  final int total;

  MessageResponse({
    required this.success,
    required this.message,
    required this.messages,
    required this.total,
  });

  factory MessageResponse.fromJson(Map<String, dynamic> json) {
    final messagesList = json['data']?['messages'] as List<dynamic>? ?? [];
    final messages = messagesList
        .map((messageJson) => Message.fromJson(messageJson))
        .toList();

    return MessageResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      messages: messages,
      total: json['data']?['total'] ?? 0,
    );
  }
}

class SendMessageResponse {
  final bool success;
  final String message;
  final String? messageId;
  final String? threadId;
  final String? content;
  final DateTime? sentAt;

  SendMessageResponse({
    required this.success,
    required this.message,
    this.messageId,
    this.threadId,
    this.content,
    this.sentAt,
  });

  factory SendMessageResponse.fromJson(Map<String, dynamic> json) {
    return SendMessageResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      messageId: json['data']?['messageId'],
      threadId: json['data']?['threadId'],
      content: json['data']?['content'],
      sentAt: json['data']?['sentAt'] != null 
          ? DateTime.tryParse(json['data']['sentAt']) 
          : null,
    );
  }
}


