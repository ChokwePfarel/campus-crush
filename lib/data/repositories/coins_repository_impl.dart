import 'package:dating_app/data/datasources/coins_remote_data_source.dart';
import 'package:dating_app/domain/entities/coins_entity.dart';
import 'package:dating_app/domain/repositories/coins_repository.dart';
import 'package:dating_app/core/constants/post_constants.dart';


class CoinsRepositoryImpl implements CoinsRepository {
  final CoinsRemoteDataSource remoteDataSource;

  CoinsRepositoryImpl(this.remoteDataSource);

  @override
  Future<CoinsEntity> trackFreeDirectPost(String userId) =>
      remoteDataSource.trackFreeDirectPost(userId);

  @override
  Future<CoinsEntity> getCoins(String userId) =>
      remoteDataSource.getCoins(userId);

  @override
  Future<CoinsEntity> earnCoinsFromAd(String userId) =>
      remoteDataSource.earnCoinsFromAd(userId);

  @override
  Future<CoinsEntity> spendCoinsOnDirectPost(String userId) =>
          remoteDataSource.spendCoinsOnDirectPost(userId);

  @override
  Future<CoinsEntity> spendCoinsOnReveal({
    required String userId,
    required String postId,
  }) =>
      remoteDataSource.spendCoinsOnReveal(userId: userId, postId: postId);

  @override
  Future<bool> hasRevealed({
    required String userId,
    required String postId,
  }) =>
      remoteDataSource.hasRevealed(userId: userId, postId: postId);
}


class MockCoinsRepositoryImpl implements CoinsRepository {
  @override
  Future<CoinsEntity> earnCoinsFromAd(String userId) {
    // TODO: implement earnCoinsFromAd
    throw UnimplementedError();
  }

  @override
  Future<CoinsEntity> getCoins(String userId) async {
    return MockCoins.mockCoins.first;
  }

  @override
  Future<bool> hasRevealed({required String userId, required String postId}) {
    // TODO: implement hasRevealed
    throw UnimplementedError();
  }

  @override
  Future<CoinsEntity> spendCoinsOnDirectPost(String userId) {
    // TODO: implement spendCoinsOnDirectPost
    throw UnimplementedError();
  }

  @override
  Future<CoinsEntity> spendCoinsOnReveal({required String userId, required String postId}) {
    // TODO: implement spendCoinsOnReveal
    throw UnimplementedError();
  }

  @override
  Future<CoinsEntity> trackFreeDirectPost(String userId   ) {
    // TODO: implement trackFreeDirectPost
    throw UnimplementedError();
  }
}

