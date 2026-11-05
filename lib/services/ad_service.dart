import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();

  static const String appId = 'ca-app-pub-2209498185642035~4195005572';

  static bool get isDebugMode => kDebugMode;
  static bool useTestAds = kDebugMode;

  static const String _prodBannerId = 'ca-app-pub-2209498185642035/7486298189';
  static const String _prodInterstitialId = 'ca-app-pub-2209498185642035/5710039860';
  static const String _prodNativeId = 'ca-app-pub-2209498185642035/6843922479';
  static const String _prodAppOpenId = 'ca-app-pub-2209498185642035/XXXXXXXXXX';
  static const String _prodRewardedId = 'ca-app-pub-2209498185642035/XXXXXXXXXX';

  static const String _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testNativeId = 'ca-app-pub-3940256099942544/2247696110';
  static const String _testAppOpenId = 'ca-app-pub-3940256099942544/9257390708';
  static const String _testRewardedId = 'ca-app-pub-3940256099942544/5224354917';

  static String get bannerAdUnitId => useTestAds ? _testBannerId : _prodBannerId;
  static String get interstitialAdUnitId => useTestAds ? _testInterstitialId : _prodInterstitialId;
  static String get nativeAdUnitId => useTestAds ? _testNativeId : _prodNativeId;
  static String get appOpenAdUnitId => useTestAds ? _testAppOpenId : _prodAppOpenId;
  static String get rewardedAdUnitId => useTestAds ? _testRewardedId : _prodRewardedId;

  static bool _isInitialized = false;
  static bool get isSupportedPlatform => !kIsWeb && Platform.isAndroid;

  static Future<void> initialize() async {
    if (!isSupportedPlatform || _isInitialized) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      loadInterstitial();
    } catch (e) {
      debugPrint('[AdService] Init error: $e');
    }
  }

  static InterstitialAd? _interstitialAd;
  static bool _isLoadingInterstitial = false;
  static DateTime? _lastInterstitialShownTime;

  static void loadInterstitial() {
    if (!isSupportedPlatform || _isLoadingInterstitial || _interstitialAd != null) return;

    _isLoadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoadingInterstitial = false;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isLoadingInterstitial = false;
        },
      ),
    );
  }

  static void showInterstitial({
    VoidCallback? onDismissed,
    int cooldownSeconds = 120,
  }) {
    if (!isSupportedPlatform) {
      onDismissed?.call();
      return;
    }

    if (_lastInterstitialShownTime != null) {
      final elapsed = DateTime.now().difference(_lastInterstitialShownTime!).inSeconds;
      if (elapsed < cooldownSeconds) {
        onDismissed?.call();
        return;
      }
    }

    if (_interstitialAd == null) {
      loadInterstitial();
      onDismissed?.call();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _lastInterstitialShownTime = DateTime.now();
        loadInterstitial();
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        loadInterstitial();
        onDismissed?.call();
      },
    );

    _interstitialAd!.show();
  }

  static Widget fixedBanner({
    AdSize size = AdSize.banner,
    EdgeInsetsGeometry margin = EdgeInsets.zero,
  }) {
    return buildBannerWidget(
      isSpaceFixed: true,
      size: size,
      margin: margin,
    );
  }

  static Widget dynamicBanner({
    AdSize size = AdSize.banner,
    EdgeInsetsGeometry margin = EdgeInsets.zero,
  }) {
    return buildBannerWidget(
      isSpaceFixed: false,
      size: size,
      margin: margin,
    );
  }

  static Widget buildBannerWidget({
    bool isSpaceFixed = false,
    AdSize size = AdSize.banner,
    EdgeInsetsGeometry margin = const EdgeInsets.symmetric(vertical: 4),
  }) {
    if (!isSupportedPlatform) return const SizedBox.shrink();
    return AdBannerWidget(
      isSpaceFixed: isSpaceFixed,
      size: size,
      margin: margin,
    );
  }

  static Widget fixedNative({
    TemplateType templateType = TemplateType.small,
    double? height,
    EdgeInsetsGeometry margin = EdgeInsets.zero,
  }) {
    return buildNativeWidget(
      isSpaceFixed: true,
      templateType: templateType,
      height: height,
      margin: margin,
    );
  }

  static Widget dynamicNative({
    TemplateType templateType = TemplateType.small,
    double? height,
    EdgeInsetsGeometry margin = EdgeInsets.zero,
  }) {
    return buildNativeWidget(
      isSpaceFixed: false,
      templateType: templateType,
      height: height,
      margin: margin,
    );
  }

  static Widget buildNativeWidget({
    bool isSpaceFixed = false,
    TemplateType templateType = TemplateType.small,
    double? height,
    EdgeInsetsGeometry margin = const EdgeInsets.symmetric(vertical: 4),
  }) {
    if (!isSupportedPlatform) return const SizedBox.shrink();
    return AdNativeWidget(
      isSpaceFixed: isSpaceFixed,
      templateType: templateType,
      height: height,
      margin: margin,
    );
  }
}

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({
    super.key,
    this.isSpaceFixed = false,
    this.size = AdSize.banner,
    this.margin = const EdgeInsets.symmetric(vertical: 4),
  });

  final bool isSpaceFixed;
  final AdSize size;
  final EdgeInsetsGeometry margin;

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isFailed = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    if (!AdService.isSupportedPlatform) return;
    if (!AdService._isInitialized) {
      AdService.initialize().then((_) {
        if (mounted) _loadBanner();
      });
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      size: widget.size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _isLoaded = true;
            _isFailed = false;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _bannerAd = null;
              _isLoaded = false;
              _isFailed = true;
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFailed) return const SizedBox.shrink();

    if (!_isLoaded || _bannerAd == null) {
      if (widget.isSpaceFixed) {
        final width = widget.size.width > 0 ? widget.size.width.toDouble() : double.infinity;
        final height = widget.size.height > 0 ? widget.size.height.toDouble() : 50.0;
        return Container(
          margin: widget.margin,
          width: width,
          height: height,
        );
      }
      return const SizedBox.shrink();
    }

    return Container(
      margin: widget.margin,
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

class AdNativeWidget extends StatefulWidget {
  const AdNativeWidget({
    super.key,
    this.isSpaceFixed = false,
    this.templateType = TemplateType.small,
    this.height,
    this.margin = const EdgeInsets.symmetric(vertical: 4),
  });

  final bool isSpaceFixed;
  final TemplateType templateType;
  final double? height;
  final EdgeInsetsGeometry margin;

  @override
  State<AdNativeWidget> createState() => _AdNativeWidgetState();
}

class _AdNativeWidgetState extends State<AdNativeWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _isFailed = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  void _loadNativeAd() {
    if (!AdService.isSupportedPlatform) return;
    if (!AdService._isInitialized) {
      AdService.initialize().then((_) {
        if (mounted) _loadNativeAd();
      });
      return;
    }

    _nativeAd = NativeAd(
      adUnitId: AdService.nativeAdUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: widget.templateType,
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _isLoaded = true;
            _isFailed = false;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _nativeAd = null;
              _isLoaded = false;
              _isFailed = true;
            });
          }
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  double get _effectiveHeight {
    if (widget.height != null) return widget.height!;
    return widget.templateType == TemplateType.small ? 90.0 : 320.0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isFailed) return const SizedBox.shrink();

    if (!_isLoaded || _nativeAd == null) {
      if (widget.isSpaceFixed) {
        return Container(
          margin: widget.margin,
          width: double.infinity,
          height: _effectiveHeight,
        );
      }
      return const SizedBox.shrink();
    }

    return Container(
      margin: widget.margin,
      alignment: Alignment.center,
      width: double.infinity,
      height: _effectiveHeight,
      child: AdWidget(ad: _nativeAd!),
    );
  }
}
