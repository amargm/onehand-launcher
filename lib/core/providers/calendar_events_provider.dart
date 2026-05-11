import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/calendar_event.dart';
import 'settings_provider.dart';

// ── Persisted country code ────────────────────────────────────────────────────

final calCountryCodeProvider = StateNotifierProvider<_CountryNotifier, String?>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return _CountryNotifier(prefs);
  },
);

class _CountryNotifier extends StateNotifier<String?> {
  _CountryNotifier(this._prefs) : super(_prefs.getString('cal_country_code'));

  final SharedPreferences _prefs;

  void set(String cc) {
    state = cc.toUpperCase();
    _prefs.setString('cal_country_code', state!);
  }

  void clear() {
    state = null;
    _prefs.remove('cal_country_code');
  }
}

// ── User-created events ───────────────────────────────────────────────────────

final userEventsProvider =
    StateNotifierProvider<UserEventsNotifier, List<CalendarEvent>>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return UserEventsNotifier(prefs);
    });

class UserEventsNotifier extends StateNotifier<List<CalendarEvent>> {
  UserEventsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;
  static const _kKey = 'cal_user_events';

  static List<CalendarEvent> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_kKey);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  void add(CalendarEvent event) {
    final updated = [...state, event];
    state = updated;
    _save(updated);
  }

  void remove(String id) {
    final updated = state.where((e) => e.id != id).toList();
    state = updated;
    _save(updated);
  }

  void _save(List<CalendarEvent> events) {
    _prefs.setString(_kKey, jsonEncode(events.map((e) => e.toJson()).toList()));
  }
}
