import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_provider.dart';

const _kPrefKey = 'recent_apps';
const _kMaxCount = 5;

/// Tracks the [_kMaxCount] most-recently-launched apps by package name.
/// Backed by SharedPreferences so it survives app restarts.
/// Uses the injected [sharedPreferencesProvider] (same instance as all other
/// providers) to avoid a separate async getInstance() call on every persist.
final recentAppsProvider =
    StateNotifierProvider<RecentAppsNotifier, List<String>>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return RecentAppsNotifier(prefs);
    });

class RecentAppsNotifier extends StateNotifier<List<String>> {
  RecentAppsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static List<String> _load(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(_kPrefKey);
      if (raw == null) return const [];
      return (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      return const [];
    }
  }

  /// Inserts [packageName] at the front, deduplicates, trims to [_kMaxCount].
  void recordLaunch(String packageName) {
    state =
        [
          packageName,
          ...state.where((p) => p != packageName),
        ].take(_kMaxCount).toList();
    _prefs.setString(_kPrefKey, jsonEncode(state));
  }
}
