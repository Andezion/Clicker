import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static bool _isInitialized = false;
  static RewardedAd? _rewardedAd;
  static bool _isAdLoading = false;

  // Android: ca-app-pub-3940256099942544/5224354917
  // iOS: ca-app-pub-3940256099942544/1712485313
  static const String _rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  static Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      await _loadRewardedAd();
    } catch (e) {
      debugPrint('AdMob initialization error: $e');
      _isInitialized = false;
    }
  }

  static Future<void> _loadRewardedAd() async {
    if (_isAdLoading || _rewardedAd != null) return;

    _isAdLoading = true;

    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Rewarded ad loaded');
          _rewardedAd = ad;
          _isAdLoading = false;

          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Failed to show rewarded ad: $error');
              ad.dispose();
              _rewardedAd = null;
              _loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Failed to load rewarded ad: $error');
          _rewardedAd = null;
          _isAdLoading = false;
        },
      ),
    );
  }

  static Future<bool> showRewardedAd() async {
    if (!_isInitialized) {
      debugPrint('AdMob not initialized');
      return false;
    }

    if (_rewardedAd == null) {
      debugPrint('Rewarded ad not ready');
      await _loadRewardedAd();
      return false;
    }

    bool rewardEarned = false;

    _rewardedAd!.setImmersiveMode(true);

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          debugPrint('User earned reward: ${reward.amount} ${reward.type}');
          rewardEarned = true;
        },
      );
      return rewardEarned;
    } catch (e) {
      debugPrint('Error showing rewarded ad: $e');
      return false;
    }
  }

  static bool isAdReady() {
    return _isInitialized && _rewardedAd != null;
  }

  static void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
