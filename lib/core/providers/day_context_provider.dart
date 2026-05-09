import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Day-of-week context shell
//
// Users can select specific weekdays (1 = Mon … 7 = Sun per DateTime.weekday)
// and pin up to [kDayContextMaxApps] apps to a dedicated row that appears
// inside the outer context shell whenever the current day matches one of the
// selected days.
//
// If headphones are also connected the shell shows:
//   Row 1 (top)   — day-of-week apps
//   Row 2 (bottom)— headphone apps
// ─────────────────────────────────────────────────────────────────────────────

const _kDayContextEnabledKey = 'day_context_enabled';
const _kDayContextDaysKey = 'day_context_days_v1';
const _kDayContextAppsKey = 'day_context_apps_v1';

/// Maximum apps in the day-of-week context row.
const kDayContextMaxApps = 5;

// ── Enabled toggle ────────────────────────────────────────────────────────────

final dayContextEnabledProvider = StateNotifierProvider<_BoolNotifier, bool>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return _BoolNotifier(prefs);
});

class _BoolNotifier extends StateNotifier<bool> {
  _BoolNotifier(this._prefs)
    : super(_prefs.getBool(_kDayContextEnabledKey) ?? false);

  final SharedPreferences _prefs;

  void set(bool value) {
    state = value;
    _prefs.setBool(_kDayContextEnabledKey, value);
  }
}

// ── Selected weekdays (Set<int>, 1=Mon … 7=Sun) ───────────────────────────────

final dayContextDaysProvider =
    StateNotifierProvider<DayContextDaysNotifier, Set<int>>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return DayContextDaysNotifier(prefs);
    });

class DayContextDaysNotifier extends StateNotifier<Set<int>> {
  DayContextDaysNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static Set<int> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_kDayContextDaysKey);
    if (raw == null) return const {};
    try {
      return Set<int>.from((jsonDecode(raw) as List).cast<int>());
    } catch (_) {
      return const {};
    }
  }

  void toggle(int weekday) {
    final next = Set<int>.from(state);
    if (next.contains(weekday)) {
      next.remove(weekday);
    } else {
      next.add(weekday);
    }
    state = next;
    _persist();
  }

  void _persist() {
    _prefs.setString(_kDayContextDaysKey, jsonEncode(state.toList()));
  }
}

// ── Day-context app list ──────────────────────────────────────────────────────

final dayContextAppsProvider =
    StateNotifierProvider<DayContextAppsNotifier, List<String>>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return DayContextAppsNotifier(prefs);
    });

class DayContextAppsNotifier extends StateNotifier<List<String>> {
  DayContextAppsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static List<String> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_kDayContextAppsKey);
    if (raw == null) return const [];
    try {
      return List<String>.from(jsonDecode(raw) as List);
    } catch (_) {
      return const [];
    }
  }

  void _persist() => _prefs.setString(_kDayContextAppsKey, jsonEncode(state));

  void add(String packageName) {
    if (state.contains(packageName)) return;
    if (state.length >= kDayContextMaxApps) return;
    state = [...state, packageName];
    _persist();
  }

  void remove(String packageName) {
    state = state.where((p) => p != packageName).toList();
    _persist();
  }
}

// ── Derived: is today one of the selected days? ───────────────────────────────

/// Returns true when the feature is enabled AND the current weekday is in the
/// user's selected set. Recomputed whenever either provider changes.
final isDayContextActiveProvider = Provider<bool>((ref) {
  final enabled = ref.watch(dayContextEnabledProvider);
  if (!enabled) return false;
  final days = ref.watch(dayContextDaysProvider);
  if (days.isEmpty) return false;
  return days.contains(DateTime.now().weekday);
});
