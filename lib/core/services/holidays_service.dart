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
          .get(uri, headers: {
            'User-Agent': 'OneHandLauncher/1.0',
            'Accept-Language': 'en',
          })
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final cc =
            (data['address']?['country_code'] as String?)?.toUpperCase();
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
  static Future<void> setCountryCode(
    SharedPreferences prefs,
    String cc,
  ) async {
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

  static Future<List<CalendarEvent>> _download(
    int year,
    String countryCode,
    SharedPreferences prefs,
  ) async {
    final uri = Uri.parse(
      'https://date.nager.at/api/v3/PublicHolidays/$year/$countryCode',
    );
    final response = await http
        .get(uri)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Could not download holidays (HTTP ${response.statusCode})',
      );
    }

    final raw = jsonDecode(response.body) as List;
    final events = raw.map((e) {
      final m = e as Map<String, dynamic>;
      return CalendarEvent(
        id: 'holiday_${countryCode}_${m['date']}',
        date: DateTime.parse(m['date'] as String),
        name: (m['localName'] as String?)?.isNotEmpty == true
            ? m['localName'] as String
            : (m['name'] as String? ?? ''),
        isPublicHoliday: true,
      );
    }).toList();

    // Save serialised CalendarEvent list (not raw API) so fromJson is consistent
    await prefs.setString(
      _cacheKey(year, countryCode),
      jsonEncode(events.map((e) => e.toJson()).toList()),
    );
    return events;
  }
}
