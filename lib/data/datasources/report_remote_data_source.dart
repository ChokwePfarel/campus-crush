import 'package:flutter/cupertino.dart';
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

  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  });

  Future<List<String>> getBlockedUserIds(String userId);
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
    try {
      final existing = await client
        .from('reports')
        .select('id')
        .eq('post_id', postId)
        .eq('reporter_id', reporterId)
        .maybeSingle();

      if (existing != null) {
        throw PostAlreadyReportedException();
      }

      await client.from('reports').insert({
        'reported_user_id': reportedUserId,
        'reporter_id': reporterId,
        'post_id': postId,
        'reason': reason,
      });
    } on PostgrestException catch (e) {
      // Catch Supabase duplicate key error (23505)
      if (e.code == '23505') {
        throw PostAlreadyReportedException();
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    // Check if block already exists to avoid duplicates
    final existing = await client
        .from('blocks')
        .select('id')
        .eq('blocker_id', blockerId)
        .eq('blocked_id', blockedId)
        .maybeSingle();

    if (existing != null) return;

    await client.from('blocks').insert({
      'blocker_id': blockerId,
      'blocked_id': blockedId,
    });
  }

  @override
  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    await client
        .from('blocks')
        .delete()
        .eq('blocker_id', blockerId)
        .eq('blocked_id', blockedId);
  }

  @override
  Future<List<String>> getBlockedUserIds(String userId) async {

    // Get users I blocked
    final blockedByMe = await client
        .from('blocks')
        .select('blocked_id')
        .eq('blocker_id', userId);



    // Get users who blocked me
    final whoBlockedMe = await client
        .from('blocks')
        .select('blocker_id')
        .eq('blocked_id', userId);

    final List<String> ids = [];
    if (blockedByMe != null) {
      ids.addAll((blockedByMe as List).map((e) => e['blocked_id'] as String));
    }
    if (whoBlockedMe != null) {
      ids.addAll((whoBlockedMe as List).map((e) => e['blocker_id'] as String));
    }

    return ids.toSet().toList(); // Remove duplicates just in case
  }
}

class PostAlreadyReportedException implements Exception {
  @override
  String toString() => 'Post has already been reported.';
}
