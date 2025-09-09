// ChatThread model for chat list
class ChatThread {
  final String id;
  final String userId;
  final String username;
  final String fullName;
  final String avatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  ChatThread({
    required this.id,
    required this.userId,
    required this.username,
    required this.fullName,
    required this.avatar,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
  });
}
