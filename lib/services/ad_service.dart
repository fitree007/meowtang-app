import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  static final AdMobService instance = AdMobService._internal();
  AdMobService._internal();

  /// Official Google Test Rewarded Video Ad Unit ID
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  /// Production Rewarded Video Ad Unit ID from user's AdMob account
  static const String _prodRewardedAdUnitId = 'ca-app-pub-8254120815988418/3585622793';

  /// Active ad unit ID based on build mode
  static String get rewardedAdUnitId {
    if (kDebugMode) {
      return _testRewardedAdUnitId;
    }
    return _prodRewardedAdUnitId;
  }

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
    _isAdLoading = true;

    try {
      RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isAdLoading = false;
            debugPrint('AdMob: Rewarded video ad loaded successfully.');
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('AdMob: Rewarded ad failed to load: $error');
            _rewardedAd = null;
            _isAdLoading = false;
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

    // 2. If ad not ready, attempt quick load
    if (_rewardedAd == null) {
      preloadRewardedAd();
      for (int i = 0; i < 5; i++) {
        if (_rewardedAd != null) break;
        await Future.delayed(const Duration(milliseconds: 400));
      }
    }

    final ad = _rewardedAd;
    // 3. If still null (e.g. offline/no internet), fallback gracefully so user gets slips
    if (ad == null) {
      debugPrint('AdMob: Ad unavailable. Granting bonus slip fallback.');
      onUserEarnedReward();
      preloadRewardedAd();
      return true;
    }

    bool rewardEarned = false;

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
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AdMob: Ad failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        preloadRewardedAd();
        onUserEarnedReward(); // Fallback
      },
    );

    await ad.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('AdMob: User earned reward (${reward.amount} ${reward.type})');
        rewardEarned = true;
      },
    );

    return true;
  }
}
