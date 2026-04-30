import 'dart:async';
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
      // 1. Try to fetch fresh data from Supabase
      final users = await remoteDataSource.getUsers(
        university: university,
        sex: sex,
        residence: residence,
        offset: offset,
        limit: limit,
      );

      // 2. On success, update the local cache (only for the first page)
      if (offset == 0) {
        print('Offline Sync: Updating Discovery Cache');
        await OfflineCache.cacheDiscoveryUsers(users);
      }

      return users;

    } catch (e) {
      // 3. On ANY error (Offline, Timeout, Server Error), fall back to Hive
      print('Offline Sync: Fetch failed, falling back to Hive cache. Error: $e');
      
      if (offset == 0) {

        final cached = OfflineCache.getCachedDiscoveryUsers();
        
        if (cached.isNotEmpty) {
          print('Offline Sync: Successfully loaded ${cached.length} users from Hive');
          return cached;
        }
      }
      
      // If we have no cache and no network, bubble up the error
      rethrow;
    }
  }

  @override
  Future<UserModel> getUserById(String userId) async {
    try {
      final user = await remoteDataSource.getUserById(userId);
      // Cache basic profile info for offline viewing
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
    return MockData.mockUsers.firstWhere(
      (user) => user.id == userId,
      orElse: () => MockData.mockUsers.first,
    );
  }
}
