import 'package:uuid/uuid.dart';

enum PlannerItemType { todo, event }

class PlannerItem {
  PlannerItem({
    String? id,
    required this.date,
    required this.title,
    this.description = '',
    this.type = PlannerItemType.todo,
    this.isCompleted = false,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final DateTime date;
  final String title;
  final String description;
  final PlannerItemType type;
  final bool isCompleted;

  PlannerItem copyWith({bool? isCompleted}) => PlannerItem(
    id: id,
    date: date,
    title: title,
    description: description,
    type: type,
    isCompleted: isCompleted ?? this.isCompleted,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'title': title,
    'description': description,
    'type': type.name,
    'isCompleted': isCompleted,
  };

  factory PlannerItem.fromJson(Map<String, dynamic> json) => PlannerItem(
    id: json['id'] as String?,
    date: DateTime.parse(json['date'] as String),
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    type: PlannerItemType.values.firstWhere(
      (v) => v.name == json['type'],
      orElse: () => PlannerItemType.todo,
    ),
    isCompleted: json['isCompleted'] as bool? ?? false,
  );
}
