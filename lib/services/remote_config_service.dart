import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  static final _rc = FirebaseRemoteConfig.instance;

  static bool _initialised = false;

  // Key name in Firebase Remote Config console
  static const _geminiKey = 'gemini_api_key';

  /// Call once at app startup (after Firebase.initializeApp).
  static Future<void> init() async {
    if (_initialised) return;
    await _rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout:      const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 12),
    ));
    // Default keeps the app functional the very first time before fetch succeeds
    await _rc.setDefaults(const {_geminiKey: ''});
    try {
      await _rc.fetchAndActivate();
    } catch (_) {
      // Use cached / default values if fetch fails (offline, etc.)
    }
    _initialised = true;
  }

  /// Returns the Gemini API key. Empty string if not yet configured.
  static String get geminiApiKey => _rc.getString(_geminiKey);
}
