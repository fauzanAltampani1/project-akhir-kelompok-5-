import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../../data/models/project_task_model.dart';
import '../../../data/models/project_model.dart';
import '../../../data/models/user_model.dart';
import '../providers/project_provider.dart';
import '../../../core/network/api_client.dart';

enum ProjectTaskLoadingState { idle, loading, success, error }

class ProjectTaskProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<ProjectTaskModel> _tasks = [];
  ProjectTaskLoadingState _loadingState = ProjectTaskLoadingState.idle;
  String? _errorMessage;
  ProjectProvider? _projectProvider;

  List<ProjectTaskModel> get tasks => _tasks;
  ProjectTaskLoadingState get loadingState => _loadingState;
  String? get errorMessage => _errorMessage;

  List<ProjectTaskModel> get assignedTasks =>
      _tasks
          .where((task) => task.assigneeIds.contains(UserModel.currentUser.id))
          .toList();

  List<ProjectTaskModel> getTasksByProjectId(String projectId) {
    return _tasks.where((task) => task.projectId == projectId).toList();
  }

  void setProjectProvider(ProjectProvider provider) {
    _projectProvider = provider;
    notifyListeners();
  }

  ProjectModel? _safeGetProjectById(String? projectId) {
    if (_projectProvider == null) {
      developer.log(
        'ProjectProvider not set',
        name: 'ProjectTaskProvider',
        level: 2, // warning
      );
      return null;
    }

    if (projectId == null || projectId.trim().isEmpty) {
      developer.log(
        'Empty/null project ID provided',
        name: 'ProjectTaskProvider',
        level: 2, // warning
      );
      return null;
    }

    return _projectProvider!.getProjectById(projectId);
  }

  Future<void> fetchTasksByProjectId(String projectId) async {
    if (projectId.trim().isEmpty) {
      developer.log(
        'Cannot fetch tasks - empty project ID',
        name: 'ProjectTaskProvider',
        level: 1, // error
      );
      _loadingState = ProjectTaskLoadingState.error;
      _errorMessage = 'Invalid project ID';
      notifyListeners();
      return;
    }

    _loadingState = ProjectTaskLoadingState.loading;
    notifyListeners();

    try {
      final response = await _apiClient.get('/projects/$projectId/tasks');
      if (response is Map<String, dynamic> && response['status'] == 'error') {
        throw Exception(response['message']);
      }

      final List<dynamic> tasksData =
          response is List ? response : response['data'] ?? [];
      _tasks =
          tasksData.map((json) => ProjectTaskModel.fromJson(json)).toList();

      _loadingState = ProjectTaskLoadingState.success;
      _errorMessage = null;

      developer.log(
        'Tasks fetched successfully (${_tasks.length} tasks)',
        name: 'ProjectTaskProvider',
      );
    } catch (e) {
      _errorMessage = 'Failed to fetch tasks: $e';
      _loadingState = ProjectTaskLoadingState.error;
      developer.log(
        'Failed to fetch tasks: $e',
        name: 'ProjectTaskProvider',
        level: 1, // error
      );
    }
    notifyListeners();
  }

  Future<bool> addProjectTask(ProjectTaskModel task) async {
    _loadingState = ProjectTaskLoadingState.loading;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        '/projects/${task.projectId}/tasks',
        task.toJson(),
      );

      if (response is Map<String, dynamic> && response['status'] == 'error') {
        throw Exception(response['message']);
      }

      await fetchTasksByProjectId(task.projectId);

      // Update project task count
      if (_projectProvider != null) {
        final project = _safeGetProjectById(task.projectId);
        if (project != null) {
          await _projectProvider!.updateProject(task.projectId, {
            'task_count': project.taskCount + 1,
          });
        }
      }

      _loadingState = ProjectTaskLoadingState.success;
      _errorMessage = null;
      notifyListeners();

      developer.log('Task created successfully', name: 'ProjectTaskProvider');
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create task: $e';
      _loadingState = ProjectTaskLoadingState.error;
      notifyListeners();

      developer.log(
        'Failed to create task: $e',
        name: 'ProjectTaskProvider',
        level: 1, // error
      );
      return false;
    }
  }

  Future<bool> updateProjectTask(
    String taskId, {
    String? title,
    String? description,
    DateTime? dueDate,
    List<String>? assigneeIds,
    bool? isCompleted,
  }) async {
    _loadingState = ProjectTaskLoadingState.loading;
    notifyListeners();

    try {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      final updates = <String, dynamic>{
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (dueDate != null) 'due_date': dueDate.toIso8601String(),
        if (assigneeIds != null) 'assignee_ids': assigneeIds,
        if (isCompleted != null) 'is_completed': isCompleted,
      };

      final response = await _apiClient.put(
        '/projects/${task.projectId}/tasks/$taskId',
        updates,
      );

      if (response is Map<String, dynamic> && response['status'] == 'error') {
        throw Exception(response['message']);
      }

      await fetchTasksByProjectId(task.projectId);
      _loadingState = ProjectTaskLoadingState.success;
      _errorMessage = null;
      notifyListeners();

      developer.log('Task updated successfully', name: 'ProjectTaskProvider');
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update task: $e';
      _loadingState = ProjectTaskLoadingState.error;
      notifyListeners();

      developer.log(
        'Failed to update task: $e',
        name: 'ProjectTaskProvider',
        level: 1, // error
      );
      return false;
    }
  }

  Future<bool> deleteProjectTask(String taskId) async {
    _loadingState = ProjectTaskLoadingState.loading;
    notifyListeners();

    try {
      final task = _tasks.firstWhere((t) => t.id == taskId);

      final response = await _apiClient.delete(
        '/projects/${task.projectId}/tasks/$taskId',
        {},
      );

      if (response is Map<String, dynamic> && response['status'] == 'error') {
        throw Exception(response['message']);
      }

      _tasks = _tasks.where((t) => t.id != taskId).toList();

      if (_projectProvider != null) {
        final project = _safeGetProjectById(task.projectId);
        if (project != null) {
          await _projectProvider!.updateProject(task.projectId, {
            'task_count': project.taskCount - 1,
          });
        }
      }

      _loadingState = ProjectTaskLoadingState.success;
      _errorMessage = null;
      notifyListeners();

      developer.log('Task deleted successfully', name: 'ProjectTaskProvider');
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete task: $e';
      _loadingState = ProjectTaskLoadingState.error;
      notifyListeners();

      developer.log(
        'Failed to delete task: $e',
        name: 'ProjectTaskProvider',
        level: 1, // error
      );
      return false;
    }
  }
}
