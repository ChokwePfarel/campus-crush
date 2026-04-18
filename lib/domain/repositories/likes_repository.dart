

import 'package:dating_app/domain/entities/like_entity.dart' show LikeEntity;

abstract class LikesRepository {

  Future<List<LikeEntity>> getLikes(String postId);

  Future<LikeEntity> likePost({
    required String postId,
    required String userId,
    required String likedByName,
  });

  Future<void> unlikePost({required String postId, required String userId});

  Future<bool> hasLiked({required String postId, required String userId});

}