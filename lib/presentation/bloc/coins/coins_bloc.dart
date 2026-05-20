// lib/presentation/bloc/coins_bloc/coins_bloc.dart

import 'package:dating_app/core/services/ad_service.dart';
import 'package:dating_app/domain/entities/coins_entity.dart';
import 'package:dating_app/domain/repositories/coins_repository.dart';
import 'package:dating_app/presentation/bloc/coins/coins_event.dart';
import 'package:dating_app/presentation/bloc/coins/coins_state.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

class CoinsBloc extends Bloc<CoinsEvent, CoinsState> {
  final CoinsRepository _coinsRepository;

  CoinsBloc(this._coinsRepository) : super(CoinsInitial()) {
    on<LoadCoins>(_onLoad);
    on<EarnCoinsFromAd>(_onEarnFromAd);
    on<SpendCoinsOnDirectPost>(_onSpendOnDirectPost);
    on<TrackFreeDirectPost>(_onTrackFreeDirectPost);
    on<SpendCoinsOnReveal>(_onSpendOnReveal);
    on<CheckHasRevealed>(_onCheckHasRevealed);
    on<WatchAdRequested>(_onWatchAdRequested);
    on<AdWatchCompleted>(_onAdWatchCompleted);
    on<AdWatchFailed>(_onAdWatchFailed);
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> _onLoad(
      LoadCoins event,
      Emitter<CoinsState> emit,
      ) async {
    try {
      emit(CoinsLoading());
      final coins = await _coinsRepository.getCoins(event.userId);
      emit(CoinsLoaded(coins: coins));
    } catch (e) {
      emit(CoinsError(e.toString()));
    }
  }

  // ── Earn from ad ──────────────────────────────────────────────────────────

  Future<void> _onEarnFromAd(
      EarnCoinsFromAd event,
      Emitter<CoinsState> emit,
      ) async {
    final current = state;
    if (current is! CoinsLoaded) return;

    // Guard — daily limit reached
    if (!current.coins.canWatchAd) {
      emit(AdLimitReached(current.coins));
      emit(current); // restore state
      return;
    }

    try {
      final updated = await _coinsRepository.earnCoinsFromAd(event.userId);
      emit(CoinsEarned(
        coins:       updated,
        coinsEarned: CoinsEntity.coinsPerAd,
      ));
      emit(CoinsLoaded(coins: updated));
    } catch (e) {
      emit(CoinsError(e.toString(), previousCoins: current.coins));
      emit(current);
    }
  }

  // ── Spend on direct post ──────────────────────────────────────────────────

  Future<void> _onSpendOnDirectPost(
      SpendCoinsOnDirectPost event,
      Emitter<CoinsState> emit,
      ) async {
    final current = state;
    if (current is! CoinsLoaded) return;

    if (!current.coins.hasEnoughForDirectPost) {
      emit(NotEnoughCoins(coins: current.coins, reason: 'direct_post'));
      emit(current);
      return;
    }

    try {
      final updated =
      await _coinsRepository.spendCoinsOnDirectPost(event.userId);
      emit(CoinsSpent(
        coins:      updated,
        coinsSpent: CoinsEntity.directPostCost,
      ));
      emit(CoinsLoaded(coins: updated));
    } catch (e) {
      emit(CoinsError(e.toString(), previousCoins: current.coins));
      emit(current);
    }
  }


// ── Track free direct post ────────────────────────────────────────────────

  Future<void> _onTrackFreeDirectPost(
      TrackFreeDirectPost event,
      Emitter<CoinsState> emit,
      ) async {
    final current = state;
    if (current is! CoinsLoaded) return;

    try {
      final updated =
      await _coinsRepository.trackFreeDirectPost(event.userId);
      
      // Emit CoinsSpent with 0 to signal success to the UI flow
      emit(CoinsSpent(
        coins:      updated,
        coinsSpent: 0,
      ));
      
      emit(CoinsLoaded(coins: updated));
    } catch (e) {
      emit(CoinsError(e.toString(), previousCoins: current.coins));
      emit(current);
    }
  }

  // ── Spend on reveal ───────────────────────────────────────────────────────

  Future<void> _onSpendOnReveal(
      SpendCoinsOnReveal event,
      Emitter<CoinsState> emit,
      ) async {
    final current = state;
    if (current is! CoinsLoaded) return;

    if (!current.coins.hasEnoughForReveal) {
      emit(NotEnoughCoins(coins: current.coins, reason: 'reveal'));
      emit(current);
      return;
    }

    try {
      final updated = await _coinsRepository.spendCoinsOnReveal(
        userId: event.userId,
        postId: event.postId,
      );
      emit(CoinsSpent(
        coins:      updated,
        coinsSpent: CoinsEntity.anonymousRevealCost,
      ));
      emit(CoinsLoaded(coins: updated, hasRevealed: true));
    } catch (e) {
      emit(CoinsError(e.toString(), previousCoins: current.coins));
      emit(current);
    }
  }

  // ── Check has revealed ────────────────────────────────────────────────────

  Future<void> _onCheckHasRevealed(
      CheckHasRevealed event,
      Emitter<CoinsState> emit,
      ) async {
    final current = state;
    if (current is! CoinsLoaded) return;

    try {
      final hasRevealed = await _coinsRepository.hasRevealed(
        userId: event.userId,
        postId: event.postId,
      );
      emit(current.copyWith(hasRevealed: hasRevealed));
    } catch (e) {
      emit(CoinsError(e.toString(), previousCoins: current.coins));
      emit(current);
    }
  }

  // ── Watch ad requested ────────────────────────────────────────────────────

  Future<void> _onWatchAdRequested(
      WatchAdRequested event,
      Emitter<CoinsState> emit,
      ) async {
    final current = state;
    if (current is! CoinsLoaded) return;

    // Guard — daily limit reached
    if (!current.coins.canWatchAd) {
      emit(AdLimitReached(current.coins));
      emit(current);
      return;
    }

    // Guard — ad not loaded yet
    if (!AdService.instance.isReady) {
      emit(AdNotReady(current.coins));
      // Try loading for next time
      AdService.instance.loadRewardedAd();
      emit(current);
      return;
    }

    emit(AdLoading(current.coins));

    await AdService.instance.showRewardedAd(
      onRewarded: () {
        // User watched the full ad — fire completed event
        add(AdWatchCompleted(event.userId));
      },
      onDismissed: () {
        // Ad dismissed without completing — restore state
        if (state is AdLoading) emit(current);
      },
      onFailed: (error) {
        add(AdWatchFailed(error));
      },
    );
  }

// ── Ad watch completed ────────────────────────────────────────────────────

  Future<void> _onAdWatchCompleted(
      AdWatchCompleted event,
      Emitter<CoinsState> emit,
      ) async {
    final current = state;
    final previousCoins =
    current is CoinsLoaded ? current.coins :
    current is AdLoading   ? current.coins : null;

    if (previousCoins == null) return;

    try {
      final updated = await _coinsRepository.earnCoinsFromAd(event.userId);
      emit(CoinsEarned(
        coins:       updated,
        coinsEarned: CoinsEntity.coinsPerAd,
      ));
      emit(CoinsLoaded(coins: updated));
    } catch (e) {
      emit(CoinsError(e.toString(), previousCoins: previousCoins));
      emit(CoinsLoaded(coins: previousCoins));
    }
  }

// ── Ad watch failed ────────────────────────────────────────────────────────

  void _onAdWatchFailed(
      AdWatchFailed event,
      Emitter<CoinsState> emit,
      ) {
    final current = state;
    final coins =
    current is AdLoading ? current.coins :
    current is CoinsLoaded ? current.coins : null;

    if (coins == null) return;

    emit(CoinsError(event.error, previousCoins: coins));
    emit(CoinsLoaded(coins: coins));
  }
}
