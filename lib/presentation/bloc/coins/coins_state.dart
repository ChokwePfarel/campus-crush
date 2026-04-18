// lib/presentation/bloc/coins_bloc/coins_state.dart

import 'package:dating_app/domain/entities/coins_entity.dart';

abstract class CoinsState {}

class CoinsInitial extends CoinsState {}

class CoinsLoading extends CoinsState {}

class CoinsLoaded extends CoinsState {
  final CoinsEntity coins;
  final bool? hasRevealed;   // null = not checked yet

  CoinsLoaded({required this.coins, this.hasRevealed});

  CoinsLoaded copyWith({CoinsEntity? coins, bool? hasRevealed}) =>
      CoinsLoaded(
        coins:       coins       ?? this.coins,
        hasRevealed: hasRevealed ?? this.hasRevealed,
      );
}

class CoinsError extends CoinsState {
  final String message;
  final CoinsEntity? previousCoins; // revert UI on failure
  CoinsError(this.message, {this.previousCoins});
}

// Specific result states for UI feedback
class CoinsEarned extends CoinsState {
  final CoinsEntity coins;
  final int coinsEarned;
  CoinsEarned({required this.coins, required this.coinsEarned});
}

class CoinsSpent extends CoinsState {
  final CoinsEntity coins;
  final int coinsSpent;
  CoinsSpent({required this.coins, required this.coinsSpent});
}

class NotEnoughCoins extends CoinsState {
  final CoinsEntity coins;
  final String reason; // 'direct_post' | 'reveal'
  NotEnoughCoins({required this.coins, required this.reason});
}

class AdLimitReached extends CoinsState {
  final CoinsEntity coins;
  AdLimitReached(this.coins);
}

class AdLoading extends CoinsState {
  final CoinsEntity coins;
  AdLoading(this.coins);
}

class AdNotReady extends CoinsState {
  final CoinsEntity coins;
  AdNotReady(this.coins);
}


