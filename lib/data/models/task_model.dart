import 'package:flutter/material.dart';

enum TaskType { daily, deadline }

enum TaskPriority { low, medium, high }

class TaskModel {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final TimeOfDay? dueTime;
  final bool isCompleted;
  final TaskType type;
  final TaskPriority? priority;
  final int streak;
  final DateTime? lastCompleted;
  final String? projectId;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.dueTime,
    this.isCompleted = false,
    required this.type,
    this.priority,
    this.streak = 0,
    this.lastCompleted,
    this.projectId,
  });

  // Add this factory
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dueDate:
          json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      dueTime:
          json['due_time'] != null
              ? TimeOfDay(
                hour: int.parse(json['due_time'].split(":")[0]),
                minute: int.parse(json['due_time'].split(":")[1]),
              )
              : null,
      isCompleted: json['is_completed'] == 1 || json['is_completed'] == true,
      type: json['type'] == 'daily' ? TaskType.daily : TaskType.deadline,
      priority:
          json['priority'] == null
              ? null
              : TaskPriority.values.firstWhere(
                (e) => e.toString().split('.').last == json['priority'],
              ),
      streak: json['streak'] ?? 0,
      lastCompleted:
          json['last_completed'] != null
              ? DateTime.parse(json['last_completed'])
              : null,
      projectId: json['project_id'],
    );
  }

  // Add this method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
      'due_time':
          dueTime != null
              ? '${dueTime!.hour.toString().padLeft(2, '0')}:${dueTime!.minute.toString().padLeft(2, '0')}'
              : null,
      'is_completed': isCompleted ? 1 : 0,
      'type': type.toString().split('.').last,
      'priority': priority?.toString().split('.').last,
      'streak': streak,
      'last_completed': lastCompleted?.toIso8601String(),
      'project_id': projectId,
    };
  }

  // Dummy data untuk testing
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TimeOfDay? dueTime,
    bool? isCompleted,
    TaskType? type,
    TaskPriority? priority,
    int? streak,
    DateTime? lastCompleted,
    String? projectId,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      isCompleted: isCompleted ?? this.isCompleted,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      streak: streak ?? this.streak,
      lastCompleted: lastCompleted ?? this.lastCompleted,
      projectId: projectId ?? this.projectId,
    );
  }
}
