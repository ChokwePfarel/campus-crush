
import 'package:dating_app/domain/entities/coins_entity.dart';

class CoinsModel extends CoinsEntity {
  const CoinsModel({
    required super.balance,
    required super.dailyAdsWatched,
    super.lastAdDate,
    required super.dailyDirectPostsCount,
    super.lastDirectPostDate,
  });

  factory CoinsModel.fromJson(Map<String, dynamic> json) {
    return CoinsModel(
      balance: json['coins'] ?? 0,
      dailyAdsWatched: json['daily_ads_watched'] ?? 0,
      lastAdDate: json['last_ad_date'] != null
          ? DateTime.parse(json['last_ad_date'])
          : null,
      dailyDirectPostsCount: json['daily_direct_posts_count'] ?? 0,
      lastDirectPostDate: json['last_direct_post_date'] != null
          ? DateTime.parse(json['last_direct_post_date'])
          : null,
    );
  }

  // Default state for a brand new user
  factory CoinsModel.empty() => const CoinsModel(
    balance:               0,
    dailyAdsWatched:       0,
    dailyDirectPostsCount: 0,
  );
}