import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_provider.dart';

const _kContextShellAppsKey = 'context_shell_apps_v1';

/// Maximum apps shown in the context outer shell.
const kContextShellMaxApps = 4;

/// Ordered list of up to [kContextShellMaxApps] package names shown in the
/// context outer shell when headphones or Bluetooth are connected.
/// Configured by the user in Settings → Context shell.
final contextShellAppsProvider =
    StateNotifierProvider<ContextShellAppsNotifier, List<String>>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return ContextShellAppsNotifier(prefs);
    });

class ContextShellAppsNotifier extends StateNotifier<List<String>> {
  ContextShellAppsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static List<String> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_kContextShellAppsKey);
    if (raw == null) return const [];
    try {
      return List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return const [];
    }
  }

  void _persist() =>
      _prefs.setString(_kContextShellAppsKey, jsonEncode(state));

  void add(String packageName) {
    if (state.contains(packageName)) return;
    if (state.length >= kContextShellMaxApps) return;
    state = [...state, packageName];
    _persist();
  }

  void remove(String packageName) {
    state = state.where((p) => p != packageName).toList();
    _persist();
  }
}
