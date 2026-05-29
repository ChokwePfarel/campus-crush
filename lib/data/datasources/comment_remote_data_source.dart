// lib/data/datasources/comments_remote_data_source.dart

import 'dart:async';

import 'package:dating_app/data/models/comment_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class CommentsRemoteDataSource {
  Future<List<CommentModel>> getComments(String postId);
  Future<CommentModel> addComment({
    required String postId,
    required String userId,
    required String repliersName,
    required String text,
    String? parentCommentId,


  });
  Future<void> deleteComment(String commentId);

  Stream<CommentModel> watchUserNotifications(String userId);
}

class CommentsRemoteDataSourceImpl implements CommentsRemoteDataSource {
  final SupabaseClient client;

  CommentsRemoteDataSourceImpl(this.client);

  @override
  Future<List<CommentModel>> getComments(String postId) async {
    final response = await client
        .from('comments')
        .select()
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    final allComments = (response as List)
        .map((e) => CommentModel.fromJson(e))
        .toList();

    // Separate top-level and replies
    final topLevel = allComments
        .where((c) => c.parentCommentId == null)
        .toList();

    final replies = allComments
        .where((c) => c.parentCommentId != null)
        .toList();

    // Nest replies under their parent
    return topLevel.map((parent) {
      final parentReplies = replies
          .where((r) => r.parentCommentId == parent.id)
          .toList();

      return CommentModel(
        id:              parent.id,
        postId:          parent.postId,
        userId:          parent.userId,
        repliersName:    parent.repliersName,
        text:            parent.text,
        createdAt:       parent.createdAt,
        parentCommentId: parent.parentCommentId,
        replies:         parentReplies,
      );
    }).toList();
  }

  @override
  Future<CommentModel> addComment({
    required String postId,
    required String userId,
    required String repliersName,
    required String text,
    String? parentCommentId,
  }) async {
    final response = await client
        .from('comments')
        .insert({
      'post_id':           postId,
      'user_id':           userId,
      'repliers_name':     repliersName,
      'text':              text,
      'parent_comment_id': parentCommentId,
    })
        .select()
        .single();

    return CommentModel.fromJson(response);
  }

  @override
  Future<void> deleteComment(String commentId) async {
    await client
        .from('comments')
        .delete()
        .eq('id', commentId);
  }

  @override
  Stream<CommentModel> watchUserNotifications(String userId) {


    final controller = StreamController<CommentModel>();

    final channel = client.channel('user-notifications-$userId')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'comments',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'post_author_id',
        value: userId,
      ),
      callback: (payload) {
        if (payload.newRecord['user_id'] != userId) {
          controller.add(CommentModel.fromJson(payload.newRecord));
        }
      },
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'comments',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'parent_comment_author_id',
        value: userId,
      ),
      callback: (payload) {
        if (payload.newRecord['user_id'] != userId) {
          controller.add(CommentModel.fromJson(payload.newRecord));
        }
      },
    )
        .subscribe();

    controller.onCancel = () {
      client.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }
}
