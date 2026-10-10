import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_provider.dart';

const _kFavoriteAppsKey = 'favorite_apps_v1';

/// Ordered list of favorite app package names, persisted on this device.
final favoriteAppsProvider =
    StateNotifierProvider<FavoriteAppsNotifier, List<String>>((ref) {
  return FavoriteAppsNotifier(ref.watch(sharedPreferencesProvider));
});

class FavoriteAppsNotifier extends StateNotifier<List<String>> {
  FavoriteAppsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static List<String> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_kFavoriteAppsKey);
    if (raw == null) return const [];
    try {
      final values = (jsonDecode(raw) as List).cast<String>();
      return values.toSet().toList();
    } catch (_) {
      return const [];
    }
  }

  void toggle(String packageName) {
    if (state.contains(packageName)) {
      state = state.where((item) => item != packageName).toList();
    } else {
      state = [...state, packageName];
    }
    _persist();
  }

  /// Moves a favorite one position earlier (-1) or later (+1).
  void move(String packageName, int offset) {
    final from = state.indexOf(packageName);
    final step = offset < 0 ? -1 : 1;
    final to = from + step;
    if (from < 0 || to < 0 || to >= state.length || offset == 0) return;
    final next = [...state];
    final item = next.removeAt(from);
    next.insert(to, item);
    state = next;
    _persist();
  }

  void _persist() {
    _prefs.setString(_kFavoriteAppsKey, jsonEncode(state));
  }
}
