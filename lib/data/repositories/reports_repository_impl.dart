import 'package:dating_app/data/datasources/report_remote_data_source.dart';
import 'package:dating_app/domain/repositories/reports_repository.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsRemoteDataSource remoteDataSource;

  ReportsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> reportPost({
    required String reportedUserId,
    required String reporterId,
    required String postId,
    required String reason,
  }) async {
    await remoteDataSource.reportPost(
      reportedUserId: reportedUserId,
      reporterId: reporterId,
      postId: postId,
      reason: reason,
    );
  }

  @override
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    await remoteDataSource.blockUser(
      blockerId: blockerId,
      blockedId: blockedId,
    );
  }

  @override
  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    await remoteDataSource.unblockUser(
      blockerId: blockerId,
      blockedId: blockedId,
    );
  }

  @override
  Future<List<String>> getBlockedUserIds(String userId) async {
    return await remoteDataSource.getBlockedUserIds(userId);
  }
}
