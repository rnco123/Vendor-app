import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Central place for swallowed/caught errors so failures are visible in logs
/// and (when Firebase is ready) in Crashlytics.
class AppLog {
  AppLog._();

  /// Log a caught error. Prefer this over empty `catch (_) {}`.
  static void caught(String where, Object error, [StackTrace? stackTrace]) {
    developer.log(
      '$error',
      name: 'PoolX.$where',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
    debugPrint('ERROR [$where] $error');
    if (stackTrace != null) {
      debugPrint('$stackTrace');
    }
    _reportToCrashlytics(where, error, stackTrace);
  }

  static void _reportToCrashlytics(
    String where,
    Object error,
    StackTrace? stackTrace,
  ) {
    try {
      if (Firebase.apps.isEmpty) return;
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: where,
        fatal: false,
      );
    } catch (_) {
      // Never let reporting itself crash the app.
    }
  }

  /// Wire Flutter framework + platform errors into Crashlytics.
  static Future<void> installCrashHandlers() async {
    if (Firebase.apps.isEmpty) return;

    // Collect in debug too so wiring can be verified; filter later if noisy.
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(true);

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
}
