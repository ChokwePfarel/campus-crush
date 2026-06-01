
class ConversationEntity {
  final String id;
  final String userOneId;
  final String userTwoId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final int unreadCount;

  final String otherUserName;
  final String otherUserImageUrl;
  final bool otherUserIsVerified;

  const ConversationEntity({
    required this.id,
    required this.userOneId,
    required this.userTwoId,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
    required this.otherUserName,
    required this.otherUserImageUrl,
    required this.otherUserIsVerified,
    this.unreadCount = 0,
  });
}
