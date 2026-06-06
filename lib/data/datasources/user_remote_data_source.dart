import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/privacy_settings_model.dart';

abstract class UserRemoteDataSource {
  Future<UserModel> getCurrentUser();
  Stream<UserModel?> watchCurrentUser();
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
  Future<UserModel> getUserById(String userId);
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
        'profile_status': 'clean'
      };

      if (privacySettings != null) {
        updates['privacy_settings'] = privacySettings.toJson();
      }

// print("Attempting Supabase Upsert with: $updates");

      final response = await client.from('profiles').upsert(updates).select();
      
// print("Supabase Response: $response");
    } catch (e) {
// print("FATAL ERROR in updateUserData: $e");
      rethrow;
    }
  }

  @override
  Future<UserModel> getUserById(String userId) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return UserModel.fromJson(response);
  }
}
