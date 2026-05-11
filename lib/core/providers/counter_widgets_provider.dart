import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/counter_widget_model.dart';
import 'settings_provider.dart';

const _kCounterWidgets = 'counter_widgets';

final counterWidgetsProvider =
    StateNotifierProvider<CounterWidgetsNotifier, List<CounterWidgetModel>>(
      (ref) => CounterWidgetsNotifier(ref.watch(sharedPreferencesProvider)),
    );

class CounterWidgetsNotifier extends StateNotifier<List<CounterWidgetModel>> {
  CounterWidgetsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static List<CounterWidgetModel> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_kCounterWidgets);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => CounterWidgetModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void _save() => _prefs.setString(
    _kCounterWidgets,
    jsonEncode(state.map((e) => e.toJson()).toList()),
  );

  void add(CounterWidgetModel widget) {
    state = [...state, widget];
    _save();
  }

  void increment(String id) {
    state = [
      for (final w in state)
        if (w.id == id) w.copyWith(count: w.count + 1) else w,
    ];
    _save();
  }

  void decrement(String id) {
    state = [
      for (final w in state)
        if (w.id == id) w.copyWith(count: w.count - 1) else w,
    ];
    _save();
  }

  void reset(String id) {
    state = [
      for (final w in state)
        if (w.id == id) w.copyWith(count: 0) else w,
    ];
    _save();
  }

  void remove(String id) {
    state = state.where((w) => w.id != id).toList();
    _save();
  }

  void updateNote(String id, String note) {
    state = [
      for (final w in state)
        if (w.id == id) w.copyWith(note: note) else w,
    ];
    _save();
  }
}
