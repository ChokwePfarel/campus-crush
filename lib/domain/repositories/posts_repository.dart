import 'package:flutter/material.dart';
import '../../data/models/post_model.dart';

abstract class PostRepository {
  Future<List<PostModel>> getPosts({
    String? university,
    String? postType,
    String? locationTag,
    required int offset,
    required int limit,
  });

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
  });

  Future<void> deletePost(String postId);


 Future <List<PostModel>> getDirectPostsPaginated({
    required String recipientId,
    DateTime? before, required int limit,
  });


  Stream<List<PostModel>> watchNewDirectPosts(String recipientId);

  Future<PostModel> getOnePostById(String postId);

}
