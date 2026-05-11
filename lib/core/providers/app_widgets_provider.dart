import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/placed_android_widget.dart';
import '../providers/settings_provider.dart';

const _kPlacedWidgets = 'placed_android_widgets';

// ── Provider ──────────────────────────────────────────────────────────────────

final placedAndroidWidgetsProvider = StateNotifierProvider<
    PlacedAndroidWidgetsNotifier, List<PlacedAndroidWidget>>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return PlacedAndroidWidgetsNotifier(prefs);
  },
);

// ── Notifier ──────────────────────────────────────────────────────────────────

class PlacedAndroidWidgetsNotifier
    extends StateNotifier<List<PlacedAndroidWidget>> {
  PlacedAndroidWidgetsNotifier(SharedPreferences prefs)
      : _prefs = prefs,
        super(_load(prefs));

  final SharedPreferences _prefs;

  static List<PlacedAndroidWidget> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_kPlacedWidgets);
    if (raw == null || raw.isEmpty) return [];
    try {
      return PlacedAndroidWidget.decodeList(raw);
    } catch (_) {
      return [];
    }
  }

  void add(PlacedAndroidWidget widget) {
    state = [...state, widget];
    _persist();
  }

  void remove(int appWidgetId) {
    state = state.where((w) => w.appWidgetId != appWidgetId).toList();
    _persist();
  }

  void _persist() {
    _prefs.setString(_kPlacedWidgets, PlacedAndroidWidget.encodeList(state));
  }
}
