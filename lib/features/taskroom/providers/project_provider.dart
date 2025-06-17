import 'package:flutter/material.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/user_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/logger.dart';
import '../../../providers/loading_state_provider.dart';
import '../../thread/providers/thread_provider.dart'; // Added import for ThreadProvider
import '../../../core/utils/personalization_helper.dart';

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
  final ApiClient _apiClient = ApiClient();
  List<ProjectModel> _projects = [];
  ProjectLoadingState _loadingState = ProjectLoadingState.idle;
  String? _errorMessage;
  ThreadProvider? _threadProvider; // Added field for ThreadProvider
  LoadingStateProvider? _loadingStateProvider;

  // Getters
  List<ProjectModel> get projects => _projects;

  // Get only projects where the current user is a member
  List<ProjectModel> get userProjects =>
      PersonalizationHelper.getCurrentUserProjects(_projects);

  ProjectLoadingState get loadingState => _loadingState;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _loadingState == ProjectLoadingState.loading;

  // Setter for LoadingStateProvider
  void setLoadingStateProvider(LoadingStateProvider provider) {
    _loadingStateProvider = provider;
    notifyListeners();
  }

  // Set the thread provider
  void setThreadProvider(ThreadProvider provider) {
    _threadProvider = provider;
    Logger.i('ProjectProvider', 'ThreadProvider has been set');
    notifyListeners();
  }
  // Get projects where current user is member (using PersonalizationHelper)

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

    // Update global loading state if available
    if (_loadingStateProvider != null) {
      _loadingStateProvider!.setModuleLoading(
        'projects',
        message: 'Fetching projects...',
      );
    }
    try {
      final response = await _apiClient.get('/projects.php');

      // Check if response is null
      if (response == null) {
        throw Exception('No response received from server');
      }

      // Handle our API response format: {status: 'success', data: [...]}
      if (response['status'] == 'error') {
        throw Exception(response['message'] ?? 'Unknown error occurred');
      }

      // Ensure we have a success response
      if (response['status'] != 'success') {
        throw Exception('Unexpected response status: ${response['status']}');
      }

      // Extract the data array from the success response
      final dynamic responseData = response['data'];
      final List<dynamic> projectsData;

      if (responseData == null) {
        projectsData = [];
      } else if (responseData is List) {
        projectsData = responseData;
      } else {
        throw Exception(
          'Invalid data format: expected List but got ${responseData.runtimeType}',
        );
      }

      _projects =
          projectsData.map((json) {
            if (json == null) {
              throw Exception('Null project data received');
            }
            return ProjectModel.fromJson(json as Map<String, dynamic>);
          }).toList();

      _setLoadingState(ProjectLoadingState.success);

      // Update global loading state if available
      if (_loadingStateProvider != null) {
        _loadingStateProvider!.setModuleLoaded(
          'projects',
          message: 'Projects loaded successfully',
        );
      }

      Logger.s(
        'ProjectProvider',
        'Projects fetched successfully (${_projects.length} projects)',
      );
    } catch (e) {
      _setLoadingState(ProjectLoadingState.error);
      _errorMessage = 'Failed to fetch projects: $e';

      // Update global loading state if available
      if (_loadingStateProvider != null) {
        _loadingStateProvider!.setModuleError(
          'projects',
          message: 'Failed to fetch projects: $e',
        );
      }

      Logger.e('ProjectProvider', 'Failed to fetch projects: $e');
    }
  }

  /// Create new project room
  Future<ProjectModel?> createProject(CreateProjectRequest request) async {
    _setLoadingState(ProjectLoadingState.loading);

    try {
      final currentUser = UserModel.currentUser;
      final projectData = {
        ...request.toJson(),
        'creator_id': currentUser.id,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'task_count': 0,
        'thread_count': 0,
        'status': 'active',
      };

      final response = await _apiClient.post('/projects', projectData);
      if (response['status'] == 'error') {
        throw Exception(response['message']);
      }

      await fetchProjects(); // Refresh the projects list
      final newProject = _projects.firstWhere(
        (p) => p.creatorId == currentUser.id && p.name == request.name,
        orElse: () => throw Exception('Project creation failed'),
      );

      _setLoadingState(ProjectLoadingState.success);
      Logger.s(
        'ProjectProvider',
        'Project "${request.name}" created successfully',
      );
      return newProject;
    } catch (e) {
      _setLoadingState(ProjectLoadingState.error);
      _errorMessage = 'Failed to create project: $e';
      Logger.e('ProjectProvider', 'Failed to create project: $e');
      return null;
    }
  }

  /// Delete project
  Future<bool> deleteProject(String projectId) async {
    try {
      final response = await _apiClient.delete('/projects', {'id': projectId});
      if (response['status'] == 'error') {
        throw Exception(response['message']);
      }

      _projects.removeWhere((p) => p.id == projectId);
      notifyListeners();

      Logger.s('ProjectProvider', 'Project deleted successfully');
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete project: $e';
      Logger.e('ProjectProvider', 'Failed to delete project: $e');
      return false;
    }
  }

  /// Get a project by its ID
  ProjectModel? getProjectById(String projectId) {
    try {
      return _projects.firstWhere((p) => p.id == projectId);
    } catch (e) {
      return null;
    }
  }

  /// Update project details with proper error handling
  Future<bool> updateProject(
    String projectId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final data = {
        'id': projectId,
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _apiClient.put('/projects', data);
      if (response['status'] == 'error') {
        throw Exception(response['message']);
      }

      final index = _projects.indexWhere((p) => p.id == projectId);
      if (index != -1) {
        _projects[index] = ProjectModel.fromJson({
          ..._projects[index].toJson(),
          ...updates,
        });
        notifyListeners();
      }

      Logger.s('ProjectProvider', 'Project updated successfully');
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update project: $e';
      Logger.e('ProjectProvider', 'Failed to update project: $e');
      return false;
    }
  }

  /// Add member to project
  Future<bool> addMemberToProject(
    String projectId,
    String userId,
    ProjectRole role,
  ) async {
    try {
      final data = {
        'project_id': projectId,
        'user_id': userId,
        'role': role.toString().split('.').last,
        'joined_at': DateTime.now().toIso8601String(),
      };

      final response = await _apiClient.post(
        '/projects/$projectId/members',
        data,
      );
      if (response['status'] == 'error') {
        throw Exception(response['message']);
      }

      await fetchProjects(); // Refresh to get updated member list
      Logger.s('ProjectProvider', 'Member added to project successfully');
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add member: $e';
      Logger.e('ProjectProvider', 'Failed to add member: $e');
      return false;
    }
  }

  /// Remove member from project
  Future<bool> removeMemberFromProject(String projectId, String userId) async {
    try {
      final response = await _apiClient.delete('/projects/$projectId/members', {
        'user_id': userId,
      });
      if (response['status'] == 'error') {
        throw Exception(response['message']);
      }

      await fetchProjects(); // Refresh to get updated member list
      Logger.s('ProjectProvider', 'Member removed from project successfully');
      return true;
    } catch (e) {
      _errorMessage = 'Failed to remove member: $e';
      Logger.e('ProjectProvider', 'Failed to remove member: $e');
      return false;
    }
  }

  /// Update member role in project
  Future<bool> updateMemberRole(
    String projectId,
    String userId,
    ProjectRole newRole,
  ) async {
    try {
      final data = {
        'user_id': userId,
        'role': newRole.toString().split('.').last,
      };

      final response = await _apiClient.put(
        '/projects/$projectId/members',
        data,
      );
      if (response['status'] == 'error') {
        throw Exception(response['message']);
      }

      await fetchProjects(); // Refresh to get updated member roles
      Logger.s('ProjectProvider', 'Member role updated successfully');
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update member role: $e';
      Logger.e('ProjectProvider', 'Failed to update member role: $e');
      return false;
    }
  }

  /// Clear any error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Updates a project in the backend and refreshes local data
  Future<void> updateAndRefresh(ProjectModel project) async {
    try {
      await _apiClient.put('/projects', {
        'id': project.id,
        'name': project.name,
        'description': project.description,
        'task_count': project.taskCount,
        'thread_count': project.threadCount,
        'status': project.status.toString().split('.').last,
        'updated_at': project.updatedAt.toIso8601String(),
      });

      // Update local project list
      final index = _projects.indexWhere((p) => p.id == project.id);
      if (index != -1) {
        _projects[index] = project;
        notifyListeners();
      }

      Logger.s('ProjectProvider', 'Project updated and refreshed successfully');
    } catch (e) {
      _errorMessage = 'Failed to update project: $e';
      Logger.e('ProjectProvider', 'Failed to update project: $e');
      rethrow;
    }
  }

  void _setLoadingState(ProjectLoadingState state) {
    _loadingState = state;
    notifyListeners();
  }
}
