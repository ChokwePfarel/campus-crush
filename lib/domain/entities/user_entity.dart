import 'privacy_settings_entity.dart';

class UserEntity {
  final String id;
  final String name;
  final int age;
  final String sex;
  final String university;
  final String residence;
  final String status;
  final String major;
  final String bio;
  final String profileImageUrl;
  final List<String> imageUrls;
  final List<String> interests;
  final bool isVerified;
  final PrivacySettingsEntity privacySettings;
  final String profileStatus;
  
  // Coin and Activity fields
  final int coins;
  final int dailyAdsWatched;
  final DateTime? lastAdDate;
  final int dailyDirectPostsCount;
  final DateTime? lastDirectPostDate;

  UserEntity({
    required this.id,
    required this.name,
    required this.age,
    required this.sex,
    required this.university,
    required this.residence,
    required this.status,
    required this.major,
    required this.bio,
    required this.profileImageUrl,
    required this.imageUrls,
    required this.interests,
    this.isVerified = false,
    required this.privacySettings,
    this.coins = 0,
    this.dailyAdsWatched = 0,
    this.lastAdDate,
    this.dailyDirectPostsCount = 0,
    this.lastDirectPostDate,
    required this.profileStatus,
  });
}
