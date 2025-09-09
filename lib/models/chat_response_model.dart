class ChatResponse {
  final bool success;
  final String message;
  final ChatResponseData data;

  ChatResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: ChatResponseData.fromJson(json['data'] ?? {}),
    );
  }
}

class ChatResponseData {
  final String? messageId;
  final String? content;
  final String? updatedAt;
  final String? deleteType;

  ChatResponseData({
    this.messageId,
    this.content,
    this.updatedAt,
    this.deleteType,
  });

  factory ChatResponseData.fromJson(Map<String, dynamic> json) {
    return ChatResponseData(
      messageId: json['messageId'],
      content: json['content'],
      updatedAt: json['updatedAt'],
      deleteType: json['deleteType'],
    );
  }
}


