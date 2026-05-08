import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_provider.dart';

const _kContextItemsKey = 'context_items_v1';

/// All available context indicator types shown in the top pill row.
enum ContextItemType {
  time,
  headphone,
  day,
  date;

  String get displayLabel {
    switch (this) {
      case time:
        return 'Time context';
      case headphone:
        return 'Headphones';
      case day:
        return 'Day of week';
      case date:
        return 'Date';
    }
  }
}

/// Which context items are currently enabled (shown in the top row).
/// Defaults to all 4 enabled.
final contextItemsProvider =
    StateNotifierProvider<ContextItemsNotifier, Set<ContextItemType>>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return ContextItemsNotifier(prefs);
    });

class ContextItemsNotifier extends StateNotifier<Set<ContextItemType>> {
  ContextItemsNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static Set<ContextItemType> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_kContextItemsKey);
    if (raw == null) return Set.from(ContextItemType.values);
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map(
            (e) => ContextItemType.values.firstWhere(
              (t) => t.name == e,
              orElse: () => ContextItemType.time,
            ),
          )
          .toSet();
    } catch (_) {
      return Set.from(ContextItemType.values);
    }
  }

  void toggle(ContextItemType item) {
    final next = Set<ContextItemType>.from(state);
    if (next.contains(item)) {
      next.remove(item);
    } else {
      next.add(item);
    }
    state = next;
    _persist();
  }

  void _persist() {
    _prefs.setString(
      _kContextItemsKey,
      jsonEncode(state.map((e) => e.name).toList()),
    );
  }
}
