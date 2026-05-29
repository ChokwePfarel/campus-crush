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

  Future<List<PostModel>> getUserPostById(String userId);

  Future<List<PostModel>> getDirectPostsPaginated({
    required String recipientId,
    DateTime? before,
  });

  Stream<List<PostModel>> watchNewDirectPosts(String recipientId);

  Future<PostModel> getOnePostById(String postId);
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
    print(
      'DEBUG: getPosts starting with Params: university=$university, type=$postType, location=$locationTag',
    );

    try {
      final selectString = '''
        *,
        profiles (
          id, name, profile_image_url, is_verified, privacy_settings
        )
      ''';

      var query = client.from('posts').select(selectString);
      query = _applyFilters(query, university, postType, locationTag);

      final response = await query
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);

      print('DEBUG: Successfully fetched ${(response as List).length} posts');
      return response.map((e) => PostModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      print('DEBUG: PostgresException in getPosts: ${e.message}');

      try {
        var fallbackQuery = client.from('posts').select('*');
        fallbackQuery = _applyFilters(
          fallbackQuery,
          university,
          postType,
          locationTag,
        );

        final fallbackRes = await fallbackQuery
            .range(offset, offset + limit - 1)
            .order('created_at', ascending: false);

        return fallbackRes.map((e) => PostModel.fromJson(e)).toList();
      } catch (fallbackError) {
        print('DEBUG: Filtered fallback failed: $fallbackError');
      }
      rethrow;
    } catch (e) {
      print('DEBUG: Unexpected error in getPosts: $e');
      rethrow;
    }
  }

  /// Helper to apply common filters to any query on the 'posts' table
  PostgrestFilterBuilder<PostgrestList> _applyFilters(
    PostgrestFilterBuilder<PostgrestList> query,
    String? university,
    String? postType,
    String? locationTag,
  ) {
    var q = query;

    if (university != null && university.isNotEmpty) {
      q = q.eq('university', university);
    }

    if (postType != null && postType.isNotEmpty) {
      q = q.eq('post_type', postType);
    } else if (locationTag == null || locationTag.isEmpty) {
      q = q.neq('post_type', 'spotted');
    }

    if (locationTag != null && locationTag.isNotEmpty) {
      q = q.eq('location_tag', locationTag);
    }

    q = q.eq('is_normal_post', true);

    q = q.or(
      'expires_at.is.null,expires_at.gt.${DateTime.now().toUtc().toIso8601String()}',
    );
    return q;
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
      'author_name': authorName,
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

    final response = await client
        .from('posts')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    return (response as List).map((e) => PostModel.fromJson(e)).toList();
  }

  @override
  Future<List<PostModel>> getUserPostById(String userId) async {
    try {
      final response = await client
          .from('posts')
          .select('''
          *,
          profiles!posts_user_id_fkey (
            id,
            name,
            profile_image_url,
            is_verified,
            privacy_settings
          )
        ''')
          .eq('user_id', userId)
          .eq('is_normal_post', true)
          .order('created_at', ascending: false);

      return response.map((e) => PostModel.fromJson(e)).toList();
    } catch (e) {
      final fallback = await client
          .from('posts')
          .select()
          .eq('user_id', userId)
          .eq('is_normal_post', true)
          .order('created_at', ascending: false);
      return fallback.map((e) => PostModel.fromJson(e)).toList();
    }
  }

  Future<List<PostModel>> getDirectPostsPaginated({
    required String recipientId,
    DateTime? before,
    int limit = 20,
  }) async {
    final query = client
        .from('posts')
        .select()
        .eq('recipient_id', recipientId)
        .eq('is_normal_post', false)
        .lt(
          'created_at',
          before?.toIso8601String() ?? DateTime.now().toIso8601String(),
        )
        .order('created_at', ascending: false)
        .limit(limit);

    final data = await query;
    return data.map((e) => PostModel.fromJson(e)).toList();
  }

  Stream<List<PostModel>> watchNewDirectPosts(String recipientId) {
    return client
        .from('posts')
        .stream(primaryKey: ['id'])
        .eq('recipient_id', recipientId)
        .order('created_at', ascending: false)
        .limit(1)
        .map(
          (data) => data
              .where((e) => e['is_normal_post'] == false)
              .map((e) => PostModel.fromJson(e))
              .toList(),
        );
  }

  @override
  Future<PostModel> getOnePostById(String postId) async {
    try {
      final response = await client
          .from('posts')
          .select('''
            *,
            profiles!posts_user_id_fkey (
              id, name, profile_image_url, is_verified, privacy_settings
            )
          ''')
          .eq('id', postId)
          .single();

      return PostModel.fromJson(response);
    } catch (e) {
      print('DEBUG: Error fetching single post by ID: $e');
      rethrow;
    }
  }
}
