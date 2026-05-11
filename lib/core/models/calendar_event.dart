import 'package:uuid/uuid.dart';

/// A single calendar event — either a public holiday or a user-created event.
class CalendarEvent {
  CalendarEvent({
    String? id,
    required this.date,
    DateTime? endDate,
    required this.name,
    required this.isPublicHoliday,
  }) : id = id ?? const Uuid().v4(),
       endDate = endDate ?? date;

  final String id;
  final DateTime date;
  final DateTime endDate;
  final String name;
  final bool isPublicHoliday;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'name': name,
    'isPublicHoliday': isPublicHoliday,
  };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
    id: json['id'] as String?,
    date: DateTime.parse(json['date'] as String),
    endDate:
        json['endDate'] != null
            ? DateTime.parse(json['endDate'] as String)
            : null,
    name: json['name'] as String,
    isPublicHoliday: json['isPublicHoliday'] as bool? ?? true,
  );
}
