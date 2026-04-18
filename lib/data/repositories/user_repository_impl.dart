import 'package:dating_app/core/constants/mock_data.dart';
import 'package:dating_app/data/datasources/user_remote_data_source.dart';
import 'package:dating_app/data/models/privacy_settings_model.dart';
import 'package:dating_app/domain/entities/privacy_settings_entity.dart';
import 'package:dating_app/domain/entities/user_entity.dart';
import 'package:dating_app/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;

  UserRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserEntity> getCurrentUser() async {
    return await remoteDataSource.getCurrentUser();
  }

  @override
  Stream<UserEntity?> watchCurrentUser() {
    return remoteDataSource.watchCurrentUser();
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
    PrivacySettingsEntity? privacySettings,
    required bool isVerified,
  }) async {
    await remoteDataSource.updateUserData(
      name: name,
      sex: sex,
      bio: bio,
      status: status,
      residence: residence,
      university: university,
      interests: interests,
      age: age,
      privacySettings: privacySettings != null
          ? PrivacySettingsModel(
              isProfilePrivate: privacySettings.isProfilePrivate,
              isSpottedVisible: privacySettings.isSpottedVisible,
              showUniversity: privacySettings.showUniversity,
              allowMessageRequests: privacySettings.allowMessageRequests,
            )
          : null,
      isVerified: isVerified,

    );
  }
}

class MockUserRepositoryImpl implements UserRepository {
  final _mockUser = MockCurrentUser().currentUserMock;

  @override
  Future<UserEntity> getCurrentUser() async {
    return _mockUser;
  }

  @override
  Stream<UserEntity?> watchCurrentUser() {
    return Stream.value(_mockUser);
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
    PrivacySettingsEntity? privacySettings,
    required bool isVerified,

  }) async {
    // In a real mock, we might update the local _mockUser variable
    print("Mock update user data called");
  }
}
