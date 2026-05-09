import 'package:uuid/uuid.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ScheduleRule
//
// A named rule that surfaces a set of apps in the context shell when:
//   • the current weekday is in [days]  (empty = every day)
//   • the current time is within [startMinutes]–[endMinutes]  (0–1439)
//
// Rules are stored in priority order (index 0 = highest priority).
// When multiple rules are active simultaneously, apps fill slots left-to-right
// from highest to lowest priority, deduplicating, capped at 5.
// ─────────────────────────────────────────────────────────────────────────────

const kScheduleMaxApps = 5;

class ScheduleRule {
  const ScheduleRule({
    required this.id,
    required this.name,
    required this.days,
    required this.startMinutes,
    required this.endMinutes,
    required this.apps,
  });

  /// Unique rule ID.
  final String id;

  /// User-given label, e.g. "Work", "Commute", "Weekend".
  final String name;

  /// Weekdays this rule applies to. 1 = Monday … 7 = Sunday.
  /// Empty set means the rule is active every day.
  final Set<int> days;

  /// Minutes from midnight when the window opens (0–1439).
  final int startMinutes;

  /// Minutes from midnight when the window closes (0–1439).
  /// If endMinutes < startMinutes the window crosses midnight (e.g. 22:00–02:00).
  final int endMinutes;

  /// Package names of apps to surface, in display order. Max [kScheduleMaxApps].
  final List<String> apps;

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool get isAllDay => startMinutes == 0 && endMinutes == 1439;

  bool isActiveNow(DateTime now) {
    final dayMatch = days.isEmpty || days.contains(now.weekday);
    if (!dayMatch) return false;
    final m = now.hour * 60 + now.minute;
    if (startMinutes <= endMinutes) {
      return m >= startMinutes && m <= endMinutes;
    } else {
      // Overnight rule (e.g. 22:00–02:00)
      return m >= startMinutes || m <= endMinutes;
    }
  }

  // ── Days summary label ────────────────────────────────────────────────────

  String get daysLabel {
    if (days.isEmpty || days.length == 7) return 'Every day';
    const abbr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = days.toList()..sort();
    if (sorted.length == 5 && sorted.every((d) => d <= 5)) return 'Mon – Fri';
    if (sorted.length == 2 && sorted.contains(6) && sorted.contains(7)) {
      return 'Weekends';
    }
    if (sorted.length == 1) return abbr[sorted.first - 1];
    return sorted.map((d) => abbr[d - 1]).join(', ');
  }

  // ── Time summary label ────────────────────────────────────────────────────

  String get timeLabel {
    if (isAllDay) return 'All day';
    return '${fmt(startMinutes)} – ${fmt(endMinutes)}';
  }

  static String fmt(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final period = h < 12 ? 'AM' : 'PM';
    final displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final pad = m.toString().padLeft(2, '0');
    return '$displayH:$pad $period';
  }

  // ── Serialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'days': days.toList(),
    'startMinutes': startMinutes,
    'endMinutes': endMinutes,
    'apps': apps,
  };

  factory ScheduleRule.fromJson(Map<String, dynamic> json) => ScheduleRule(
    id: json['id'] as String,
    name: json['name'] as String,
    days: Set<int>.from(((json['days'] as List?) ?? []).cast<int>()),
    startMinutes: json['startMinutes'] as int,
    endMinutes: json['endMinutes'] as int,
    apps: List<String>.from(json['apps'] as List),
  );

  factory ScheduleRule.blank() => ScheduleRule(
    id: const Uuid().v4(),
    name: '',
    days: const {},
    startMinutes: 0,
    endMinutes: 1439,
    apps: const [],
  );

  ScheduleRule copyWith({
    String? name,
    Set<int>? days,
    int? startMinutes,
    int? endMinutes,
    List<String>? apps,
  }) => ScheduleRule(
    id: id,
    name: name ?? this.name,
    days: days ?? this.days,
    startMinutes: startMinutes ?? this.startMinutes,
    endMinutes: endMinutes ?? this.endMinutes,
    apps: apps ?? this.apps,
  );
}
