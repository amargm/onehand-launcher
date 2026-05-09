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

  static const _eventChannel = EventChannel(
    'com.onehand.onehand_launcher/headphone_events',
  );

  /// Stream of `true`/`false` pushed by a native BroadcastReceiver whenever
  /// an audio device is connected or disconnected.
  /// Zero battery cost when nothing changes; instant on plug/unplug.
  /// The first event is emitted immediately on subscribe with the current state.
  static Stream<bool> get headphoneEvents =>
      _eventChannel.receiveBroadcastStream().map((e) => e as bool);
}
