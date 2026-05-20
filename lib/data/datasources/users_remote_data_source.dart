import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

abstract class UsersRemoteDataSource {
  Future<List<UserModel>> getUsers({
    required String university,
    required String sex,
    String? residence,
    required int offset,
    required int limit,
  });

  Future<List<UserModel>> searchUsers({
    required String university,
    required String query,
    required int offset,
    required int limit,
  });

  Future<UserModel> getUserById(String userId);
}

class UsersRemoteDataSourceImpl implements UsersRemoteDataSource {
  final SupabaseClient client;

  UsersRemoteDataSourceImpl({required this.client});

  @override
  Future<List<UserModel>> getUsers({
    required String university,
    required String sex, // This is the current user's sex
    String? residence,
    required int offset,
    required int limit,
  }) async {
    // 1. Determine the target sex based on the requirement
    String targetSex;
    String currentSexLower = sex;

    try {
      if (currentSexLower == 'LGBTQ') {
        targetSex = 'LGBTQ';
      } else if (currentSexLower == 'Male') {
        targetSex = 'Female';
      } else {
        targetSex = 'Male';
      }

      // 2. Build the query
      var query = client.from('profiles').select().eq('university', university);

      // Apply gender filter
      query = query.eq('sex', targetSex);

      // Exclude current user
      query = query.neq('id', client.auth.currentUser?.id ?? '');

      if (residence != null && residence.isNotEmpty) {
        query = query.ilike('residence', '%$residence%');
      }

      final response = await query
          .range(offset, offset + limit - 1)
          .order('name');

      return (response as List).map((e) => UserModel.fromJson(e)).toList();
    } catch (e) {
      print('ERROR: $e');
    }
    return [];
  }

  @override
  Future<List<UserModel>> searchUsers({
    required String university,
    required String query,
    required int offset,
    required int limit,
  }) async {
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('university', university)
          .neq('id', client.auth.currentUser?.id ?? '')
          .or('name.ilike.%$query%,residence.ilike.%$query%')
          .range(offset, offset + limit - 1)
          .order('name');

      return (response as List).map((e) => UserModel.fromJson(e)).toList();
    } catch (e) {
      print('SEARCH ERROR: $e');
      return [];
    }
  }

  @override
  Future<UserModel> getUserById(String userId) async {
    final response = await client.from('profiles').select().eq('id', userId).single();
    return UserModel.fromJson(response);
  }
}
