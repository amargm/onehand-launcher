import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/calendar_event.dart';

/// Handles country detection (via GPS + Nominatim) and holiday fetching
/// (via Nager.Date). All network results are cached in SharedPreferences so
/// subsequent calls are instant and work offline.
class HolidaysService {
  static const _kCountryCode = 'cal_country_code';

  // ── Country detection ────────────────────────────────────────────────────

  /// Returns the two-letter ISO country code (uppercase) or null if:
  ///  • location permission was denied
  ///  • GPS timed out
  ///  • reverse geocode failed
  ///
  /// A successful result is cached in SharedPreferences so this is truly
  /// one-time on subsequent launches.
  static Future<String?> detectCountryCode(SharedPreferences prefs) async {
    // Return cached value immediately
    final cached = prefs.getString(_kCountryCode);
    if (cached != null && cached.length == 2) return cached;

    // Check / request permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    // Make sure the device location service is on
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    // Get coarse position
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      ).timeout(const Duration(seconds: 12));
    } catch (_) {
      return null;
    }

    // Reverse geocode via Nominatim (zoom=3 = country level)
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=json'
        '&lat=${position.latitude}'
        '&lon=${position.longitude}'
        '&zoom=3',
      );
      final response = await http
          .get(
            uri,
            headers: {
              'User-Agent': 'OneHandLauncher/1.0',
              'Accept-Language': 'en',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final cc = (data['address']?['country_code'] as String?)?.toUpperCase();
        if (cc != null && cc.length == 2) {
          await prefs.setString(_kCountryCode, cc);
          return cc;
        }
      }
    } catch (_) {
      // Gracefully degrade — caller will show the country picker
    }
    return null;
  }

  /// Persist a manually selected country code (from the picker dialog).
  static Future<void> setCountryCode(SharedPreferences prefs, String cc) async {
    await prefs.setString(_kCountryCode, cc.toUpperCase());
  }

  // ── Holiday fetching ──────────────────────────────────────────────────────

  static String _cacheKey(int year, String cc) => 'cal_holidays_${year}_$cc';

  /// Returns holidays for [year]+[countryCode]. Uses cache if available;
  /// falls through to the network on first call or after [refreshHolidays].
  static Future<List<CalendarEvent>> fetchHolidays(
    int year,
    String countryCode,
    SharedPreferences prefs,
  ) async {
    final cached = prefs.getString(_cacheKey(year, countryCode));
    if (cached != null) {
      try {
        final list = jsonDecode(cached) as List;
        return list
            .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        // Corrupted cache — re-download
      }
    }
    return _download(year, countryCode, prefs);
  }

  /// Forces a fresh download, bypassing and overwriting the cache.
  static Future<List<CalendarEvent>> refreshHolidays(
    int year,
    String countryCode,
    SharedPreferences prefs,
  ) => _download(year, countryCode, prefs);

  // ── Download orchestration ────────────────────────────────────────────────

  /// Tries both APIs, caches on first success, returns [] (no error)
  /// when the country is simply not in any API database.
  static Future<List<CalendarEvent>> _download(
    int year,
    String countryCode,
    SharedPreferences prefs,
  ) async {
    Exception? primaryError;

    // ── 1. Nager.Date (primary — 115+ countries) ─────────────────────────
    try {
      final events = await _tryNager(year, countryCode);
      if (events != null) {
        _cache(prefs, year, countryCode, events);
        return events;
      }
      // null = 404 = country not in Nager → try backup
    } catch (e) {
      primaryError = _wrap(e);
      // Network / server error — still try backup before giving up
    }

    // ── 2. OpenHolidays (backup — ~50 mostly European countries) ─────────
    try {
      final events = await _tryOpenHolidays(year, countryCode);
      if (events != null) {
        _cache(prefs, year, countryCode, events);
        return events;
      }
      // null = country not in OpenHolidays either
      if (primaryError != null) {
        // Nager had a network error and OpenHolidays has no data → throw
        throw primaryError;
      }
      // Both APIs confirmed: no data for this country → empty, not an error
      return const [];
    } catch (e) {
      // OpenHolidays network error — surface best available error
      throw primaryError ?? _wrap(e);
    }
  }

  // ── Nager.Date ────────────────────────────────────────────────────────────
  // Returns null  → country not in database (HTTP 404)
  // Returns list  → data found (may be empty for countries with no public holidays)
  // Throws        → network / server problem

  static Future<List<CalendarEvent>?> _tryNager(
    int year,
    String countryCode,
  ) async {
    final uri = Uri.parse(
      'https://date.nager.at/api/v3/PublicHolidays/$year/$countryCode',
    );
    final http.Response response;
    try {
      response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));
    } catch (e) {
      throw _networkException(e);
    }

    if (response.statusCode == 404) return null; // country not in Nager
    if (response.statusCode != 200) {
      throw Exception(
        'Holiday service temporarily unavailable. Try again later.',
      );
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! List) return null; // unexpected body = treat as missing
      final events = <CalendarEvent>[];
      for (final item in decoded) {
        try {
          if (item is! Map) continue;
          final m = Map<String, dynamic>.from(item);
          final dateStr = m['date'] as String?;
          if (dateStr == null || dateStr.isEmpty) continue;
          final name =
              (m['localName'] as String?)?.isNotEmpty == true
                  ? m['localName'] as String
                  : (m['name'] as String? ?? '');
          if (name.isEmpty) continue;
          events.add(
            CalendarEvent(
              id: 'holiday_${countryCode}_$dateStr',
              date: DateTime.parse(dateStr),
              name: name,
              isPublicHoliday: true,
            ),
          );
        } catch (_) {
          continue; // skip malformed entries
        }
      }
      return events; // may be empty — that's valid (country has no public holidays)
    } on FormatException {
      throw Exception('Received invalid data from holiday service.');
    }
  }

  // ── OpenHolidays API ──────────────────────────────────────────────────────
  // Returns null  → country not in database (404, 400, or empty response)
  // Returns list  → data found (non-empty)
  // Throws        → network / server problem

  static Future<List<CalendarEvent>?> _tryOpenHolidays(
    int year,
    String countryCode,
  ) async {
    final uri = Uri.parse(
      'https://openholidaysapi.org/PublicHolidays'
      '?countryIsoCode=$countryCode'
      '&languageIsoCode=EN'
      '&validFrom=$year-01-01'
      '&validTo=$year-12-31',
    );
    final http.Response response;
    try {
      response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));
    } catch (e) {
      throw _networkException(e);
    }

    // 400/404 = country not in this database
    if (response.statusCode == 400 || response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception('Backup holiday service temporarily unavailable.');
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! List || decoded.isEmpty) {
        return null; // country not in OpenHolidays
      }

      final events = <CalendarEvent>[];
      for (final item in decoded) {
        try {
          if (item is! Map) continue;
          final m = Map<String, dynamic>.from(item);
          final dateStr = m['startDate'] as String?;
          if (dateStr == null || dateStr.isEmpty) continue;

          // name is [{language: "EN", text: "..."}, ...]
          // Use whereType<Map> to avoid cast exceptions on different Map types
          final nameList = m['name'];
          final names =
              nameList is List ? nameList.whereType<Map>().toList() : <Map>[];

          String name = '';
          if (names.isNotEmpty) {
            final en = names.firstWhere(
              (n) => (n['language'] as String? ?? '').toUpperCase() == 'EN',
              orElse: () => names.first,
            );
            name = (en['text'] as String?) ?? '';
          }
          if (name.isEmpty) continue;

          events.add(
            CalendarEvent(
              id: 'holiday_${countryCode}_$dateStr',
              date: DateTime.parse(dateStr),
              name: name,
              isPublicHoliday: true,
            ),
          );
        } catch (_) {
          continue; // skip malformed entries
        }
      }
      return events.isEmpty ? null : events;
    } on FormatException {
      throw Exception('Received invalid data from backup holiday service.');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static void _cache(
    SharedPreferences prefs,
    int year,
    String cc,
    List<CalendarEvent> events,
  ) {
    if (events.isNotEmpty) {
      prefs.setString(
        _cacheKey(year, cc),
        jsonEncode(events.map((e) => e.toJson()).toList()),
      );
    }
  }

  static Exception _wrap(Object e) =>
      e is Exception ? e : Exception(e.toString());

  static Exception _networkException(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('timeout') || msg.contains('timed out')) {
      return Exception(
        'Connection timed out. Check your internet and try again.',
      );
    }
    if (msg.contains('socket') ||
        msg.contains('connection') ||
        msg.contains('network') ||
        msg.contains('host lookup') ||
        msg.contains('unreachable')) {
      return Exception('No internet connection.');
    }
    return Exception('Could not reach holiday service. Check your connection.');
  }
}
