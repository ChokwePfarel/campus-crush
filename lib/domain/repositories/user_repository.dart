
import 'package:dating_app/domain/entities/user_entity.dart';
import '../entities/privacy_settings_entity.dart';

abstract class UserRepository {
  Future<UserEntity> getCurrentUser();
  Stream<UserEntity?> watchCurrentUser();
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
  });
}
