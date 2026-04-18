// lib/domain/repositories/coins_repository.dart

import 'package:dating_app/domain/entities/coins_entity.dart';

abstract class CoinsRepository {
  Future<CoinsEntity> trackFreeDirectPost(String userId);
  Future<CoinsEntity> getCoins(String userId);
  Future<CoinsEntity> earnCoinsFromAd(String userId);
  Future<CoinsEntity> spendCoinsOnDirectPost(String userId);
  Future<CoinsEntity> spendCoinsOnReveal({
    required String userId,
    required String postId,
  });
  Future<bool> hasRevealed({
    required String userId,
    required String postId,
  });
}