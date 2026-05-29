import 'dart:ui';
import 'package:dating_app/core/utils/offline_cache.dart';
import 'package:dating_app/data/datasources/post_remote_data_source.dart';
import 'package:dating_app/data/models/post_model.dart';
import 'package:dating_app/domain/repositories/posts_repository.dart';

class PostRepositoryImp implements PostRepository {
  final PostRemoteDataSource remoteDataSource;

  PostRepositoryImp({required this.remoteDataSource});

  @override
  Future<List<PostModel>> getPosts({
    String? university,
    String? postType,
    String? locationTag,
    required int offset,
    required int limit,
  }) async {
    try {
      final posts = await remoteDataSource.getPosts(
        university: university,
        postType: postType,
        locationTag: locationTag,
        offset: offset,
        limit: limit,
      );

      return posts;

    } catch (e) {

      rethrow;
    }
  }

  @override
  Future<void> createPost({
    required String content,
    required String university,
    required Color backgroundColor,
    required bool isAnonymous,
    required String postType,
    required String authorName,
    String? recipientId,
    bool isNormalPost = true,
    String? locationTag,
    DateTime? expiresAt,
  }) async {
    await remoteDataSource.createPost(
      content: content,
      university: university,
      backgroundColor: backgroundColor.value,
      isAnonymous: isAnonymous,
      postType: postType,
      authorName: authorName,
      recipientId: recipientId,
      isNormalPost: isNormalPost,
      locationTag: locationTag,
      expiresAt: expiresAt,
    );
  }

  @override
  Future<void> deletePost(String postId) async {
    await remoteDataSource.deletePost(postId);
  }

  @override
  Future<List<PostModel>> getDirectPostsPaginated({
    required String recipientId,
    DateTime? before,
    int limit = 20,
  }) async {
    return await remoteDataSource.getDirectPostsPaginated(
      recipientId: recipientId,
      before: before,
    );
  }

  @override
  Stream<List<PostModel>> watchNewDirectPosts(String recipientId) {
    return remoteDataSource.watchNewDirectPosts(recipientId);
  }


  @override
    Future<PostModel> getOnePostById(String postId) async {
    return await remoteDataSource.getOnePostById(postId);
  }
}
