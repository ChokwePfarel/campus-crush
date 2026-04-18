
class LikeEntity {
  final String id;
  final String postId;
  final String userId;
  final String likedByName;
  final DateTime createdAt;

  const LikeEntity({
    required this.id,
    required this.postId,
    required this.userId,
    required this.likedByName,
    required this.createdAt,
  });
}