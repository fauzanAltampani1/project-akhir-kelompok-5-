import 'thread_member_model.dart';

enum ThreadType { hq, project }

class ThreadModel {
  final String id;
  final String name;
  final ThreadType type;
  final String? parentThreadId; // Untuk sub-threads
  final String? projectId; // Untuk project threads
  final List<ThreadMemberModel> members;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description; // Deskripsi thread (tambahan)

  ThreadModel({
    required this.id,
    required this.name,
    required this.type,
    this.parentThreadId,
    this.projectId,
    required this.members,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });

  // Membuat salinan dengan nilai yang diubah
  ThreadModel copyWith({
    String? id,
    String? name,
    ThreadType? type,
    String? parentThreadId,
    String? projectId,
    List<ThreadMemberModel>? members,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
  }) {
    return ThreadModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      parentThreadId: parentThreadId ?? this.parentThreadId,
      projectId: projectId ?? this.projectId,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
    );
  }
  
  // Factory untuk membuat dari JSON (untuk integrasi backend)
  factory ThreadModel.fromJson(Map<String, dynamic> json) {
    return ThreadModel(
      id: json['id'],
      name: json['name'],
      type: json['type'] == 'hq' ? ThreadType.hq : ThreadType.project,
      parentThreadId: json['parent_thread_id'],
      projectId: json['project_id'],
      members: (json['members'] as List?)
          ?.map((m) => ThreadMemberModel.fromJson(m))
          .toList() ?? [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      description: json['description'],
    );
  }
  
  // Konversi ke JSON (untuk integrasi backend)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type == ThreadType.hq ? 'hq' : 'project',
      'parent_thread_id': parentThreadId,
      'project_id': projectId,
      'members': members.map((m) => m.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'description': description,
    };
  }

  // Dummy data untuk testing dengan struktur thread seperti di spesifikasi
  static List<ThreadModel> dummyThreads = [
    // HQ Threads
    ThreadModel(
      id: 'hq-1',
      name: '#FLIPINDO',
      type: ThreadType.hq,
      members: ThreadMemberModel.dummyMembers,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
      description: 'Main organization thread',
    ),
    ThreadModel(
      id: 'hq-1-1',
      name: '#lobby',
      type: ThreadType.hq,
      parentThreadId: 'hq-1',
      members: ThreadMemberModel.dummyMembers,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
      description: 'General chat room',
    ),
    ThreadModel(
      id: 'hq-1-2',
      name: '#announcement',
      type: ThreadType.hq,
      parentThreadId: 'hq-1',
      members: ThreadMemberModel.dummyMembers,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
      description: 'Important announcements',
    ),
    ThreadModel(
      id: 'hq-1-3',
      name: '#brainstorm',
      type: ThreadType.hq,
      parentThreadId: 'hq-1',
      members: ThreadMemberModel.dummyMembers,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
      description: 'Share ideas and inspirations',
    ),
    ThreadModel(
      id: 'hq-1-4',
      name: '#DIVISIIT',
      type: ThreadType.hq,
      parentThreadId: 'hq-1',
      members: ThreadMemberModel.dummyMembers.sublist(0, 3),
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
      description: 'IT Division discussion',
    ),
    
    // Project Threads
    ThreadModel(
      id: 'project-1',
      name: '#Mobile-App-UAS',
      type: ThreadType.project,
      projectId: '1', // Merujuk ke ProjectModel dengan id '1'
      members: ThreadMemberModel.dummyMembers,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now(),
      description: 'Mobile Application Final Project',
    ),
    ThreadModel(
      id: 'project-1-1',
      name: '#UI',
      type: ThreadType.project,
      parentThreadId: 'project-1',
      projectId: '1',
      members: ThreadMemberModel.dummyMembers.sublist(0, 3),
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now(),
      description: 'UI Design discussions',
    ),
    ThreadModel(
      id: 'project-1-2',
      name: '#UX',
      type: ThreadType.project,
      parentThreadId: 'project-1',
      projectId: '1',
      members: ThreadMemberModel.dummyMembers.sublist(0, 3),
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now(),
      description: 'UX Research and design',
    ),
  ];
}