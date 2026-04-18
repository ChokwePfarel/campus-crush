// lib/data/repositories/comments_repository_impl.dart

import 'package:dating_app/core/constants/mock_data.dart';
import 'package:dating_app/data/datasources/comment_remote_data_source.dart';
import 'package:dating_app/data/models/comment_model.dart';
import 'package:dating_app/domain/entities/comment_entity.dart';
import 'package:dating_app/domain/repositories/comments_repository.dart';

class CommentsRepositoryImpl implements CommentsRepository {
  final CommentsRemoteDataSource _dataSource;

  CommentsRepositoryImpl(this._dataSource);

  @override
  Future<List<CommentEntity>> getComments(String postId) =>
      _dataSource.getComments(postId);

  @override
  Future<CommentEntity> addComment({
    required String postId,
    required String userId,
    required String repliersName,
    required String text,
    String? parentCommentId,
  }) => _dataSource.addComment(
    postId: postId,
    userId: userId,
    repliersName: repliersName,
    text: text,
    parentCommentId: parentCommentId,
  );

  @override
  Future<void> deleteComment(String commentId) =>
      _dataSource.deleteComment(commentId);
}

class MockCommentsRepositoryImpl implements CommentsRepository {
  @override
  Future<List<CommentModel>> getComments(String postId) async {
    return CommentMock.mockComments;
  }

  @override
  Future<CommentEntity> addComment({
    required String postId,
    required String userId,
    required String repliersName,
    required String text,
    String? parentCommentId,
  }) {
    // TODO: implement addComment
    throw UnimplementedError();
  }

  @override
  Future<void> deleteComment(String commentId) {
    // TODO: implement deleteComment
    throw UnimplementedError();
  }
}
