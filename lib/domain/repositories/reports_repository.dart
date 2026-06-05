abstract class ReportsRepository {
  Future<void> reportPost({
    required String reportedUserId,
    required String reporterId,
    required String postId,
    required String reason,
  });

  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  });
}
