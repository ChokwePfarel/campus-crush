
class CoinsEntity {
  final int balance;
  final int dailyAdsWatched;
  final DateTime? lastAdDate;
  final int dailyDirectPostsCount;
  final DateTime? lastDirectPostDate;

  const CoinsEntity({
    required this.balance,
    required this.dailyAdsWatched,
    this.lastAdDate,
    required this.dailyDirectPostsCount,
    this.lastDirectPostDate,
  });

  static const int maxDailyAds        = 5;
  static const int coinsPerAd         = 10;
  static const int directPostCost     = 5;
  static const int anonymousRevealCost = 20;
  static const int freeDirectPosts    = 2;

  bool get canWatchAd {
    final today = DateTime.now();
    if (lastAdDate == null) return true;
    final isToday = lastAdDate!.year  == today.year &&
        lastAdDate!.month == today.month &&
        lastAdDate!.day   == today.day;
    return !isToday || dailyAdsWatched < maxDailyAds;
  }

  int get adsRemainingToday {
    final today = DateTime.now();
    if (lastAdDate == null) return maxDailyAds;
    final isToday = lastAdDate!.year  == today.year &&
        lastAdDate!.month == today.month &&
        lastAdDate!.day   == today.day;
    return isToday ? (maxDailyAds - dailyAdsWatched) : maxDailyAds;
  }

  bool get canSendFreeDirectPost {
    final today = DateTime.now();
    if (lastDirectPostDate == null) return true;
    final isToday = lastDirectPostDate!.year  == today.year &&
        lastDirectPostDate!.month == today.month &&
        lastDirectPostDate!.day   == today.day;
    return !isToday || dailyDirectPostsCount < freeDirectPosts;
  }

  bool get hasEnoughForDirectPost  => balance >= directPostCost;
  bool get hasEnoughForReveal      => balance >= anonymousRevealCost;

  CoinsEntity copyWith({
    int? balance,
    int? dailyAdsWatched,
    DateTime? lastAdDate,
    int? dailyDirectPostsCount,
    DateTime? lastDirectPostDate,
  }) {
    return CoinsEntity(
      balance:               balance               ?? this.balance,
      dailyAdsWatched:       dailyAdsWatched       ?? this.dailyAdsWatched,
      lastAdDate:            lastAdDate            ?? this.lastAdDate,
      dailyDirectPostsCount: dailyDirectPostsCount ?? this.dailyDirectPostsCount,
      lastDirectPostDate:    lastDirectPostDate    ?? this.lastDirectPostDate,
    );
  }
}
