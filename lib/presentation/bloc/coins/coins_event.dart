// lib/presentation/bloc/coins_bloc/coins_event.dart

abstract class CoinsEvent {}

class LoadCoins extends CoinsEvent {
  final String userId;
  LoadCoins(this.userId);
}



class TrackFreeDirectPost extends CoinsEvent {
  final String userId;
  TrackFreeDirectPost(this.userId);
}

class EarnCoinsFromAd extends CoinsEvent {
  final String userId;
  EarnCoinsFromAd(this.userId);
}

class SpendCoinsOnDirectPost extends CoinsEvent {
  final String userId;
  SpendCoinsOnDirectPost(this.userId);
}

class SpendCoinsOnReveal extends CoinsEvent {
  final String userId;
  final String postId;
  SpendCoinsOnReveal({required this.userId, required this.postId});
}

class CheckHasRevealed extends CoinsEvent {
  final String userId;
  final String postId;
  CheckHasRevealed({required this.userId, required this.postId});
}

class WatchAdRequested extends CoinsEvent {
  final String userId;
  WatchAdRequested(this.userId);
}

class AdWatchCompleted extends CoinsEvent {
  final String userId;
  AdWatchCompleted(this.userId);
}

class AdWatchFailed extends CoinsEvent {
  final String error;
  AdWatchFailed(this.error);
}