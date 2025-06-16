import 'package:flutter/material.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/thread_model.dart';
import '../../thread/providers/thread_provider.dart';
import '../helpers/thread_integration_help.dart';

enum ProjectLoadingState { idle, loading, success, error }

class CreateProjectRequest {
  final String name;
  final String? description;
  final List<String> memberIds;
  final Map<String, ProjectRole> memberRoles;

  CreateProjectRequest({
    required this.name,
    this.description,
    required this.memberIds,
    required this.memberRoles,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'member_ids': memberIds,
      'member_roles': memberRoles.map(
        (userId, role) => MapEntry(userId, role.toString().split('.').last),
      ),
    };
  }
}

class ProjectProvider with ChangeNotifier {
  List<ProjectModel> _projects = [];
  ProjectLoadingState _loadingState = ProjectLoadingState.idle;
  String? _errorMessage;
  ThreadProvider? _threadProvider;

  // Getters
  List<ProjectModel> get projects => _projects;
  ProjectLoadingState get loadingState => _loadingState;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _loadingState == ProjectLoadingState.loading;

  // CRITICAL: Setter untuk ThreadProvider (dependency injection)
  void setThreadProvider(ThreadProvider threadProvider) {
    _threadProvider = threadProvider;
    print('🔧 ProjectProvider: ThreadProvider dependency injected');
  }

  // Get projects where current user is member
  List<ProjectModel> get userProjects {
    final currentUserId = UserModel.currentUser.id;
    return _projects
        .where((project) => project.isUserMember(currentUserId))
        .toList();
  }

  // Get projects created by current user
  List<ProjectModel> get createdProjects {
    final currentUserId = UserModel.currentUser.id;
    return _projects
        .where((project) => project.creatorId == currentUserId)
        .toList();
  }

  // Backend integration ready methods

  /// Fetch projects from backend
  Future<void> fetchProjects() async {
    _setLoadingState(ProjectLoadingState.loading);

    try {
      // TODO: Implement actual API call
      // final response = await _apiService.get('/projects');
      // final projectsData = response.data as List;
      // _projects = projectsData.map((json) => ProjectModel.fromJson(json)).toList();

      // Simulation: delay untuk mimic network request
      await Future.delayed(const Duration(milliseconds: 500));

      // For now, use dummy data
      _projects = ProjectModel.dummyProjects;

      _setLoadingState(ProjectLoadingState.success);
      print(
        '🔧 ProjectProvider: Projects fetched successfully (${_projects.length} projects)',
      );
    } catch (e) {
      _setLoadingState(ProjectLoadingState.error);
      _errorMessage = 'Failed to fetch projects: $e';
      print('❌ ProjectProvider: Failed to fetch projects: $e');
    }
  }

  /// Create new project room
  Future<ProjectModel?> createProject(CreateProjectRequest request) async {
    _setLoadingState(ProjectLoadingState.loading);

    try {
      // TODO: Implement actual API call
      // final response = await _apiService.post('/projects', data: request.toJson());
      // final newProject = ProjectModel.fromJson(response.data);

      print('🔧 ProjectProvider: Creating project "${request.name}"...');

      // Simulation: Create project locally
      final newProjectId = DateTime.now().millisecondsSinceEpoch.toString();
      final currentUser = UserModel.currentUser;

      // Create project members list
      final members = <ProjectMember>[];

      // Add creator as admin
      members.add(
        ProjectMember(
          userId: currentUser.id,
          user: currentUser,
          role: ProjectRole.admin,
          joinedAt: DateTime.now(),
        ),
      );

      // Add other members
      for (final memberId in request.memberIds) {
        if (memberId != currentUser.id) {
          final user = _getDummyUser(memberId);
          final role = request.memberRoles[memberId] ?? ProjectRole.member;

          members.add(
            ProjectMember(
              userId: memberId,
              user: user,
              role: role,
              joinedAt: DateTime.now(),
            ),
          );
        }
      }

      final newProject = ProjectModel(
        id: newProjectId,
        name: request.name,
        description: request.description,
        creatorId: currentUser.id,
        creator: currentUser,
        members: members,
        taskCount: 0,
        threadCount: 0,
        status: ProjectStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        threadId: 'project-$newProjectId',
      );

      // Add to local list
      _projects.add(newProject);

      // CRITICAL: Auto-create project thread using ThreadIntegrationHelper
      await _createProjectThread(newProject);

      _setLoadingState(ProjectLoadingState.success);
      _errorMessage = null;

      print(
        '✅ ProjectProvider: Project "${newProject.name}" created successfully with ID: ${newProject.id}',
      );

      return newProject;
    } catch (e) {
      _setLoadingState(ProjectLoadingState.error);
      _errorMessage = 'Failed to create project: $e';
      print('❌ ProjectProvider: Failed to create project: $e');
      return null;
    }
  }

  /// Add member to project
  Future<bool> addMemberToProject(
    String projectId,
    String userId,
    ProjectRole role,
  ) async {
    try {
      final projectIndex = _projects.indexWhere((p) => p.id == projectId);
      if (projectIndex != -1) {
        final project = _projects[projectIndex];
        final user = _getDummyUser(userId);

        final newMember = ProjectMember(
          userId: userId,
          user: user,
          role: role,
          joinedAt: DateTime.now(),
        );

        final updatedMembers = List<ProjectMember>.from(project.members)
          ..add(newMember);

        _projects[projectIndex] = project.copyWith(
          members: updatedMembers,
          updatedAt: DateTime.now(),
        );

        // ADDED: Update thread members using ThreadIntegrationHelper
        if (_threadProvider != null) {
          await ThreadIntegrationHelper.addMemberToProjectThreads(
            projectId: projectId,
            newMember: newMember,
            threadProvider: _threadProvider!,
          );
        }

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      _errorMessage = 'Failed to add member: $e';
      notifyListeners();
      return false;
    }
  }

  /// Remove member from project
  Future<bool> removeMemberFromProject(String projectId, String userId) async {
    try {
      final projectIndex = _projects.indexWhere((p) => p.id == projectId);
      if (projectIndex != -1) {
        final project = _projects[projectIndex];

        final updatedMembers =
            project.members.where((member) => member.userId != userId).toList();

        _projects[projectIndex] = project.copyWith(
          members: updatedMembers,
          updatedAt: DateTime.now(),
        );

        // ADDED: Remove from thread members using ThreadIntegrationHelper
        if (_threadProvider != null) {
          await ThreadIntegrationHelper.removeMemberFromProjectThreads(
            projectId: projectId,
            userId: userId,
            threadProvider: _threadProvider!,
          );
        }

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      _errorMessage = 'Failed to remove member: $e';
      notifyListeners();
      return false;
    }
  }

  /// Update project details
  Future<bool> updateProject(
    String projectId, {
    String? name,
    String? description,
    ProjectStatus? status,
    String? threadId,
    int? threadCount,
    int? taskCount,
  }) async {
    try {
      final projectIndex = _projects.indexWhere((p) => p.id == projectId);
      if (projectIndex != -1) {
        final project = _projects[projectIndex];

        _projects[projectIndex] = project.copyWith(
          name: name ?? project.name,
          description: description ?? project.description,
          status: status ?? project.status,
          threadId: threadId ?? project.threadId,
          threadCount: threadCount ?? project.threadCount,
          taskCount: taskCount ?? project.taskCount,
          updatedAt: DateTime.now(),
        );

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      _errorMessage = 'Failed to update project: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete project
  Future<bool> deleteProject(String projectId) async {
    try {
      // ADDED: Delete project threads using ThreadIntegrationHelper
      if (_threadProvider != null) {
        await ThreadIntegrationHelper.deleteProjectThreads(
          projectId: projectId,
          threadProvider: _threadProvider!,
        );
      }

      _projects.removeWhere((project) => project.id == projectId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete project: $e';
      notifyListeners();
      return false;
    }
  }

  /// Get project by ID dengan improved error handling
  ProjectModel? getProjectById(String projectId) {
    try {
      // IMPROVED: Trim whitespace dan explicit empty check
      final trimmedId = projectId.trim();

      if (trimmedId.isEmpty) {
        // HANYA LOG DI DEBUG MODE dan lebih informatif
        assert(() {
          print('⚠️ ProjectProvider: getProjectById called with empty ID');
          print(
            '📍 Available projects: ${_projects.map((p) => '${p.id}:${p.name}').join(', ')}',
          );
          return true;
        }());
        return null;
      }

      return _projects.firstWhere((project) => project.id == trimmedId);
    } catch (e) {
      // IMPROVED: Lebih detailed logging untuk debugging
      assert(() {
        print('⚠️ ProjectProvider: Project with ID "$projectId" not found');
        print(
          '📍 Available projects: ${_projects.map((p) => '${p.id}:${p.name}').join(', ')}',
        );
        print('📍 Search attempted for: "${projectId.trim()}"');
        return true;
      }());
      return null;
    }
  }

  // Private helper methods

  void _setLoadingState(ProjectLoadingState state) {
    _loadingState = state;
    notifyListeners();
  }

  /// CRITICAL: Auto-create thread when project is created
  Future<void> _createProjectThread(ProjectModel project) async {
    if (_threadProvider == null) {
      print(
        '❌ ProjectProvider: ThreadProvider not available for creating project thread',
      );
      return;
    }

    try {
      print(
        '🔧 ProjectProvider: Creating thread for project "${project.name}"...',
      );

      // Use ThreadIntegrationHelper to create project thread
      final createdThread = await ThreadIntegrationHelper.createProjectThread(
        project: project,
        threadProvider: _threadProvider!,
      );

      print(
        '✅ ProjectProvider: Project thread created successfully: ${createdThread.name}',
      );

      // Send welcome message
      await ThreadIntegrationHelper.sendWelcomeMessage(
        project: project,
        threadProvider: _threadProvider!,
      );

      // Update project with threadId
      updateProject(
        project.id,
        threadId: createdThread.id,
        threadCount: (project.threadCount ?? 0) + 1,
      );
    } catch (e) {
      print('❌ ProjectProvider: Failed to create project thread: $e');
      // Don't fail project creation if thread creation fails
    }
  }

  /// Get dummy user data (TODO: Replace with actual backend call)
  UserModel _getDummyUser(String userId) {
    switch (userId) {
      case '2':
        return UserModel(id: '2', name: 'King', email: 'king@example.com');
      case '3':
        return UserModel(id: '3', name: 'Alice', email: 'alice@example.com');
      case '4':
        return UserModel(id: '4', name: 'Bob', email: 'bob@example.com');
      default:
        return UserModel(
          id: userId,
          name: 'User $userId',
          email: 'user$userId@example.com',
        );
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh projects
  Future<void> refreshProjects() async {
    await fetchProjects();
  }

  // TAMBAH: Method untuk debugging project IDs
  void debugProjectIds() {
    print('🔍 ProjectProvider Debug Info:');
    print('   Total projects: ${_projects.length}');
    for (var project in _projects) {
      print('   - ID: "${project.id}" | Name: "${project.name}"');
    }
  }
}
