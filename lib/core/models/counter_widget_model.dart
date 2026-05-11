import 'package:uuid/uuid.dart';

/// A user-created counter widget with an optional note / goal label (max 75 chars).
class CounterWidgetModel {
  CounterWidgetModel({String? id, required this.note, this.count = 0})
    : id = id ?? const Uuid().v4();

  final String id;

  /// Short label / goal text — caller should enforce ≤ 75 chars.
  final String note;

  final int count;

  CounterWidgetModel copyWith({String? note, int? count}) => CounterWidgetModel(
    id: id,
    note: note ?? this.note,
    count: count ?? this.count,
  );

  Map<String, dynamic> toJson() => {'id': id, 'note': note, 'count': count};

  factory CounterWidgetModel.fromJson(Map<String, dynamic> json) =>
      CounterWidgetModel(
        id: json['id'] as String?,
        note: json['note'] as String? ?? '',
        count: json['count'] as int? ?? 0,
      );
}
