import 'package:dating_app/core/constants/mock_data.dart';
import 'package:dating_app/core/utils/offline_cache.dart';
import 'package:dating_app/data/datasources/users_remote_data_source.dart';
import 'package:dating_app/data/models/user_model.dart';
import 'package:dating_app/domain/repositories/users_repository.dart';

class UsersRepositoryImpl implements UsersRepository {
  final UsersRemoteDataSource remoteDataSource;

  UsersRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<UserModel>> getUsers({
    required String university,
    required String sex,
    String? residence,
    required int offset,
    required int limit,
  }) =>
      remoteDataSource.getUsers(
        university: university,
        sex: sex,
        residence: residence,
        offset: offset,
        limit: limit,
      );

  @override
  Future<List<UserModel>> searchUsers({
    required String university,
    required String query,
    required int offset,
    required int limit,
  }) =>
      remoteDataSource.searchUsers(
        university: university,
        query: query,
        offset: offset,
        limit: limit,
      );

  @override
  Future<UserModel> getUserById(String userId) async {
    try {
      final user = await remoteDataSource.getUserById(userId);
      await OfflineCache.cacheProfile(userId, user.toJson());
      return user;
    } catch (e) {
      final cachedJson = OfflineCache.getCachedProfile(userId);
      if (cachedJson != null) return UserModel.fromJson(cachedJson);
      rethrow;
    }
  }
}

class MockRepositoryImpl implements UsersRepository {
  MockRepositoryImpl();

  @override
  Future<List<UserModel>> getUsers({
    required String university,
    required String sex,
    String? residence,
    required int offset,
    required int limit,
  }) async {
    final filtered = MockData.mockUsers
        .where((u) => u.university == university && u.sex == sex)
        .toList();
    return filtered.skip(offset).take(limit).toList();
  }

  @override
  Future<List<UserModel>> searchUsers({
    required String university,
    required String query,
    required int offset,
    required int limit,
  }) async {
    final filtered = MockData.mockUsers
        .where((u) => u.university == university && 
                (u.name.toLowerCase().contains(query.toLowerCase()) || 
                 u.residence.toLowerCase().contains(query.toLowerCase())))
        .toList();
    return filtered.skip(offset).take(limit).toList();
  }

  @override
  Future<UserModel> getUserById(String userId) async {
    return MockData.mockUsers.firstWhere(
          (user) => user.id == userId,
      orElse: () => MockData.mockUsers.first,
    );
  }
}
