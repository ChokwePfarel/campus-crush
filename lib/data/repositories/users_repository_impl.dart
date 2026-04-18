import 'dart:async';
import 'package:dating_app/core/constants/mock_data.dart';
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
    return await remoteDataSource.getUsers(
      university: university,
      sex: sex,
      residence: residence,
      offset: offset,
      limit: limit,
    );
  }

  @override
  Future<UserModel> getUserById(String userId) async {
    return await remoteDataSource.getUserById(userId);
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
