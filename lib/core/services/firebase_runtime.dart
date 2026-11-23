import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

abstract final class FirebaseRuntime {
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _senderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
  );
  static const _iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const _webAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const _iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');

  static bool get isConfigured =>
      _apiKey.isNotEmpty &&
      _projectId.isNotEmpty &&
      _senderId.isNotEmpty &&
      _appIdForCurrentPlatform.isNotEmpty &&
      _storageBucket.isNotEmpty &&
      (!kIsWeb || _authDomain.isNotEmpty);

  static Future<void> initialize() async {
    if (!isConfigured) return;
    await Firebase.initializeApp(options: _optionsForCurrentPlatform);
  }

  static String get _appIdForCurrentPlatform {
    if (kIsWeb) return _webAppId;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _androidAppId,
      TargetPlatform.iOS || TargetPlatform.macOS => _iosAppId,
      _ => '',
    };
  }

  static FirebaseOptions get _optionsForCurrentPlatform {
    return FirebaseOptions(
      apiKey: _apiKey,
      appId: _appIdForCurrentPlatform,
      messagingSenderId: _senderId,
      projectId: _projectId,
      authDomain: _authDomain.isEmpty ? null : _authDomain,
      storageBucket: _storageBucket.isEmpty ? null : _storageBucket,
      iosBundleId: _iosBundleId.isEmpty ? null : _iosBundleId,
    );
  }
}
