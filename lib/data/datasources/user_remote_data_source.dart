import 'package:dating_app/data/models/warning_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/privacy_settings_model.dart';

abstract class UserRemoteDataSource {

  Future<void> profileUpdate({
    required String name,
    required String sex,
    required String bio,
    required String status,
    required String residence,
    required String university,
    required List<String> interests,
    required int age,
    required PrivacySettingsModel? privacySettings,
  });

  Future<void> updateUserData({
    required String name,
    required String sex,
    required String bio,
    required String status,
    required String residence,
    required String university,
    required List<String> interests,
    required int age,
    required PrivacySettingsModel? privacySettings,
    required bool isVerified,
    int? coins,
  });

  Future<UserModel> getCurrentUser();

  Stream<UserModel?> watchCurrentUser();

  Future<UserModel> getUserById(String userId);

  Future<UserWarning> getUserWarning();

  Future<bool> checkIsProfileCompleted(String userId);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final SupabaseClient client;

  UserRemoteDataSourceImpl({required this.client});

  @override
  Future<UserModel> getCurrentUser() async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    final response = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    // print("Supabase Response: $response");

    return UserModel.fromJson(response);
  }

  @override
  Stream<UserModel?> watchCurrentUser() {
    final user = client.auth.currentUser;
    if (user == null) return Stream.value(null);

    return client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .map((data) {
          if (data.isEmpty) return null;
          return UserModel.fromJson(data.first);
        });
  }


  @override
  Future<void> profileUpdate({
    required String name,
    required String sex,
    required String bio,
    required String status,
    required String residence,
    required String university,
    required List<String> interests,
    required int age,
    required PrivacySettingsModel? privacySettings,
  }) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) throw Exception('Not signed in');

      final Map<String, dynamic> updates = {
        'name': name,
        'sex': sex,
        'bio': bio,
        'status': status,
        'residence': residence,
        'interests': interests,
        'university': university,
        'age': age,
      };

      if (privacySettings != null) {
        updates['privacy_settings'] = privacySettings.toJson();
      }

      final response = await client
          .from('profiles')
          .update(updates)
          .eq('id', user.id) // only update current user row
          .select();

    } catch (e) {
      rethrow;
    }
  }


  @override
  Future<void> updateUserData({
    required String name,
    required String sex,
    required String bio,
    required String status,
    required String residence,
    required String university,
    required List<String> interests,
    required int age,
    required PrivacySettingsModel? privacySettings,
    required bool isVerified,
    int? coins,
  }) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) throw Exception('Not signed in');

      final Map<String, dynamic> updates = {
        'id': user.id,
        'name': name,
        'sex': sex,
        'bio': bio,
        'status': status,
        'residence': residence,
        'interests': interests,
        'university': university,
        'age': age,
        'is_verified': isVerified,
        'coins': coins,
        'profile_status': 'clean',
        'is_profile_completed': true,
      };

      if (privacySettings != null) {
        updates['privacy_settings'] = privacySettings.toJson();
      }

      final response = await client.from('profiles').upsert(updates).select();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserModel> getUserById(String userId) async {
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId != null) {
      final blockCheck = await client
          .from('blocks')
          .select('id')
          .or('and(blocker_id.eq.$currentUserId,blocked_id.eq.$userId),and(blocker_id.eq.$userId,blocked_id.eq.$currentUserId)')
          .maybeSingle();

      if (blockCheck != null) {
        throw Exception('User not found or blocked');
      }
    }

    final response = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return UserModel.fromJson(response);
  }

  Future<UserWarning> getUserWarning() async {
    print('Getting warning for user ${client.auth.currentUser!.id}');

    final response = await client
        .from('warnings')
        .select()
        .eq('user_id', client.auth.currentUser!.id)
        .order('created_at', ascending: false)
        .limit(1);

    if (response.isNotEmpty) {
      print('Warning found: ${response.first}');
      return UserWarning.fromJson(response.first);
    } else {
      throw Exception('No warnings found');
    }
  }


  Future<bool> checkIsProfileCompleted(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select('is_profile_completed')
          .eq('id', userId)
          .maybeSingle(); // Use maybeSingle() instead of single()

      // If response is null, the record doesn't exist (New user)
      if (response == null) {
        return false;
      }

      return response['is_profile_completed'] as bool;
      print("Profile status: ${response['is_profile_completed']}");
    } catch (e) {
      print("Error checking profile: $e");
      return false; // Default to false to be safe
    }
  }

}
