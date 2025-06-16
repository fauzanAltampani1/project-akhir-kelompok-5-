import '../../../data/models/project_model.dart';
import '../../../data/models/thread_model.dart';
import '../../../data/models/thread_member_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/user_model.dart';
import '../../thread/providers/thread_provider.dart';

class ThreadIntegrationHelper {
  static const String PROJECT_THREAD_PREFIX = '#';
  static int _subThreadCounter = 0; // Tambah counter untuk ID unik

  static String _generateUniqueSubThreadId(String parentId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final counter = ++_subThreadCounter;
    return '$parentId-sub-$timestamp-$counter';
  }

  static Future<ThreadModel> createProjectThread({
    required ProjectModel project,
    required ThreadProvider threadProvider,
  }) async {
    try {
      print('🔧 ThreadIntegrationHelper: Creating thread for project ${project.name}...');
      
      // Reset counter tiap bikin project thread baru
      _subThreadCounter = 0;
      
      // Cek apakah thread dengan projectId ini udah ada
      final existingThread = threadProvider.threads
          .firstWhere((thread) => thread.projectId == project.id && thread.parentThreadId == null, 
          orElse: () => ThreadModel(
            id: 'temp-${project.id}',
            name: formatProjectThreadName(project.name),
            type: ThreadType.project,
            projectId: project.id,
            members: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
      if (existingThread.id != 'temp-${project.id}') {
        print('🔧 ThreadIntegrationHelper: Thread already exists for project ${project.name}: ${existingThread.id}');
        return existingThread;
      }

      final threadMembers = project.members.map((projectMember) {
        return ThreadMemberModel(
          user: projectMember.user,
          role: _convertProjectRoleToMemberRole(projectMember.role),
          status: MemberStatus.online,
          lastActive: DateTime.now(),
        );
      }).toList();

      final mainThreadName = formatProjectThreadName(project.name);
      final threadId = 'project-${DateTime.now().millisecondsSinceEpoch}';
      
      print('🔧 ThreadIntegrationHelper: Thread name will be: $mainThreadName');
      print('🔧 ThreadIntegrationHelper: Thread members: ${threadMembers.map((m) => m.user.name).toList()}');
      
      // Buat thread utama
      final mainThread = ThreadModel(
        id: threadId,
        name: mainThreadName,
        type: ThreadType.project,
        projectId: project.id,
        members: threadMembers,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        description: project.description ?? 'Main project discussion thread for ${project.name}',
      );
      
      threadProvider.threads.add(mainThread);
      // Inisialisasi _threadMessages
      if (!threadProvider.threadMessages.containsKey(threadId)) {
        threadProvider.threadMessages[threadId] = [];
      }

      // Buat sub-thread dengan delay dan counter
      final subThreads = ['general', 'tasks', 'updates'];
      for (var subThreadName in subThreads) {
        // Tambah delay biar timestamp beda
        await Future.delayed(const Duration(milliseconds: 5));
        
        final subThreadId = _generateUniqueSubThreadId(threadId);
        final subThread = ThreadModel(
          id: subThreadId,
          name: '#$subThreadName',
          type: ThreadType.project,
          parentThreadId: threadId,
          projectId: project.id,
          members: threadMembers,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          description: _getDefaultDescription(subThreadName),
        );
        threadProvider.threads.add(subThread);
        // Inisialisasi _threadMessages untuk sub-thread
        if (!threadProvider.threadMessages.containsKey(subThreadId)) {
          threadProvider.threadMessages[subThreadId] = [];
        }
        print('🔧 ThreadIntegrationHelper: Created sub-thread "#$subThreadName" with ID: $subThreadId');
      }

      threadProvider.notifyListeners();
      print('✅ ThreadIntegrationHelper: Project thread created successfully: ${mainThread.name} (${mainThread.id})');
      
      return mainThread;
    } catch (e) {
      print('❌ ThreadIntegrationHelper: Error creating project thread: $e');
      return ThreadModel(
        id: 'temp-${project.id}',
        name: formatProjectThreadName(project.name),
        type: ThreadType.project,
        projectId: project.id,
        members: project.members.map((m) => convertProjectMemberToThreadMember(m)).toList(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  static Future<void> addMemberToProjectThreads({
    required String projectId,
    required ProjectMember newMember,
    required ThreadProvider threadProvider,
  }) async {
    try {
      final projectThreads = getProjectThreadsByProjectId(projectId, threadProvider);
      
      final threadMember = ThreadMemberModel(
        user: newMember.user,
        role: _convertProjectRoleToMemberRole(newMember.role),
        status: MemberStatus.online,
        lastActive: DateTime.now(),
      );

      for (final thread in projectThreads) {
        final threadIndex = threadProvider.threads.indexWhere((t) => t.id == thread.id);
        if (threadIndex != -1) {
          final updatedMembers = List<ThreadMemberModel>.from(thread.members)
            ..add(threadMember);
          
          threadProvider.threads[threadIndex] = thread.copyWith(
            members: updatedMembers,
            updatedAt: DateTime.now(),
          );
        }
      }
      
      threadProvider.notifyListeners();
      print('✅ ThreadIntegrationHelper: Added ${newMember.user.name} to ${projectThreads.length} project threads');
    } catch (e) {
      print('❌ ThreadIntegrationHelper: Error adding member to project threads: $e');
    }
  }

  static Future<void> removeMemberFromProjectThreads({
    required String projectId,
    required String userId,
    required ThreadProvider threadProvider,
  }) async {
    try {
      final projectThreads = getProjectThreadsByProjectId(projectId, threadProvider);

      for (final thread in projectThreads) {
        final threadIndex = threadProvider.threads.indexWhere((t) => t.id == thread.id);
        if (threadIndex != -1) {
          final updatedMembers = thread.members
              .where((member) => member.user.id != userId)
              .toList();
          
          threadProvider.threads[threadIndex] = thread.copyWith(
            members: updatedMembers,
            updatedAt: DateTime.now(),
          );
        }
      }
      
      threadProvider.notifyListeners();
      print('✅ ThreadIntegrationHelper: Removed user $userId from ${projectThreads.length} project threads');
    } catch (e) {
      print('❌ ThreadIntegrationHelper: Error removing member from project threads: $e');
    }
  }

  static Future<void> updateMemberRoleInProjectThreads({
    required String projectId,
    required String userId,
    required ProjectRole newRole,
    required ThreadProvider threadProvider,
  }) async {
    try {
      final projectThreads = getProjectThreadsByProjectId(projectId, threadProvider);
      
      final newMemberRole = _convertProjectRoleToMemberRole(newRole);

      for (final thread in projectThreads) {
        await threadProvider.updateMemberRole(
          threadId: thread.id,
          userId: userId,
          role: newMemberRole,
        );
      }
      
      print('✅ ThreadIntegrationHelper: Updated role for user $userId in ${projectThreads.length} project threads');
    } catch (e) {
      print('❌ ThreadIntegrationHelper: Error updating member role in project threads: $e');
    }
  }

  static Future<void> deleteProjectThreads({
    required String projectId,
    required ThreadProvider threadProvider,
  }) async {
    try {
      final projectThreads = getProjectThreadsByProjectId(projectId, threadProvider);

      for (final thread in projectThreads) {
        threadProvider.threads.removeWhere((t) => t.id == thread.id);
      }
      
      threadProvider.notifyListeners();
      print('✅ ThreadIntegrationHelper: Deleted ${projectThreads.length} project threads');
    } catch (e) {
      print('❌ ThreadIntegrationHelper: Error deleting project threads: $e');
    }
  }

  static Future<void> sendProjectSystemMessage({
    required String projectId,
    required String message,
    required ThreadProvider threadProvider,
  }) async {
    try {
      final mainThread = getMainProjectThread(projectId, threadProvider);
      
      if (mainThread != null) {
        final systemMessage = MessageModel(
          id: 'msg-system-${DateTime.now().millisecondsSinceEpoch}',
          threadId: mainThread.id,
          sender: UserModel(id: 'system', name: 'System', email: 'system@example.com'),
          content: message,
          type: MessageType.system,
          createdAt: DateTime.now(),
          isUnread: true,
        );

        if (!threadProvider.threadMessages.containsKey(mainThread.id)) {
          threadProvider.threadMessages[mainThread.id] = [];
        }
        threadProvider.threadMessages[mainThread.id]!.add(systemMessage);
        threadProvider.notifyListeners();

        print('✅ ThreadIntegrationHelper: Sent system message to project thread: $message');
      } else {
        print('❌ ThreadIntegrationHelper: Main project thread not found for project $projectId');
      }
    } catch (e) {
      print('❌ ThreadIntegrationHelper: Error sending project system message: $e');
    }
  }

  static String getProjectThreadRoute(String projectId) {
    return '/thread?project=$projectId';
  }

  static String formatProjectThreadName(String projectName) {
    final cleanName = projectName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
    
    return '$PROJECT_THREAD_PREFIX$cleanName';
  }

  static bool hasThreadPermission({
    required ProjectModel project,
    required String userId,
    required ThreadAction action,
  }) {
    try {
      final userRole = project.getUserRole(userId);
      if (userRole == null) return false;

      switch (action) {
        case ThreadAction.read:
          return true;
        case ThreadAction.write:
          return userRole != ProjectRole.viewer;
        case ThreadAction.manageMembers:
          return userRole == ProjectRole.admin;
        case ThreadAction.deleteThread:
          return userRole == ProjectRole.admin;
      }
    } catch (e) {
      return false;
    }
  }

  static List<ThreadModel> getProjectThreadsByProjectId(String projectId, ThreadProvider threadProvider) {
    return threadProvider.threads.where((thread) {
      return thread.projectId == projectId;
    }).toList();
  }

  static ThreadModel? getMainProjectThread(String projectId, ThreadProvider threadProvider) {
    final projectThreads = getProjectThreadsByProjectId(projectId, threadProvider);
    
    if (projectThreads.isEmpty) return null;
    
    try {
      return projectThreads.firstWhere(
        (thread) => thread.parentThreadId == null,
      );
    } catch (e) {
      return projectThreads.first;
    }
  }

  static ThreadMemberModel convertProjectMemberToThreadMember(ProjectMember projectMember) {
    return ThreadMemberModel(
      user: projectMember.user,
      role: _convertProjectRoleToMemberRole(projectMember.role),
      status: MemberStatus.online,
      lastActive: DateTime.now(),
    );
  }

  static Future<void> sendWelcomeMessage({
    required ProjectModel project,
    required ThreadProvider threadProvider,
  }) async {
    await sendProjectSystemMessage(
      projectId: project.id,
      message: '🎉 Welcome to ${project.name}! Project has been created successfully.',
      threadProvider: threadProvider,
    );
  }

  static Future<void> sendMemberJoinedMessage({
    required String projectId,
    required ProjectMember member,
    required ThreadProvider threadProvider,
  }) async {
    await sendProjectSystemMessage(
      projectId: projectId,
      message: '👋 ${member.user.name} joined the project as ${member.role.toString().split('.').last}',
      threadProvider: threadProvider,
    );
  }

  static Future<void> sendMemberLeftMessage({
    required String projectId,
    required String userName,
    required ThreadProvider threadProvider,
  }) async {
    await sendProjectSystemMessage(
      projectId: projectId,
      message: '👋 $userName left the project',
      threadProvider: threadProvider,
    );
  }

  static String _getDefaultDescription(String subThreadName) {
    final name = subThreadName.toLowerCase();
    if (name.contains('general')) return 'General discussion';
    if (name.contains('tasks')) return 'Task-related discussions';
    if (name.contains('updates')) return 'Project updates';
    return 'Thread discussion';
  }

  static MemberRole _convertProjectRoleToMemberRole(ProjectRole projectRole) {
    switch (projectRole) {
      case ProjectRole.admin:
        return MemberRole.admin;
      case ProjectRole.member:
        return MemberRole.member;
      case ProjectRole.viewer:
        return MemberRole.member;
    }
  }
}

enum ThreadAction {
  read,
  write,
  manageMembers,
  deleteThread,
}