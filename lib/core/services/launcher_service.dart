import 'package:flutter/services.dart';

/// Dart-side wrapper for launcher-role operations.
/// Backed by the 'com.onehand.onehand_launcher/launcher' MethodChannel
/// implemented in MainActivity.kt.
class LauncherService {
  LauncherService._();

  static const _channel = MethodChannel(
    'com.onehand.onehand_launcher/launcher',
  );

  /// Returns `true` when this app is currently the default home screen.
  static Future<bool> isDefaultLauncher() async {
    return await _channel.invokeMethod<bool>('isDefaultLauncher') ?? false;
  }

  /// Opens the system UI that lets the user choose this app as home.
  static Future<void> requestDefaultLauncher() async {
    await _channel.invokeMethod<void>('requestDefaultLauncher');
  }

  /// Returns `true` when wired or Bluetooth headphones are connected.
  static Future<bool> isHeadphoneConnected() async {
    return await _channel.invokeMethod<bool>('isHeadphoneConnected') ?? false;
  }
}
