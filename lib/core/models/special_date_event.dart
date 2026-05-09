import 'dart:convert';

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SpecialDateEvent — a user-defined date with a rich-text message.
// Shown as a pulsing amber dot on the dock on the matching calendar day.
// ─────────────────────────────────────────────────────────────────────────────

/// A single paragraph inside a [SpecialDateEvent] message.
class RichParagraph {
  const RichParagraph({
    required this.text,
    this.bold = false,
    this.italic = false,
    this.align = TextAlign.left,
    this.isBullet = false,
  });

  final String text;
  final bool bold;
  final bool italic;
  final TextAlign align;
  final bool isBullet;

  Map<String, dynamic> toJson() => {
    'text': text,
    'bold': bold,
    'italic': italic,
    'align': align.index,
    'isBullet': isBullet,
  };

  factory RichParagraph.fromJson(Map<String, dynamic> j) => RichParagraph(
    text: j['text'] as String? ?? '',
    bold: j['bold'] as bool? ?? false,
    italic: j['italic'] as bool? ?? false,
    align: TextAlign.values[(j['align'] as int?) ?? 0],
    isBullet: j['isBullet'] as bool? ?? false,
  );

  RichParagraph copyWith({
    String? text,
    bool? bold,
    bool? italic,
    TextAlign? align,
    bool? isBullet,
  }) => RichParagraph(
    text: text ?? this.text,
    bold: bold ?? this.bold,
    italic: italic ?? this.italic,
    align: align ?? this.align,
    isBullet: isBullet ?? this.isBullet,
  );
}

class SpecialDateEvent {
  const SpecialDateEvent({
    required this.id,
    required this.name,
    required this.month,
    required this.day,
    required this.isRecurring,
    required this.message,
    this.snoozeMinutes = 30,
  });

  final String id;
  final String name;
  final int month; // 1–12
  final int day; // 1–31
  final bool isRecurring; // true = shows every year
  final List<RichParagraph> message;
  final int snoozeMinutes; // per-event override; 0 = use global default

  /// Whether this event falls on [date]'s month/day.
  bool isToday(DateTime date) => date.month == month && date.day == day;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'month': month,
    'day': day,
    'isRecurring': isRecurring,
    'message': message.map((p) => p.toJson()).toList(),
    'snoozeMinutes': snoozeMinutes,
  };

  factory SpecialDateEvent.fromJson(Map<String, dynamic> j) => SpecialDateEvent(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    month: j['month'] as int? ?? 1,
    day: j['day'] as int? ?? 1,
    isRecurring: j['isRecurring'] as bool? ?? true,
    message:
        (j['message'] as List<dynamic>? ?? [])
            .map(
              (e) =>
                  RichParagraph.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(),
    snoozeMinutes: j['snoozeMinutes'] as int? ?? 30,
  );

  factory SpecialDateEvent.blank() => SpecialDateEvent(
    id: '',
    name: '',
    month: DateTime.now().month,
    day: DateTime.now().day,
    isRecurring: true,
    message: [const RichParagraph(text: '')],
    snoozeMinutes: 0,
  );

  SpecialDateEvent copyWith({
    String? id,
    String? name,
    int? month,
    int? day,
    bool? isRecurring,
    List<RichParagraph>? message,
    int? snoozeMinutes,
  }) => SpecialDateEvent(
    id: id ?? this.id,
    name: name ?? this.name,
    month: month ?? this.month,
    day: day ?? this.day,
    isRecurring: isRecurring ?? this.isRecurring,
    message: message ?? this.message,
    snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
  );

  static List<SpecialDateEvent> listFromJsonString(String s) {
    if (s.isEmpty) return [];
    final list = json.decode(s) as List<dynamic>;
    return list
        .map(
          (e) => SpecialDateEvent.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  static String listToJsonString(List<SpecialDateEvent> events) =>
      json.encode(events.map((e) => e.toJson()).toList());
}
