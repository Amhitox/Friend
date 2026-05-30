import 'package:flutter/foundation.dart';

/// Environment configuration for Dostok app.
/// Loads from environment variables or .env file.
/// Use --dart-define-from-file=.env or --dart-define for runtime config.
class EnvConfig {
  static final EnvConfig _instance = EnvConfig._internal();
  factory EnvConfig() => _instance;
  EnvConfig._internal();

  bool _initialized = false;

  // AI Configuration
  static const String _defaultAiApiUrl = 'https://api.openai.com/v1';
  static const String _defaultAiApiKey = '';

  // AdMob Configuration
  static const String _defaultAdmobAppId = '';
  static const String _defaultAdmobBannerId = '';
  static const String _defaultAdmobInterstitialId = '';
  static const String _defaultAdmobRewardedId = '';

  // Firebase Configuration
  static const String _defaultFirebaseProjectId = '';

  // RevenueCat Configuration
  static const String _defaultRevenueCatApiKey = '';

  // Environment
  static const bool _defaultIsProduction = false;

  // Environment variable keys (for --dart-define)
  static const String _aiApiUrlKey = 'AI_API_URL';
  static const String _aiApiKeyKey = 'AI_API_KEY';
  static const String _admobAppIdKey = 'ADMOB_APP_ID';
  static const String _admobBannerIdKey = 'ADMOB_BANNER_ID';
  static const String _admobInterstitialIdKey = 'ADMOB_INTERSTITIAL_ID';
  static const String _admobRewardedIdKey = 'ADMOB_REWARDED_ID';
  static const String _firebaseProjectIdKey = 'FIREBASE_PROJECT_ID';
  static const String _revenueCatApiKeyKey = 'REVENUECAT_API_KEY';
  static const String _isProductionKey = 'IS_PRODUCTION';

  // Cached values
  late final String _aiApiUrl;
  late final String _aiApiKey;
  late final String _admobAppId;
  late final String _admobBannerId;
  late final String _admobInterstitialId;
  late final String _admobRewardedId;
  late final String _firebaseProjectId;
  late final String _revenueCatApiKey;
  late final bool _isProduction;

  /// Initialize configuration. Call once during app startup.
  void initialize() {
    if (_initialized) return;

    // Load from environment variables (dart-define)
    _aiApiUrl = _getEnv(_aiApiUrlKey, _defaultAiApiUrl);
    _aiApiKey = _getEnv(_aiApiKeyKey, _defaultAiApiKey);
    _admobAppId = _getEnv(_admobAppIdKey, _defaultAdmobAppId);
    _admobBannerId = _getEnv(_admobBannerIdKey, _defaultAdmobBannerId);
    _admobInterstitialId = _getEnv(_admobInterstitialIdKey, _defaultAdmobInterstitialId);
    _admobRewardedId = _getEnv(_admobRewardedIdKey, _defaultAdmobRewardedId);
    _firebaseProjectId = _getEnv(_firebaseProjectIdKey, _defaultFirebaseProjectId);
    _revenueCatApiKey = _getEnv(_revenueCatApiKeyKey, _defaultRevenueCatApiKey);
    _isProduction = _getEnvBool(_isProductionKey, _defaultIsProduction);

    _initialized = true;

    if (kDebugMode) {
      debugPrint('[EnvConfig] Initialized:');
      debugPrint('  AI API URL: $_aiApiUrl');
      debugPrint('  AI API Key: ${_aiApiKey.isNotEmpty ? "***${_aiApiKey.substring(_aiApiKey.length - 4)}" : "(empty)"}');
      debugPrint('  AdMob App ID: ${_admobAppId.isNotEmpty ? _admobAppId : "(empty)"}');
      debugPrint('  Firebase Project: ${_firebaseProjectId.isNotEmpty ? _firebaseProjectId : "(empty)"}');
      debugPrint('  RevenueCat Key: ${_revenueCatApiKey.isNotEmpty ? "***${_revenueCatApiKey.substring(_revenueCatApiKey.length - 4)}" : "(empty)"}');
      debugPrint('  Is Production: $_isProduction');
    }
  }

  // Getters
  String get aiApiUrl {
    _ensureInitialized();
    return _aiApiUrl;
  }

  String get aiApiKey {
    _ensureInitialized();
    return _aiApiKey;
  }

  String get admobAppId {
    _ensureInitialized();
    return _admobAppId;
  }

  String get admobBannerId {
    _ensureInitialized();
    return _admobBannerId;
  }

  String get admobInterstitialId {
    _ensureInitialized();
    return _admobInterstitialId;
  }

  String get admobRewardedId {
    _ensureInitialized();
    return _admobRewardedId;
  }

  String get firebaseProjectId {
    _ensureInitialized();
    return _firebaseProjectId;
  }

  String get revenueCatApiKey {
    _ensureInitialized();
    return _revenueCatApiKey;
  }

  bool get isProduction {
    _ensureInitialized();
    return _isProduction;
  }

  bool get isDevelopment => !isProduction;

  // Validation helpers
  bool get hasAiApiKey => aiApiKey.isNotEmpty;
  bool get hasAdMobConfig => admobAppId.isNotEmpty && admobBannerId.isNotEmpty;
  bool get hasFirebaseConfig => firebaseProjectId.isNotEmpty;
  bool get hasRevenueCatConfig => revenueCatApiKey.isNotEmpty;

  // Convenience methods for platform-specific AdMob IDs
  String get bannerAdUnitId {
    if (kDebugMode) {
      // Use test ad unit IDs in debug
      return 'ca-app-pub-3940256099942544/6300978111';
    }
    return admobBannerId;
  }

  String get interstitialAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/1033173712';
    }
    return admobInterstitialId;
  }

  String get rewardedAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/5224354917';
    }
    return admobRewardedId;
  }

  // Helper methods
  String _getEnv(String key, String defaultValue) {
    // Try to get from dart-define environment
    final value = String.fromEnvironment(key);
    if (value.isNotEmpty) return value;

    // Fallback to default
    return defaultValue;
  }

  bool _getEnvBool(String key, bool defaultValue) {
    final value = String.fromEnvironment(key);
    if (value.isEmpty) return defaultValue;
    return value.toLowerCase() == 'true';
  }

  void _ensureInitialized() {
    if (!_initialized) {
      initialize();
    }
  }

  /// Get a summary of the configuration (safe for logging, no secrets)
  Map<String, dynamic> toSummary() {
    return {
      'aiApiUrl': aiApiUrl,
      'hasAiApiKey': hasAiApiKey,
      'hasAdMobConfig': hasAdMobConfig,
      'hasFirebaseConfig': hasFirebaseConfig,
      'hasRevenueCatConfig': hasRevenueCatConfig,
      'isProduction': isProduction,
      'firebaseProjectId': firebaseProjectId,
    };
  }
}
