import 'package:uuid/uuid.dart';

/// A user-created counter widget with an optional note / goal label (max 75 chars).
class CounterWidgetModel {
  CounterWidgetModel({
    String? id,
    required this.note,
    this.count = 0,
    this.lastModifiedAt,
    this.lastChangeDirection = 0,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final String note;
  final int count;
  final DateTime? lastModifiedAt;

  /// 1 = increased, -1 = decreased, 0 = no directional change.
  final int lastChangeDirection;

  CounterWidgetModel copyWith({
    String? note,
    int? count,
    DateTime? lastModifiedAt,
    int? lastChangeDirection,
  }) => CounterWidgetModel(
    id: id,
    note: note ?? this.note,
    count: count ?? this.count,
    lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
    lastChangeDirection: lastChangeDirection ?? this.lastChangeDirection,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'note': note,
    'count': count,
    'lastModifiedAt': lastModifiedAt?.toIso8601String(),
    'lastChangeDirection': lastChangeDirection,
  };

  factory CounterWidgetModel.fromJson(Map<String, dynamic> json) =>
      CounterWidgetModel(
        id: json['id'] as String?,
        note: json['note'] as String? ?? '',
        count: json['count'] as int? ?? 0,
        lastModifiedAt: json['lastModifiedAt'] is String
            ? DateTime.tryParse(json['lastModifiedAt'] as String)
            : null,
        lastChangeDirection:
            (json['lastChangeDirection'] as int? ?? 0).clamp(-1, 1).toInt(),
      );
}
