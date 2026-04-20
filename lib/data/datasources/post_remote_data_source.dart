import 'package:dating_app/data/models/post_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class PostRemoteDataSource {
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
    required int backgroundColor,
    required bool isAnonymous,
    required String postType,
    required String authorName,
    String? recipientId,
    bool isNormalPost = true,
    String? locationTag,
    DateTime? expiresAt,
  });

  Future<void> deletePost(String postId);


  Future<List<PostModel>> getCurrentUserPost();


  Future<List<PostModel>> getDirectPostsPaginated({
    required String recipientId,
    DateTime? before,
  });

  Stream<List<PostModel>> watchNewDirectPosts(String recipientId);

}



//----------------------------------------------------------------------------
class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  final SupabaseClient client;

  PostRemoteDataSourceImpl({required this.client});

  @override
  Future<List<PostModel>> getPosts({
    String? university,
    String? postType,
    String? locationTag,
    required int offset,
    required int limit,
  }) async {

    try{

      print( 'Getting posts with university: $university, postType: $postType, locationTag: $locationTag, offset: $offset, limit: $limit');

      var query = client.from('posts').select('''
    *,
    profiles:user_id (
      id,
      name,
      profile_image_url,
      is_verified,
      privacy_settings
    )
  ''');

      if (university != null && university.isNotEmpty) {
        query = query.eq('university', university);
      }

      if (postType != null && postType.isNotEmpty) {
        query = query.eq('post_type', postType);
      }

      if (locationTag != null && locationTag.isNotEmpty) {
        query = query.eq('location_tag', locationTag);
      }

      // Only fetch normal posts for the general feed
      query = query
          .eq('is_normal_post', true);

      /* query = query
        .eq('is_normal_post', true)
        .neq('post_type', 'spotted');*/

      query = query.or(
        'expires_at.is.null,expires_at.gt.${DateTime.now().toUtc().toIso8601String()}',
      );

      final response = await query
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);


      print('Posts fetched: $response');
      print('Posts fetched legth: ${response.length.toString()}');

      return (response as List).map((e) => PostModel.fromJson(e)).toList();

    } catch(e){
      print(e.toString());
    }


    return [];




  }

  @override
  Future<void> createPost({
    required String content,
    required String university,
    required int backgroundColor,
    required bool isAnonymous,
    required String postType,
    required String authorName,
    String? recipientId,
    bool isNormalPost = true,
    String? locationTag,
    DateTime? expiresAt,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    await client.from('posts').insert({
      'user_id': user.id,
      'content': content,
      'university': university,
      'background_color': backgroundColor,
      'is_anonymous': isAnonymous,
      'post_type': postType,
      'recipient_id': recipientId,
      'is_normal_post': isNormalPost,
      'location_tag': locationTag,
      'author_name' : authorName,
      'expires_at': expiresAt?.toIso8601String(),
    });
  }

  @override
  Future<void> deletePost(String postId) async {
    await client.from('posts').delete().eq('id', postId);
  }

  @override
  Future<List<PostModel>> getCurrentUserPost() async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    final response = await client.from('posts').select().eq('user_id', user.id);
    return (response as List).map((e) => PostModel.fromJson(e)).toList();
  }



//-----------------------------------------------------------------------


  /// Fetches a page of direct posts (cursor-based pagination)
  Future<List<PostModel>> getDirectPostsPaginated({
    required String recipientId,
    DateTime? before, // cursor: fetch posts older than this timestamp
    int limit = 20,
  }) async {

    final query = client
        .from('posts')
        .select()
        .eq('recipient_id', recipientId)
        .eq('is_normal_post', false)
        .lt('created_at', before?.toIso8601String() ?? DateTime.now().toIso8601String())
        .order('created_at', ascending: false)
        .limit(limit);

    final data = await query;
    return data.map((e) => PostModel.fromJson(e)).toList();
  }

  /// Streams real-time new direct posts.
  /// .stream() only supports ONE .eq() filter — so we filter
  /// is_normal_post client-side after the stream emits.
  Stream<List<PostModel>> watchNewDirectPosts(String recipientId) {
    return client
        .from('posts')
        .stream(primaryKey: ['id'])
        .eq('recipient_id', recipientId)   // only one .eq() allowed
        .order('created_at', ascending: false)
        .limit(1)
        .map((data) => data
        .where((e) => e['is_normal_post'] == false) // second filter client-side
        .map((e) => PostModel.fromJson(e))
        .toList());
  }
}