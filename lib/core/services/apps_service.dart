import 'package:flutter/services.dart';

import '../models/app_info.dart';

/// Platform channel wrapper — replaces the discontinued `device_apps` package.
/// Communicates with the native `MethodChannel` in `MainActivity.kt`.
class AppsService {
  AppsService._();

  static const _channel = MethodChannel('com.onehand.onehand_launcher/apps');

  /// Returns all user-installed launchable apps, sorted alphabetically.
  static Future<List<AppInfo>> getInstalledApps() async {
    try {
      final raw =
          await _channel.invokeListMethod<Map>('getInstalledApps') ?? [];
      return raw.map((e) {
        final iconRaw = e['icon'];
        final Uint8List? icon = switch (iconRaw) {
          Uint8List u => u,
          List<Object?> l => Uint8List.fromList(l.cast<int>()),
          _ => null,
        };
        return AppInfo(
          packageName: e['packageName'] as String,
          appName: e['appName'] as String,
          icon: icon,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Launches the app identified by [packageName].
  /// Silently ignores failures (e.g. app uninstalled between list load and tap).
  static Future<void> openApp(String packageName) async {
    try {
      await _channel.invokeMethod<void>('openApp', {
        'packageName': packageName,
      });
    } catch (_) {}
  }

  /// Opens the system uninstall dialog for [packageName].
  static Future<void> requestUninstall(String packageName) async {
    try {
      await _channel.invokeMethod<void>('uninstallApp', {
        'packageName': packageName,
      });
    } catch (_) {}
  }

  /// Opens the Android App Info screen (Settings → Apps → [app]) for
  /// [packageName] — equivalent to the (i) button in stock launchers.
  static Future<void> openAppInfo(String packageName) async {
    try {
      await _channel.invokeMethod<void>('openAppInfo', {
        'packageName': packageName,
      });
    } catch (_) {}
  }

  /// Opens the default browser with the address / search bar focused and
  /// the software keyboard raised — triggered by long-pressing the search
  /// circle on the dock.
  static Future<void> openBrowserSearch() async {
    try {
      await _channel.invokeMethod<void>('openBrowserSearch');
    } catch (_) {}
  }

  /// Opens [url] in the default browser.
  static Future<void> openUrl(String url) async {
    try {
      await _channel.invokeMethod<void>('openUrl', {'url': url});
    } catch (_) {}
  }

  /// Triggers a light haptic impulse that bypasses the device's silent /
  /// DND / vibrate-only setting. Uses Android's FLAG_IGNORE_GLOBAL_SETTING
  /// so it fires in every ringer mode.
  static Future<void> forceHaptic() async {
    try {
      await _channel.invokeMethod<void>('forceHaptic');
    } catch (_) {}
  }

  /// Returns apps that can play audio (music players, podcast apps, etc.).
  /// Used to populate the quick-launch strip when headphones are connected.
  static Future<List<AppInfo>> getMediaApps() async {
    try {
      final raw = await _channel.invokeListMethod<Map>('getMediaApps') ?? [];
      return raw
          .map((e) {
            final iconRaw = e['icon'];
            final Uint8List? icon = switch (iconRaw) {
              Uint8List u => u,
              List<Object?> l => Uint8List.fromList(l.cast<int>()),
              _ => null,
            };
            return AppInfo(
              packageName: e['packageName'] as String? ?? '',
              appName: e['appName'] as String? ?? '',
              icon: icon,
            );
          })
          .where((a) => a.packageName.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Downloads [imageBytes] and passes them to Android's WallpaperManager.
  /// Throws on failure so the caller can show an error to the user.
  static Future<void> setWallpaper(Uint8List imageBytes) async {
    await _channel.invokeMethod<void>('setWallpaper', {'bytes': imageBytes});
  }
}
