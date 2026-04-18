import 'package:dating_app/data/models/like_model.dart';
import 'package:dating_app/domain/entities/like_entity.dart' show LikeEntity;
import 'package:supabase/supabase.dart' show SupabaseClient;

abstract class LikeRemoteDataSource {
  Future<List<LikeEntity>> getLikes(String postId);

  Future<LikeEntity> likePost({
    required String postId,
    required String userId,
    required String likedByName,
  });

  Future<void> unlikePost({required String postId, required String userId});

  Future<bool> hasLiked({required String postId, required String userId});
}

class LikeRemoteDataSourceImpl implements LikeRemoteDataSource {
  final SupabaseClient client;

  LikeRemoteDataSourceImpl(this.client);

  @override
  Future<List<LikeEntity>> getLikes(String postId) async {
    final response = await client
        .from('likes')
        .select()
        .eq('post_id', postId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => LikeModel.fromJson(e)).toList();
  }

  @override
  Future<LikeEntity> likePost({
    required String postId,
    required String userId,
    required String likedByName,
  }) async {
    final response = await client
        .from('likes')
        .insert({
          'post_id': postId,
          'user_id': userId,
          'liked_by_name': likedByName,
        })
        .select()
        .single();

    return LikeModel.fromJson(response);
  }

  @override
  Future<void> unlikePost({
    required String postId,
    required String userId,
  }) async {
    await client
        .from('likes')
        .delete()
        .eq('post_id', postId)
        .eq('user_id', userId);
  }

  @override
  Future<bool> hasLiked({
    required String postId,
    required String userId,
  }) async {
    final response = await client
        .from('likes')
        .select('id')
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();

    return response != null;
  }
}
