import 'dart:typed_data';

/// Represents a single installed app.
class AppInfo {
  const AppInfo({required this.packageName, required this.appName, this.icon});

  final String packageName;
  final String appName;
  final Uint8List? icon;
}
