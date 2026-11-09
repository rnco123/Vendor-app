import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Safely reads Firebase config from `.env` without force-unwrapping.
class FirebaseEnv {
  static const _requiredKeys = [
    'FIREBASE_API_KEY',
    'FIREBASE_APP_ID',
    'FIREBASE_MESSAGING_SENDER_ID',
    'FIREBASE_PROJECT_ID',
  ];

  static String? _trimmed(String key) {
    final value = dotenv.env[key]?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  /// Human-readable list of missing/empty required keys, or null if all present.
  static String? missingKeysMessage() {
    final missing =
        _requiredKeys.where((key) => _trimmed(key) == null).toList();
    if (missing.isEmpty) return null;
    return 'Missing or empty .env settings:\n${missing.join('\n')}\n\n'
        'Fix your .env file and restart the app.';
  }

  /// Returns [FirebaseOptions] when all required keys are set; otherwise null.
  static FirebaseOptions? tryLoadOptions() {
    final projectId = _trimmed('FIREBASE_PROJECT_ID');
    final apiKey = _trimmed('FIREBASE_API_KEY');
    final appId = _trimmed('FIREBASE_APP_ID');
    final messagingSenderId = _trimmed('FIREBASE_MESSAGING_SENDER_ID');
    if (projectId == null ||
        apiKey == null ||
        appId == null ||
        messagingSenderId == null) {
      return null;
    }

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket:
          _trimmed('FIREBASE_STORAGE_BUCKET') ?? '$projectId.firebasestorage.app',
      databaseURL: _trimmed('FIREBASE_DATABASE_URL') ??
          'https://$projectId-default-rtdb.firebaseio.com',
    );
  }
}
