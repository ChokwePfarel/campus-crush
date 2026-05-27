import '../../../domain/entities/user_entity.dart';
import '../../../domain/entities/privacy_settings_entity.dart';

abstract class UserEvent {}

class LoadUserSubscription extends UserEvent {}

class UserUpdated extends UserEvent {
  final UserEntity? user;
  UserUpdated(this.user);
}

class UserErrorOccurred extends UserEvent {
  final String message;
  UserErrorOccurred(this.message);
}

class UpdateUserRequested extends UserEvent {
  final String name;
  final String sex;
  final String bio;
  final String status;
  final String residence;
  final String university;
  final List<String> interests;
  final int age;
  final PrivacySettingsEntity? privacySettings;
  final bool isVerified;
  final int? coins;



  UpdateUserRequested({
    required this.name,
    required this.sex,
    required this.bio,
    required this.status,
    required this.residence,
    required this.university,
    required this.interests,
    required this.age,
    this.privacySettings,
    required this.isVerified,
    this.coins ,
  });
}

//WHEN LOGG OUT
class ResetUser extends UserEvent {}
