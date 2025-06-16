import 'package:intl/intl.dart';

enum TaskPriority { low, medium, high }

class ProjectTaskModel {
  final String id;
  final String title;
  final String? description;
  final DateTime dueDate;
  final List<String> assigneeIds;
  final String projectId;
  final bool isCompleted;
  final String assignerId;

  ProjectTaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.dueDate,
    required this.assigneeIds,
    required this.projectId,
    this.isCompleted = false,
    required this.assignerId,
  });

  factory ProjectTaskModel.fromJson(Map<String, dynamic> json) {
    return ProjectTaskModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dueDate: DateTime.parse(json['due_date']),
      assigneeIds: List<String>.from(json['assignee_ids'] ?? []),
      projectId: json['project_id'],
      isCompleted: json['is_completed'] ?? false,
      assignerId: json['assigner_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'due_date': DateFormat('yyyy-MM-dd').format(dueDate),
      'assignee_ids': assigneeIds,
      'project_id': projectId,
      'is_completed': isCompleted,
      'assigner_id': assignerId,
    };
  }

  ProjectTaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    List<String>? assigneeIds,
    String? projectId,
    bool? isCompleted,
    String? assignerId,
  }) {
    return ProjectTaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      assigneeIds: assigneeIds ?? this.assigneeIds,
      projectId: projectId ?? this.projectId,
      isCompleted: isCompleted ?? this.isCompleted,
      assignerId: assignerId ?? this.assignerId,
    );
  }

  static List<ProjectTaskModel> _dummyTasks = [
    ProjectTaskModel(
      id: 'task-1',
      title: 'Design UI',
      description: 'Create home screen design',
      dueDate: DateTime(2025, 6, 3),
      assigneeIds: ['1', '2'],
      projectId: '1',
      assignerId: '3',
    ),
    ProjectTaskModel(
      id: 'task-2',
      title: 'Review Code',
      dueDate: DateTime(2025, 6, 4),
      assigneeIds: ['2'],
      projectId: '2',
      assignerId: '1',
    ),
    ProjectTaskModel(
      id: 'task-3',
      title: 'Redesign login page',
      description: 'Update login page UI',
      dueDate: DateTime(2025, 6, 5),
      assigneeIds: ['2'],
      projectId: '1',
      assignerId: '3',
    ),
  ];

  // Update: Tambah getter dan setter
  static List<ProjectTaskModel> get dummyTasks => _dummyTasks;
  static set dummyTasks(List<ProjectTaskModel> tasks) {
    _dummyTasks = tasks;
  }
}