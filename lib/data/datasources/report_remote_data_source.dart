import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ReportsRemoteDataSource {
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

class ReportsRemoteDataSourceImp implements ReportsRemoteDataSource {
  final SupabaseClient client;

  ReportsRemoteDataSourceImp(this.client);

  @override
  Future<void> reportPost({
    required String reportedUserId,
    required String reporterId,
    required String postId,
    required String reason,
  }) async {
    await client.from('reports').insert({
      'reported_user_id': reportedUserId,
      'reporter_id': reporterId,
      'post_id': postId,
      'reason': reason,

    });
  }

  @override
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    await client.from('blocks').insert({
      'blocker_id': blockerId,
      'blocked_id': blockedId,
    });
  }
}
