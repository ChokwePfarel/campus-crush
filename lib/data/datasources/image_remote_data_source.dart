import 'dart:io';
import 'package:dating_app/data/models/image_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ImagesRemoteDataSource {
  Future<List<UserImageModel>> getUserImages(String userId);

  Future<UserImageModel> uploadProfileImage({
    required String userId,
    required File image,
  });

  Future<UserImageModel> uploadGalleryImage({
    required String userId,
    required File image,
  });

  Future<void> deleteImage({required String imageId, required String path});
}

class ImagesRemoteDataSourceImpl implements ImagesRemoteDataSource {
  final SupabaseClient client;
  static const _bucket = 'user-images';

  ImagesRemoteDataSourceImpl(this.client);

  @override
  Future<List<UserImageModel>> getUserImages(String userId) async {
    try {
      print('Fetching user images for user ID: $userId');

      final response = await client
          .from('user_images')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      print('Response: $response');


      return (response as List).map((e) => UserImageModel.fromJson(e)).toList();


    } catch (e) {
      debugPrint('Error: $e');
    }

    return [];
  }

  @override
  Future<UserImageModel> uploadProfileImage({
    required String userId,
    required File image,
  }) async {
    try {
      // Step 1 — delete existing profile image if one exists
      final existing = await client
          .from('user_images')
          .select()
          .eq('user_id', userId)
          .eq('type', 'profile')
          .maybeSingle();

      if (existing != null) {
        await client.storage.from(_bucket).remove([existing['path']]);
        await client.from('user_images').delete().eq('id', existing['id']);
      }

      // Step 2 — upload new profile image
      final path =
          '$userId/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await client.storage
          .from(_bucket)
          .upload(path, image, fileOptions: const FileOptions(upsert: true));

      final url = client.storage.from(_bucket).getPublicUrl(path);

      // Step 3 — save metadata to table
      final response = await client
          .from('user_images')
          .insert({
            'user_id': userId,
            'url': url,
            'path': path,
            'type': 'profile',
          })
          .select()
          .single();

      // Step 4 — update profile_image_url on profiles table
      await client
          .from('profiles')
          .update({'profile_image_url': url})
          .eq('id', userId);

      return UserImageModel.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException: ${e.message}');
      debugPrint('Code: ${e.code}, Details: ${e.details}, Hint: ${e.hint}');
    } on StorageException catch (e) {
      debugPrint('StorageException: ${e.message}');
    } catch (e, stack) {
      debugPrint('Unexpected error: $e');
      debugPrint('Stack trace: $stack');
    }
    throw Exception('Failed to upload image');
  }

  @override
  Future<UserImageModel> uploadGalleryImage({
    required String userId,
    required File image,
  }) async {
    try {
      final path =
          '$userId/gallery_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload to storage
      await client.storage.from(_bucket).upload(path, image);

      final url = client.storage.from(_bucket).getPublicUrl(path);

      // Insert into user_images table
      final response = await client
          .from('user_images')
          .insert({
            'user_id': userId,
            'url': url,
            'path': path,
            'type': 'gallery',
          })
          .select()
          .single();

      return UserImageModel.fromJson(response);
    } on PostgrestException catch (e) {
      // Supabase/PostgREST-specific error
      debugPrint('PostgrestException: ${e.message}');
      debugPrint('Code: ${e.code}, Details: ${e.details}, Hint: ${e.hint}');
    } on StorageException catch (e) {
      // Supabase storage-specific error
      debugPrint('StorageException: ${e.message}');
    } catch (e, stack) {
      // Any other unexpected error
      debugPrint('Unexpected error: $e');
      debugPrint('Stack trace: $stack');
    }
    throw Exception('Failed to upload image');
  }

  @override
  Future<void> deleteImage({
    required String imageId,
    required String path,
  }) async {
    // Delete from storage first
    await client.storage.from(_bucket).remove([path]);

    // Then delete metadata row
    await client.from('user_images').delete().eq('id', imageId);
  }
}
