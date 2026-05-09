import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPrefKey = 'recent_apps';
const _kMaxCount = 5;

/// Tracks the [_kMaxCount] most-recently-launched apps by package name.
/// Backed by SharedPreferences so it survives app restarts.
final recentAppsProvider =
    StateNotifierProvider<RecentAppsNotifier, List<String>>((ref) {
  return RecentAppsNotifier();
});

class RecentAppsNotifier extends StateNotifier<List<String>> {
  RecentAppsNotifier() : super(const []) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrefKey);
    if (raw != null && mounted) {
      state = (jsonDecode(raw) as List).cast<String>();
    }
  }

  /// Inserts [packageName] at the front, deduplicates, trims to [_kMaxCount].
  void recordLaunch(String packageName) {
    state = [
      packageName,
      ...state.where((p) => p != packageName),
    ].take(_kMaxCount).toList();
    _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefKey, jsonEncode(state));
  }
}
