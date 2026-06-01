
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  // ── Ad Unit IDs ────────────────────────────────────────────────────────────
  // Replace with your real IDs from AdMob when going live
  static const String _androidAdUnitId =

      'ca-app-pub-8085940948919628/5893674322';  //production ID
  static const String _iosAdUnitId = "";


  static String get _adUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _androidAdUnitId;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _iosAdUnitId;
    }
    return _androidAdUnitId;
  }

  bool get isReady => _rewardedAd != null;
  bool get isLoading => _isLoading;

  // ── Load ───────────────────────────────────────────────────────────────────

  Future<void> loadRewardedAd() async {
    if (_isLoading || _rewardedAd != null) return;
    _isLoading = true;

    await RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
          debugPrint('✅ Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isLoading = false;
          debugPrint('❌ Rewarded ad failed to load: ${error.message}');
        },
      ),
    );
  }

  // ── Show ───────────────────────────────────────────────────────────────────

  Future<bool> showRewardedAd({
    required void Function() onRewarded,
    void Function()? onDismissed,
    void Function(String error)? onFailed,
  }) async {
    if (_rewardedAd == null) {
      onFailed?.call('Ad not ready. Please try again.');
      // Preload for next time
      loadRewardedAd();
      return false;
    }

    final completer = Completer<bool>();

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        onDismissed?.call();
        // Preload next ad immediately
        loadRewardedAd();
        if (!completer.isCompleted) completer.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        onFailed?.call(error.message);
        loadRewardedAd();
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (_, reward) {
        debugPrint('🎉 User earned reward: ${reward.amount} ${reward.type}');
        onRewarded();
      },
    );

    return completer.future;
  }

  // ── Dispose ────────────────────────────────────────────────────────────────

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
