import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/schedule_rule.dart';
import 'settings_provider.dart';

const _kScheduleRulesKey = 'schedule_rules_v1';

// ── Rules list ────────────────────────────────────────────────────────────────

final scheduleRulesProvider =
    StateNotifierProvider<ScheduleRulesNotifier, List<ScheduleRule>>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return ScheduleRulesNotifier(prefs);
    });

class ScheduleRulesNotifier extends StateNotifier<List<ScheduleRule>> {
  ScheduleRulesNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static List<ScheduleRule> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_kScheduleRulesKey);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => ScheduleRule.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  void _persist() => _prefs.setString(
    _kScheduleRulesKey,
    jsonEncode(state.map((r) => r.toJson()).toList()),
  );

  void add(ScheduleRule rule) {
    state = [...state, rule];
    _persist();
  }

  void update(ScheduleRule rule) {
    state = [for (final r in state) r.id == rule.id ? rule : r];
    _persist();
  }

  void remove(String id) {
    state = state.where((r) => r.id != id).toList();
    _persist();
  }

  void reorder(int oldIndex, int newIndex) {
    final list = [...state];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, item);
    state = list;
    _persist();
  }
}

// ── Minute tick (re-evaluates active rules every minute) ──────────────────────

final _scheduleTickProvider = StateNotifierProvider<_TickNotifier, DateTime>(
  (_) => _TickNotifier(),
);

class _TickNotifier extends StateNotifier<DateTime> {
  _TickNotifier() : super(DateTime.now()) {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) state = DateTime.now();
    });
  }

  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ── Derived: apps to show in the schedule context row ────────────────────────

/// Merged app list from all currently-active rules.
/// Slot-filled in priority order (list index), deduplicated, capped at 5.
final activeScheduleAppsProvider = Provider<List<String>>((ref) {
  final rules = ref.watch(scheduleRulesProvider);
  final now = ref.watch(_scheduleTickProvider);

  final seen = <String>{};
  final result = <String>[];

  for (final rule in rules) {
    if (!rule.isActiveNow(now)) continue;
    for (final pkg in rule.apps) {
      if (result.length >= kScheduleMaxApps) break;
      if (seen.add(pkg)) result.add(pkg);
    }
    if (result.length >= kScheduleMaxApps) break;
  }

  return result;
});

/// True when at least one schedule rule is active right now.
final isScheduleContextActiveProvider = Provider<bool>((ref) {
  final rules = ref.watch(scheduleRulesProvider);
  if (rules.isEmpty) return false;
  final now = ref.watch(_scheduleTickProvider);
  return rules.any((r) => r.isActiveNow(now));
});
