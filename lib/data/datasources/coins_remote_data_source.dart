import 'package:dating_app/data/models/coins_model.dart';
import 'package:dating_app/domain/entities/coins_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class CoinsRemoteDataSource {
  Future<CoinsModel> trackFreeDirectPost(String userId);
  Future<CoinsModel> getCoins(String userId);
  Future<CoinsModel> earnCoinsFromAd(String userId);
  Future<CoinsModel> spendCoinsOnDirectPost(String userId);
  Future<CoinsModel> spendCoinsOnReveal({
    required String userId,
    required String postId,
  });
  Future<bool> hasRevealed({
    required String userId,
    required String postId,
  });
}

class CoinsRemoteDataSourceImpl implements CoinsRemoteDataSource {
  final SupabaseClient client;

  CoinsRemoteDataSourceImpl(this.client);

  @override
  Future<CoinsModel> trackFreeDirectPost(String userId) async {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final current = await getCoins(userId);

    final isToday = current.lastDirectPostDate != null &&
        current.lastDirectPostDate!.year  == today.year &&
        current.lastDirectPostDate!.month == today.month &&
        current.lastDirectPostDate!.day   == today.day;

    // Increment count if today, reset to 1 if new day
    final newCount = isToday ? current.dailyDirectPostsCount + 1 : 1;

    final response = await client
        .from('profiles')
        .update({
      'daily_direct_posts_count': newCount,
      'last_direct_post_date':    todayStr,
    })
        .eq('id', userId)
        .select('''
        coins,
        daily_ads_watched,
        last_ad_date,
        daily_direct_posts_count,
        last_direct_post_date
      ''')
        .single();

    return CoinsModel.fromJson(response);
  }

  @override
  Future<CoinsModel> getCoins(String userId) async {
    final response = await client
        .from('profiles')
        .select('''
          coins,
          daily_ads_watched,
          last_ad_date,
          daily_direct_posts_count,
          last_direct_post_date
        ''')
        .eq('id', userId)
        .single();

    return CoinsModel.fromJson(response);
  }

  @override
  Future<CoinsModel> earnCoinsFromAd(String userId) async {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Fetch current state
    final current = await getCoins(userId);

    // Check if last_ad_date is today
    final isToday = current.lastAdDate != null &&
        current.lastAdDate!.year  == today.year &&
        current.lastAdDate!.month == today.month &&
        current.lastAdDate!.day   == today.day;

    final newAdsWatched = isToday
        ? current.dailyAdsWatched + 1
        : 1; // reset to 1 (this is the first ad today)

    final response = await client
        .from('profiles')
        .update({
      'coins':             current.balance + CoinsEntity.coinsPerAd,
      'daily_ads_watched': newAdsWatched,
      'last_ad_date':      todayStr,
    })
        .eq('id', userId)
        .select('''
          coins,
          daily_ads_watched,
          last_ad_date,
          daily_direct_posts_count,
          last_direct_post_date
        ''')
        .single();

    return CoinsModel.fromJson(response);
  }

  @override
  Future<CoinsModel> spendCoinsOnDirectPost(String userId) async {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final current = await getCoins(userId);

    final isToday = current.lastDirectPostDate != null &&
        current.lastDirectPostDate!.year  == today.year &&
        current.lastDirectPostDate!.month == today.month &&
        current.lastDirectPostDate!.day   == today.day;

    final newCount = isToday ? current.dailyDirectPostsCount + 1 : 1;

    final response = await client
        .from('profiles')
        .update({
      'coins':                    current.balance - CoinsEntity.directPostCost,
      'daily_direct_posts_count': newCount,
      'last_direct_post_date':    todayStr,
    })
        .eq('id', userId)
        .select('''
        coins,
        daily_ads_watched,
        last_ad_date,
        daily_direct_posts_count,
        last_direct_post_date
      ''')
        .single();

    return CoinsModel.fromJson(response);
  }

  @override
  Future<CoinsModel> spendCoinsOnReveal({
    required String userId,
    required String postId,
  }) async {
    final current = await getCoins(userId);

    // Insert reveal record (unique constraint prevents double-charge)
    await client
        .from('anonymous_reveals')
        .insert({'user_id': userId, 'post_id': postId});

    // Deduct coins
    final response = await client
        .from('profiles')
        .update({'coins': current.balance - CoinsEntity.anonymousRevealCost})
        .eq('id', userId)
        .select('''
          coins,
          daily_ads_watched,
          last_ad_date,
          daily_direct_posts_count,
          last_direct_post_date
        ''')
        .single();

    return CoinsModel.fromJson(response);
  }

  @override
  Future<bool> hasRevealed({
    required String userId,
    required String postId,
  }) async {
    final response = await client
        .from('anonymous_reveals')
        .select('id')
        .eq('user_id', userId)
        .eq('post_id', postId)
        .maybeSingle();

    return response != null;
  }
}
