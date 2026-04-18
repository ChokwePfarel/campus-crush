
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

  Future<UserModel> getUserById(String userId);
}

class UsersRemoteDataSourceImpl implements UsersRemoteDataSource {
  final SupabaseClient client;

  UsersRemoteDataSourceImpl({required this.client});

  @override
  Future<List<UserModel>> getUsers({
    required String university,
    required String sex,
    String? residence,
    required int offset,
    required int limit,

  }) async {

      var query = client
          .from('profiles')
          .select().eq('university', university)
          .neq('sex', sex).neq('id', client.auth.currentUser?.id ?? ''); // Exclude current user

      if (residence != null && residence.isNotEmpty) {
        query = query.ilike('residence', '%$residence%');
      }

      final response = await query
          .range(offset, offset + limit - 1)
          .order('name');

      return (response as List).map((e) => UserModel.fromJson(e)).toList();

  }


  @override
  Future<UserModel> getUserById(String userId) async {

    final response = await client.from('profiles').select().eq('id', userId).single();

    return UserModel.fromJson(response);
  }
}

//------------------------Explaining pagination

///iLike == perform a case in sensitive patten match on residence column from the results
/// %% == wildcards . so if res is 'cape', the the query becomes iLike 'cape' , so find all rows where res contains cape,
/// 
///offset is the starting index, and limit is the max,
///offset + limit - 1 == , since index start from 0, subtracting 1 will lead to consistency
