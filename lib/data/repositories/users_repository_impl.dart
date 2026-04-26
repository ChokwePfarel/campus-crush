import 'dart:async';
import 'dart:io';
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
  }) async {
    try {
      final users = await remoteDataSource.getUsers(
        university: university,
        sex: sex,
        residence: residence,
        offset: offset,
        limit: limit,
      );

      // Update cache on initial load (offset 0)
      if (offset == 0) {
        print('Caching discovery users');
        await OfflineCache.cacheDiscoveryUsers(users);
      }

      return users;

    } on SocketException {
      // Return cached data if network fails on initial load
      print('Network error, returning cached data');
      if (offset == 0) {
        return OfflineCache.getCachedDiscoveryUsers();
      }
      rethrow;
    } catch (e) {
      // For other errors on initial load, try fallback to cache
      if (offset == 0) {
        final cached = OfflineCache.getCachedDiscoveryUsers();
        if (cached.isNotEmpty) return cached;
      }
      rethrow;
    }
  }

  @override
  Future<UserModel> getUserById(String userId) async {
    try {
      final user = await remoteDataSource.getUserById(userId);
      // Cache basic profile info
      await OfflineCache.cacheProfile(userId, user.toJson());
      return user;
    } catch (e) {
      final cachedJson = OfflineCache.getCachedProfile(userId);
      if (cachedJson != null) {
        return UserModel.fromJson(cachedJson);
      }
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

    final paginated = filtered.skip(offset).take(limit).toList();

    return paginated;
  }

  @override
  Future<UserModel> getUserById(String userId) async {
    // Look for the user in MockData.mockUsers
    return MockData.mockUsers.firstWhere(
      (user) => user.id == userId,
      orElse: () => MockData.mockUsers.first,
    );
  }
}
