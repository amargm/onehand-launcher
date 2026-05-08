import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_provider.dart';

const _kPinnedKey = 'pinned_apps';

/// Maximum number of app slots in the 4×2 home grid.
const kHomeGridSlots = 8;

/// Ordered list of pinned package names (max 8, nulls = empty slot).
final pinnedAppsProvider =
    StateNotifierProvider<PinnedAppsNotifier, List<String?>>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return PinnedAppsNotifier(prefs);
    });

class PinnedAppsNotifier extends StateNotifier<List<String?>> {
  PinnedAppsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static List<String?> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_kPinnedKey);
    if (raw == null) return List.filled(kHomeGridSlots, null);
    try {
      final list = jsonDecode(raw) as List;
      final loaded = list.map((e) => e as String?).toList();
      // Always keep exactly 8 slots
      while (loaded.length < kHomeGridSlots) {
        loaded.add(null);
      }
      return loaded.take(kHomeGridSlots).toList();
    } catch (_) {
      return List.filled(kHomeGridSlots, null);
    }
  }

  void _persist() {
    _prefs.setString(_kPinnedKey, jsonEncode(state));
  }

  /// Pin [packageName] to the first empty slot, or replace slot at [index].
  void pin(String packageName, {int? index}) {
    // Don't pin duplicates
    if (state.contains(packageName)) return;
    final next = List<String?>.from(state);
    if (index != null && index < kHomeGridSlots) {
      next[index] = packageName;
    } else {
      final empty = next.indexOf(null);
      if (empty == -1) return; // all slots full
      next[empty] = packageName;
    }
    state = next;
    _persist();
  }

  /// Remove from home grid (slot becomes empty).
  void unpin(String packageName) {
    state = [
      for (final p in state)
        if (p == packageName) null else p,
    ];
    _persist();
  }

  /// Swap two slots (for drag-reorder).
  void swap(int a, int b) {
    final next = List<String?>.from(state);
    final tmp = next[a];
    next[a] = next[b];
    next[b] = tmp;
    state = next;
    _persist();
  }
}
