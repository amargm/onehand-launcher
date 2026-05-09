import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

const _kAccentColorKey = 'accent_color';
const _kShowFolderLabels = 'show_folder_labels';
const _kShowSearchLabel = 'show_search_label';
const _kRightHanded = 'right_handed';
const _kSnoozeDurationMins = 'snooze_duration_mins';

/// Injected at app startup — see main.dart.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) =>
      throw UnimplementedError(
        'Override sharedPreferencesProvider in ProviderScope',
      ),
);

/// Accent color used throughout the UI.
final accentColorProvider = StateNotifierProvider<AccentColorNotifier, Color>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AccentColorNotifier(prefs);
});

class AccentColorNotifier extends StateNotifier<Color> {
  AccentColorNotifier(this._prefs)
    : super(
        Color(
          _prefs.getInt(_kAccentColorKey) ?? AppTheme.defaultAccent.toARGB32(),
        ),
      );

  final SharedPreferences _prefs;

  void setColor(Color color) {
    state = color;
    _prefs.setInt(_kAccentColorKey, color.toARGB32());
  }
}

// ── Dock label visibility ──────────────────────────────────────────────────

/// Whether folder name labels are shown beneath dock buttons.
final showFolderLabelsProvider = StateNotifierProvider<_BoolNotifier, bool>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return _BoolNotifier(prefs, _kShowFolderLabels, defaultValue: false);
});

/// Whether the "Search" label is shown beneath the search button.
final showSearchLabelProvider = StateNotifierProvider<_BoolNotifier, bool>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return _BoolNotifier(prefs, _kShowSearchLabel, defaultValue: false);
});

class _BoolNotifier extends StateNotifier<bool> {
  _BoolNotifier(this._prefs, this._key, {required bool defaultValue})
    : super(_prefs.getBool(_key) ?? defaultValue);

  final SharedPreferences _prefs;
  final String _key;

  void toggle() => _set(!state);

  void set(bool value) => _set(value);

  void _set(bool value) {
    state = value;
    _prefs.setBool(_key, value);
  }
}

// ── Handedness ─────────────────────────────────────────────────────────────

/// `true` = right-handed (search rightmost, default).
/// `false` = left-handed (search leftmost).
final rightHandedProvider = StateNotifierProvider<_BoolNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return _BoolNotifier(prefs, _kRightHanded, defaultValue: true);
});

// ── Clock format ───────────────────────────────────────────────────────────

const _kUse24HourClock = 'use_24_hour_clock';

/// `true` = 24-hour display (default). `false` = 12-hour (AM/PM).
final use24HourClockProvider = StateNotifierProvider<_BoolNotifier, bool>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return _BoolNotifier(prefs, _kUse24HourClock, defaultValue: true);
});

// ── Wallpaper ──────────────────────────────────────────────────────────────

const _kWallpaperPath = 'wallpaper_path';
const _kWallpaperVersion = 'wallpaper_version';

/// Holds the local wallpaper path plus a monotonic version counter.
/// The version is incremented on every [set] call so the widget tree always
/// gets a new value — even when the file path doesn't change — which forces
/// [Image.file] to evict its cache and redraw with the new bytes.
typedef WallpaperState = ({String? path, int version});

final wallpaperPathProvider =
    StateNotifierProvider<_WallpaperNotifier, WallpaperState>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return _WallpaperNotifier(prefs);
    });

class _WallpaperNotifier extends StateNotifier<WallpaperState> {
  _WallpaperNotifier(this._prefs)
    : super((
        path: _prefs.getString(_kWallpaperPath),
        version: _prefs.getInt(_kWallpaperVersion) ?? 0,
      ));

  final SharedPreferences _prefs;

  void set(String path) {
    final v = state.version + 1;
    state = (path: path, version: v);
    _prefs.setString(_kWallpaperPath, path);
    _prefs.setInt(_kWallpaperVersion, v);
  }

  void clear() {
    state = (path: null, version: state.version + 1);
    _prefs.remove(_kWallpaperPath);
  }
}

// ── Special-date snooze duration ───────────────────────────────────────────

/// Global default snooze duration in minutes (default 30).
/// Can be overridden per-event in the event's own snoozeMinutes field.
final snoozeDurationProvider = StateNotifierProvider<_IntNotifier, int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return _IntNotifier(prefs, _kSnoozeDurationMins, defaultValue: 30);
});

/// Transient UI flag — true while the search overlay is open.
/// Watched by the home screen clock to fade in/out in sync with the overlay.
final searchOverlayActiveProvider = StateProvider<bool>((ref) => false);

class _IntNotifier extends StateNotifier<int> {
  _IntNotifier(this._prefs, this._key, {required int defaultValue})
    : super(_prefs.getInt(_key) ?? defaultValue);

  final SharedPreferences _prefs;
  final String _key;

  void set(int value) {
    state = value;
    _prefs.setInt(_key, value);
  }
}
