import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_info.dart';
import '../services/apps_service.dart';

/// Loads all user-installed launchable apps with icons.
/// Uses a custom MethodChannel in MainActivity — no third-party dep.
final appsProvider = FutureProvider<List<AppInfo>>((ref) async {
  return AppsService.getInstalledApps();
});
