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

  void add(PlannerItem item) {
    state = [...state, item];
    _save();
  }

  void toggleCompleted(String id) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(isCompleted: !item.isCompleted) else item,
    ];
    _save();
  }

  void remove(String id) {
    state = state.where((item) => item.id != id).toList();
    _save();
  }

  void _save() {
    _prefs.setString(_key, jsonEncode(state.map((e) => e.toJson()).toList()));
  }
}
