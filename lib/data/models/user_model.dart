import '../../domain/entities/user_entity.dart';
import 'privacy_settings_model.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.id,
    required super.name,
    required super.age,
    required super.sex,
    required super.university,
    required super.residence,
    required super.status,
    required super.major,
    required super.bio,
    required super.profileImageUrl,
    required super.imageUrls,
    required super.interests,
    super.isVerified = false,
    required PrivacySettingsModel super.privacySettings,
    super.coins = 0,
    super.dailyAdsWatched = 0,
    super.lastAdDate,
    super.dailyDirectPostsCount = 0,
    super.lastDirectPostDate,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      sex: json['sex'] ?? '',
      university: json['university'] ?? '',
      residence: json['residence'] ?? '',
      status: json['status'] ?? '',
      major: json['major'] ?? '',
      bio: json['bio'] ?? '',
      profileImageUrl: json['profile_image_url'] ?? '',
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      interests: List<String>.from(json['interests'] ?? []),
      isVerified: json['is_verified'] ?? false,
      privacySettings: PrivacySettingsModel.fromJson(json['privacy_settings'] ?? {}),
      coins: json['coins'] ?? 0,
      dailyAdsWatched: json['daily_ads_watched'] ?? 0,
      lastAdDate: json['last_ad_date'] != null ? DateTime.parse(json['last_ad_date']) : null,
      dailyDirectPostsCount: json['daily_direct_posts_count'] ?? 0,
      lastDirectPostDate: json['last_direct_post_date'] != null ? DateTime.parse(json['last_direct_post_date']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'sex': sex,
      'university': university,
      'residence': residence,
      'status': status,
      'major': major,
      'bio': bio,
      'profile_image_url': profileImageUrl,
      'image_urls': imageUrls,
      'interests': interests,
      'is_verified': isVerified,
      'privacy_settings': (privacySettings as PrivacySettingsModel).toJson(),
      'coins': coins,
      'daily_ads_watched': dailyAdsWatched,
      'last_ad_date': lastAdDate?.toIso8601String(),
      'daily_direct_posts_count': dailyDirectPostsCount,
      'last_direct_post_date': lastDirectPostDate?.toIso8601String(),
    };
  }
}
