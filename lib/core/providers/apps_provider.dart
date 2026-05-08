import 'package:device_apps/device_apps.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_info.dart';

/// Loads all user-installed launchable apps with icons.
final appsProvider = FutureProvider<List<AppInfo>>((ref) async {
  final raw = await DeviceApps.getInstalledApplications(
    includeAppIcons: true,
    includeSystemApps: false,
    onlyAppsWithLaunchIntent: true,
  );

  final apps =
      raw.map((app) {
          final icon = app is ApplicationWithIcon ? app.icon : null;
          return AppInfo(
            packageName: app.packageName,
            appName: app.appName,
            icon: icon,
          );
        }).toList()
        ..sort(
          (a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()),
        );

  return apps;
});
