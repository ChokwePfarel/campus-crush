import '../../domain/entities/privacy_settings_entity.dart';

class PrivacySettingsModel extends PrivacySettingsEntity {
  PrivacySettingsModel({
    super.isProfilePrivate = false,
    super.isSpottedVisible = true,
    super.showUniversity = true,
    super.allowMessageRequests = true,
  });

  factory PrivacySettingsModel.fromJson(Map<String, dynamic> json) {
    return PrivacySettingsModel(
      isProfilePrivate: json['is_profile_private'] ?? false,
      isSpottedVisible: json['is_spotted_visible'] ?? true,
      showUniversity: json['show_university'] ?? true,
      allowMessageRequests: json['allow_message_requests'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_profile_private': isProfilePrivate,
      'is_spotted_visible': isSpottedVisible,
      'show_university': showUniversity,
      'allow_message_requests': allowMessageRequests,
    };
  }
}
