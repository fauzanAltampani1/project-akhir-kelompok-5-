import '../models/user_model.dart';

enum ProjectRole { admin, member, viewer }
enum ProjectStatus { active, archived, completed }

class ProjectMember {
  final String userId;
  final UserModel user;
  final ProjectRole role;
  final DateTime joinedAt;

  ProjectMember({
    required this.userId,
    required this.user,
    required this.role,
    required this.joinedAt,
  });

  factory ProjectMember.fromJson(Map<String, dynamic> json) {
    return ProjectMember(
      userId: json['user_id'],
      user: UserModel.fromJson(json['user']),
      role: _getRoleFromString(json['role']),
      joinedAt: DateTime.parse(json['joined_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user': user.toJson(),
      'role': role.toString().split('.').last,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  static ProjectRole _getRoleFromString(String? roleStr) {
    switch (roleStr) {
      case 'admin':
        return ProjectRole.admin;
      case 'member':
        return ProjectRole.member;
      case 'viewer':
        return ProjectRole.viewer;
      default:
        return ProjectRole.member;
    }
  }

  ProjectMember copyWith({
    String? userId,
    UserModel? user,
    ProjectRole? role,
    DateTime? joinedAt,
  }) {
    return ProjectMember(
      userId: userId ?? this.userId,
      user: user ?? this.user,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}

class ProjectModel {
  final String id;
  final String name;
  final String? description;
  final String creatorId;
  final UserModel creator;
  final List<ProjectMember> members;
  final int taskCount;
  final int threadCount;
  final ProjectStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? threadId; // ID thread yang otomatis dibuat

  ProjectModel({
    required this.id,
    required this.name,
    this.description,
    required this.creatorId,
    required this.creator,
    required this.members,
    this.taskCount = 0,
    this.threadCount = 0,
    this.status = ProjectStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.threadId,
  });

  // Factory untuk membuat dari JSON (backend integration ready)
  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      creatorId: json['creator_id'],
      creator: UserModel.fromJson(json['creator']),
      members: (json['members'] as List?)
          ?.map((m) => ProjectMember.fromJson(m))
          .toList() ?? [],
      taskCount: json['task_count'] ?? 0,
      threadCount: json['thread_count'] ?? 0,
      status: _getStatusFromString(json['status']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      threadId: json['thread_id'],
    );
  }

  // Konversi ke JSON (backend integration ready)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'creator_id': creatorId,
      'creator': creator.toJson(),
      'members': members.map((m) => m.toJson()).toList(),
      'task_count': taskCount,
      'thread_count': threadCount,
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'thread_id': threadId,
    };
  }

  static ProjectStatus _getStatusFromString(String? statusStr) {
    switch (statusStr) {
      case 'active':
        return ProjectStatus.active;
      case 'archived':
        return ProjectStatus.archived;
      case 'completed':
        return ProjectStatus.completed;
      default:
        return ProjectStatus.active;
    }
  }

  ProjectModel copyWith({
    String? id,
    String? name,
    String? description,
    String? creatorId,
    UserModel? creator,
    List<ProjectMember>? members,
    int? taskCount,
    int? threadCount,
    ProjectStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? threadId,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      creator: creator ?? this.creator,
      members: members ?? this.members,
      taskCount: taskCount ?? this.taskCount,
      threadCount: threadCount ?? this.threadCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      threadId: threadId ?? this.threadId,
    );
  }

  // Helper methods
  bool isUserMember(String userId) {
    return members.any((member) => member.userId == userId);
  }

  bool isUserAdmin(String userId) {
    return members.any((member) => 
        member.userId == userId && member.role == ProjectRole.admin);
  }

  ProjectRole? getUserRole(String userId) {
    final member = members.firstWhere(
      (member) => member.userId == userId,
      orElse: () => throw StateError('User not found in project'),
    );
    return member.role;
  }

  // Enhanced dummy data dengan members dan backend-ready structure
  static List<ProjectModel> dummyProjects = [
    ProjectModel(
      id: '1',
      name: 'Mobile App UAS',
      description: 'Final project for Mobile App Development class',
      creatorId: UserModel.currentUser.id,
      creator: UserModel.currentUser,
      members: [
        ProjectMember(
          userId: UserModel.currentUser.id,
          user: UserModel.currentUser,
          role: ProjectRole.admin,
          joinedAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
        ProjectMember(
          userId: '2',
          user: UserModel(id: '2', name: 'King', email: 'king@example.com'),
          role: ProjectRole.member,
          joinedAt: DateTime.now().subtract(const Duration(days: 8)),
        ),
        ProjectMember(
          userId: '3',
          user: UserModel(id: '3', name: 'Alice', email: 'alice@example.com'),
          role: ProjectRole.member,
          joinedAt: DateTime.now().subtract(const Duration(days: 6)),
        ),
      ],
      taskCount: 5,
      threadCount: 3,
      status: ProjectStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now(),
      threadId: 'project-1', // Merujuk ke ThreadModel
    ),
    ProjectModel(
      id: '2',
      name: 'Website Redesign',
      description: 'Redesign company website with modern UI/UX',
      creatorId: '2',
      creator: UserModel(id: '2', name: 'King', email: 'king@example.com'),
      members: [
        ProjectMember(
          userId: '2',
          user: UserModel(id: '2', name: 'King', email: 'king@example.com'),
          role: ProjectRole.admin,
          joinedAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        ProjectMember(
          userId: UserModel.currentUser.id,
          user: UserModel.currentUser,
          role: ProjectRole.member,
          joinedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ],
      taskCount: 3,
      threadCount: 2,
      status: ProjectStatus.active,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now(),
      threadId: 'project-2',
    ),
  ];
}