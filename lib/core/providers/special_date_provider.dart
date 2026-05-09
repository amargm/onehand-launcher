import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/special_date_event.dart';
import 'settings_provider.dart';

const _kEventsKey = 'special_date_events_v1';
const _kDismissedKey = 'special_date_dismissed_v1';
const _kSnoozeUntilKey = 'special_date_snooze_v1';

// -- Event list -------------------------------------------------------------

final specialDateEventsProvider =
    StateNotifierProvider<SpecialDateEventsNotifier, List<SpecialDateEvent>>((
      ref,
    ) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return SpecialDateEventsNotifier(prefs);
    });

class SpecialDateEventsNotifier extends StateNotifier<List<SpecialDateEvent>> {
  SpecialDateEventsNotifier(this._prefs)
    : super(
        SpecialDateEvent.listFromJsonString(
          _prefs.getString(_kEventsKey) ?? '',
        ),
      );

  final SharedPreferences _prefs;

  void add(SpecialDateEvent event) {
    state = [...state, event];
    _save();
  }

  void update(SpecialDateEvent event) {
    state = [for (final e in state) e.id == event.id ? event : e];
    _save();
  }

  void remove(String id) {
    state = state.where((e) => e.id != id).toList();
    _save();
  }

  void _save() =>
      _prefs.setString(_kEventsKey, SpecialDateEvent.listToJsonString(state));
}

// -- 1-minute tick ----------------------------------------------------------

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

final _specialTickProvider = StateNotifierProvider<_TickNotifier, DateTime>(
  (_) => _TickNotifier(),
);

// -- Dismiss state ----------------------------------------------------------

final _dismissedProvider =
    StateNotifierProvider<_DismissedNotifier, Map<String, int>>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return _DismissedNotifier(prefs);
    });

class _DismissedNotifier extends StateNotifier<Map<String, int>> {
  _DismissedNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static Map<String, int> _load(SharedPreferences p) {
    try {
      final raw = p.getString(_kDismissedKey) ?? '{}';
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as int));
    } catch (_) {
      return {};
    }
  }

  void dismiss(String id, int year) {
    state = {...state, id: year};
    _prefs.setString(_kDismissedKey, json.encode(state));
  }

  bool isDismissedForYear(String id, int year) => state[id] == year;
}

// -- Snooze state -----------------------------------------------------------

final _snoozeProvider =
    StateNotifierProvider<_SnoozeNotifier, Map<String, DateTime>>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return _SnoozeNotifier(prefs);
    });

class _SnoozeNotifier extends StateNotifier<Map<String, DateTime>> {
  _SnoozeNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static Map<String, DateTime> _load(SharedPreferences p) {
    try {
      final raw = p.getString(_kSnoozeUntilKey) ?? '{}';
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, DateTime.parse(v as String)));
    } catch (_) {
      return {};
    }
  }

  void snooze(String id, int minutes) {
    final until = DateTime.now().add(Duration(minutes: minutes));
    state = {...state, id: until};
    _prefs.setString(
      _kSnoozeUntilKey,
      json.encode(state.map((k, v) => MapEntry(k, v.toIso8601String()))),
    );
  }

  bool isSnoozed(String id) {
    final until = state[id];
    if (until == null) return false;
    return DateTime.now().isBefore(until);
  }
}

// -- Active events ----------------------------------------------------------

final activeSpecialDateEventsProvider = Provider<List<SpecialDateEvent>>((ref) {
  final now = ref.watch(_specialTickProvider);
  final events = ref.watch(specialDateEventsProvider);
  // Watch the state maps directly so the provider rebuilds immediately after
  // dismiss/snooze — watching .notifier gives a stable object that never
  // triggers a rebuild.
  final dismissedMap = ref.watch(_dismissedProvider);
  final snoozeMap = ref.watch(_snoozeProvider);

  return events.where((e) {
    if (!e.isToday(now)) return false;
    // 9999 is used as a permanent dismissal year for non-recurring events.
    final dismissedYear = dismissedMap[e.id];
    if (dismissedYear == 9999 || dismissedYear == now.year) return false;
    final until = snoozeMap[e.id];
    if (until != null && DateTime.now().isBefore(until)) return false;
    return true;
  }).toList();
});

final hasActiveSpecialDateProvider = Provider<bool>((ref) {
  return ref.watch(activeSpecialDateEventsProvider).isNotEmpty;
});

// -- Public action helpers --------------------------------------------------

void dismissSpecialDate(WidgetRef ref, SpecialDateEvent event) {
  // Non-recurring: use 9999 as a permanent year so it is never shown again.
  // Recurring: use current year so it shows again next year.
  final year = event.isRecurring ? DateTime.now().year : 9999;
  ref.read(_dismissedProvider.notifier).dismiss(event.id, year);
}

void snoozeSpecialDate(
  WidgetRef ref,
  SpecialDateEvent event,
  int globalDefaultMins,
) {
  final mins =
      event.snoozeMinutes > 0 ? event.snoozeMinutes : globalDefaultMins;
  ref.read(_snoozeProvider.notifier).snooze(event.id, mins);
}
