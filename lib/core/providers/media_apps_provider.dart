import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_info.dart';
import '../services/apps_service.dart';
import 'headphone_provider.dart';

/// Audio / media-player apps for the dock quick-launch strip.
///
/// Watches [headphoneProvider] reactively:
///   • headphones disconnected → returns [] immediately (no platform call).
///   • headphones connected    → fetches and caches up to 8 media apps.
///
/// Because this is a standard (non-autoDispose) FutureProvider, Riverpod
/// re-runs the async body only when the [headphoneProvider] dependency
/// changes — not on every rebuild.
final mediaAppsProvider = FutureProvider<List<AppInfo>>((ref) async {
  final connected = ref.watch(headphoneProvider);
  if (!connected) return const [];
  return AppsService.getMediaApps();
});
