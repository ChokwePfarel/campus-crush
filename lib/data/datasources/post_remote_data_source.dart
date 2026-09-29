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
      try {
        var fallbackQuery = client.from('posts').select('*');
        fallbackQuery = _applyFilters(fallbackQuery, university, postType, locationTag);

        final fallbackRes = await fallbackQuery
            .range(offset, offset + limit - 1)
            .order('created_at', ascending: false);

        return fallbackRes.map((e) => PostModel.fromJson(e)).toList();
      } catch (fallbackError) {
        rethrow;
      }
    } catch (e) {
      rethrow;
    }
  }

  PostgrestFilterBuilder<PostgrestList> _applyFilters(
      PostgrestFilterBuilder<PostgrestList> query,
      String? university,
      String? postType,
      String? locationTag) {
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
    print('DEBUG: 🗑️ Starting deletion for post: $postId');

    // 1. Find all comments first to clean up comment-linked data
    List<String> commentIds = [];
    try {
      final res =
          await client.from('comments').select('id').eq('post_id', postId);
      commentIds = (res as List).map((c) => c['id'].toString()).toList();
      print('DEBUG: Found ${commentIds.length} comments to clean up');
    } catch (e) {
      print('DEBUG: Error fetching comment IDs: $e');
    }

    // 2. Notifications
    try {
      print('DEBUG: Deleting notifications linked to post...');
      await client.from('notifications').delete().eq('post_id', postId);

      if (commentIds.isNotEmpty) {
        print('DEBUG: Deleting notifications linked to comments...');
        await client
            .from('notifications')
            .delete()
            .filter('comment_id', 'in', commentIds);
      }
    } catch (e) {
      print('DEBUG: ❌ Notification Cleanup Failed: $e');
    }

    // 3. Engagement & Reports
    try {
      print('DEBUG: Deleting reports...');
      await client.from('reports').delete().eq('post_id', postId);
      print('DEBUG: Deleting anonymous reveals...');
      await client.from('anonymous_reveals').delete().eq('post_id', postId);
      print('DEBUG: Deleting likes...');
      await client.from('likes').delete().eq('post_id', postId);
    } catch (e) {
      print('DEBUG: ❌ Engagement Cleanup Failed: $e');
    }

    // 4. Comments
    try {
      if (commentIds.isNotEmpty) {
        print('DEBUG: Deleting nested replies...');
        await client
            .from('comments')
            .delete()
            .eq('post_id', postId)
            .not('parent_comment_id', 'is', null);

        print('DEBUG: Deleting top-level comments...');
        await client.from('comments').delete().eq('post_id', postId);
      }
    } catch (e) {
      print('DEBUG: ❌ Comment Cleanup Failed: $e');
    }

    // 5. The Post itself
    try {
      print('DEBUG: Final step: Deleting the post itself...');
      await client.from('posts').delete().eq('id', postId);
      print('DEBUG: ✅ Post $postId deleted successfully');
    } catch (e) {
      print('DEBUG: 🛑 CRITICAL ERROR deleting post: $e');
      rethrow;
    }
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
    print('DEBUG: Successfully fetched ${response.length} posts');
    return (response as List).map((e) => PostModel.fromJson(e)).toList();
  }


  @override
  Future<List<PostModel>> getUserPostById(String userId) async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId != null) {
        final blockCheck = await client
            .from('blocks')
            .select('id')
            .or('and(blocker_id.eq.$currentUserId,blocked_id.eq.$userId),and(blocker_id.eq.$userId,blocked_id.eq.$currentUserId)')
            .maybeSingle();

        if (blockCheck != null) {
          return []; // Don't show posts if blocked
        }
      }

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

  @override
  Future<List<PostModel>> getDirectPostsPaginated({
    required String recipientId,
    DateTime? before,
    int limit = 20,
  }) async {
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId != null) {
      final blockCheck = await client
          .from('blocks')
          .select('id')
          .or('and(blocker_id.eq.$currentUserId,blocked_id.eq.$recipientId),and(blocker_id.eq.$recipientId,blocked_id.eq.$currentUserId)')
          .maybeSingle();

      if (blockCheck != null) {
        return [];
      }
    }

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


  @override
  Stream<List<PostModel>> watchNewDirectPosts(String recipientId) {
    return client
        .from('posts')
        .stream(primaryKey: ['id'])
        .eq('recipient_id', recipientId)
        .order('created_at', ascending: false)
        .limit(1)
        .map(
          (data) =>
          data
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

      final post = PostModel.fromJson(response);

      // Manual Safety: Mutual block check
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId != null) {
        final blockCheck = await client
            .from('blocks')
            .select('id')
            .or('and(blocker_id.eq.$currentUserId,blocked_id.eq.${post.userId}),and(blocker_id.eq.${post.userId},blocked_id.eq.$currentUserId)')
            .maybeSingle();

        if (blockCheck != null) {
          throw Exception('This post is unavailable.');
        }
      }

      return post;
    } catch (e) {
// print('DEBUG: Error fetching single post by ID: $e');
      rethrow;
    }
  }
}
