import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  static final AdMobService instance = AdMobService._internal();
  AdMobService._internal();

  /// Official Google Test Rewarded Video Ad Unit ID (Always serves test video ads 24/7)
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  /// Production Rewarded Video Ad Unit ID from user's AdMob account
  static const String _prodRewardedAdUnitId = 'ca-app-pub-8254120815988418/3585622793';

  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;
  bool _isInitialized = false;

  /// Initialize Google Mobile Ads SDK (Android / iOS)
  Future<void> initialize() async {
    if (kIsWeb || _isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      preloadRewardedAd();
    } catch (e) {
      debugPrint('AdMob initialization error: $e');
    }
  }

  /// Preload a rewarded video ad in background for instant availability
  void preloadRewardedAd() {
    if (kIsWeb || _isAdLoading || _rewardedAd != null) return;
    _loadAdUnit(kDebugMode ? _testRewardedAdUnitId : _prodRewardedAdUnitId, allowFallback: true);
  }

  void _loadAdUnit(String unitId, {bool allowFallback = true}) {
    if (kIsWeb || _isAdLoading) return;
    _isAdLoading = true;

    try {
      RewardedAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isAdLoading = false;
            debugPrint('AdMob: Rewarded video ad loaded successfully ($unitId).');
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('AdMob: Failed to load ad unit ($unitId): $error');
            _rewardedAd = null;
            _isAdLoading = false;
            // If production ad failed (e.g. Code 3 No Fill before PlayStore launch), fallback to Google Test Ad
            if (allowFallback && unitId != _testRewardedAdUnitId) {
              debugPrint('AdMob: Falling back to official Google test ad unit for reliable video playback...');
              _loadAdUnit(_testRewardedAdUnitId, allowFallback: false);
            }
          },
        ),
      );
    } catch (e) {
      debugPrint('AdMob: Error loading ad: $e');
      _isAdLoading = false;
    }
  }

  /// Displays the rewarded video ad.
  /// When completed, triggers [onUserEarnedReward].
  Future<bool> showRewardedAd({required VoidCallback onUserEarnedReward}) async {
    // 1. Web fallback (Simulated for computer preview)
    if (kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 1000));
      onUserEarnedReward();
      return true;
    }

    // 2. If ad not ready, attempt quick load or wait
    if (_rewardedAd == null) {
      preloadRewardedAd();
      for (int i = 0; i < 8; i++) {
        if (_rewardedAd != null) break;
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    final ad = _rewardedAd;
    // 3. If still null (e.g. offline/no internet), fallback gracefully so user gets slips
    if (ad == null) {
      debugPrint('AdMob: Ad unavailable after timeout. Granting bonus slip fallback.');
      onUserEarnedReward();
      preloadRewardedAd();
      return false;
    }

    bool rewardEarned = false;
    final completer = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('AdMob: Ad showing full screen.');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('AdMob: Ad dismissed.');
        ad.dispose();
        _rewardedAd = null;
        preloadRewardedAd(); // Preload next one
        if (rewardEarned) {
          onUserEarnedReward();
        }
        if (!completer.isCompleted) completer.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AdMob: Ad failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        preloadRewardedAd();
        onUserEarnedReward(); // Fallback
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    await ad.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('AdMob: User earned reward (${reward.amount} ${reward.type})');
        rewardEarned = true;
      },
    );

    return await completer.future;
  }
}
