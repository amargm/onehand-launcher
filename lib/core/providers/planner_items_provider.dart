import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/planner_item.dart';
import 'settings_provider.dart';

final plannerItemsProvider =
    StateNotifierProvider<PlannerItemsNotifier, List<PlannerItem>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PlannerItemsNotifier(prefs);
});

class PlannerItemsNotifier extends StateNotifier<List<PlannerItem>> {
  PlannerItemsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;
  static const _key = 'home_planner_items_v1';

  // Serialize asynchronous writes so an older snapshot cannot finish last
  // and overwrite a more recent planner mutation.
  Future<void> _saveQueue = Future<void>.value();

  static List<PlannerItem> _load(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(_key);
      if (raw == null) return const [];
      return (jsonDecode(raw) as List)
          .map((e) => PlannerItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Mutations update the current session immediately, then report whether
  /// persistence succeeded so the UI can offer an explicit retry.
  Future<bool> add(PlannerItem item) async {
    state = [...state, item];
    return _save();
  }

  Future<bool> toggleCompleted(String id) async {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(isCompleted: !item.isCompleted) else item,
    ];
    return _save();
  }

  Future<bool> remove(String id) async {
    state = state.where((item) => item.id != id).toList();
    return _save();
  }

  /// Retry persisting the current state after a previous failed write.
  Future<bool> persist() => _save();

  Future<bool> _save() {
    final snapshot = jsonEncode(state.map((e) => e.toJson()).toList());
    final result = Completer<bool>();

    _saveQueue = _saveQueue.then((_) async {
      try {
        result.complete(await _prefs.setString(_key, snapshot));
      } catch (_) {
        result.complete(false);
      }
    });

    return result.future;
  }
}
