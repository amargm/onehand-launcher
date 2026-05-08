import 'package:flutter/services.dart';

import '../models/app_info.dart';

/// Platform channel wrapper — replaces the discontinued `device_apps` package.
/// Communicates with the native `MethodChannel` in `MainActivity.kt`.
class AppsService {
  AppsService._();

  static const _channel = MethodChannel('com.onehand.onehand_launcher/apps');

  /// Returns all user-installed launchable apps, sorted alphabetically.
  static Future<List<AppInfo>> getInstalledApps() async {
    final raw = await _channel.invokeListMethod<Map>('getInstalledApps') ?? [];
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
  }

  /// Launches the app identified by [packageName].
  static Future<void> openApp(String packageName) async {
    await _channel.invokeMethod<void>('openApp', {'packageName': packageName});
  }
}
