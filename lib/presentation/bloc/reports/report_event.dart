abstract class ReportsEvent {}

class ReportPost extends ReportsEvent {
  final String reporterId;
  final String reportedUserId;
  final String postId;
  final String reason;

  ReportPost({
    required this.reporterId,
    required this.reportedUserId,
    required this.postId,
    required this.reason,
  });
}

abstract class BlockUserEvent {}

class BlockUser extends BlockUserEvent {
  final String blockerId;
  final String blockedId;

  BlockUser({required this.blockerId, required this.blockedId});
}

class UnblockUser extends BlockUserEvent {
  final String blockerId;
  final String blockedId;

  UnblockUser({required this.blockerId, required this.blockedId});
}
