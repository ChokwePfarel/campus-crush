

import 'package:dating_app/core/constants/mock_data.dart';
import 'package:dating_app/data/datasources/likes_remote_data_source.dart';
import 'package:dating_app/domain/entities/like_entity.dart';
import 'package:dating_app/domain/repositories/likes_repository.dart';

class LikeRepositoryImpl implements LikesRepository {
  final LikeRemoteDataSource remoteDataSource;

  LikeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<LikeEntity>> getLikes(String postId) async {
    return await remoteDataSource.getLikes(postId);

  }

  @override
  Future<LikeEntity> likePost({
    required String postId,
    required String userId,
    required String likedByName,}) async {
    return await remoteDataSource.likePost(
      postId: postId,
      userId: userId,
      likedByName: likedByName,);

}

 @override
  Future<void> unlikePost({required String postId, required String userId}) async {
    await remoteDataSource.unlikePost(postId: postId, userId: userId);
  }

  @override
  Future<bool> hasLiked({required String postId, required String userId}) async {
    return await remoteDataSource.hasLiked(postId: postId, userId: userId);

  }


}

class LikesMockImpl implements LikesRepository {
  
  @override
  Future<List<LikeEntity>> getLikes(String postId) async {
    return LikesMock.mockLikes;

  }

  @override
  Future<bool> hasLiked({required String postId, required String userId}) {
    // TODO: implement hasLiked
    throw UnimplementedError();
  }

  @override
  Future<LikeEntity> likePost({required String postId, required String userId, required String likedByName}) {
    // TODO: implement likePost
    throw UnimplementedError();
  }

  @override
  Future<void> unlikePost({required String postId, required String userId}) {
    // TODO: implement unlikePost
    throw UnimplementedError();
  }
}